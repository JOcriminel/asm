import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/models/bon_preparation.dart';
import '../../domain/repositories/bon_preparation_repository.dart';
import '../models/bon_preparation_dto.dart';
import '../mappers/bon_preparation_mapper.dart';

class BonPreparationRepositoryImpl implements BonPreparationRepository {
  final Dio _dio;

  const BonPreparationRepositoryImpl(this._dio);

  @override
  Future<List<BonPreparation>> getBonPreparations({
    required BonPreparationFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final now = DateTime.now();
      final defaultFrom = DateTime(now.year, now.month, 1);
      final defaultTo = DateTime(now.year, now.month + 1, 0);

      final fromStr =
          filter.dateFrom != null ? formatter.format(filter.dateFrom!) : formatter.format(defaultFrom);
      final toStr =
          filter.dateTo != null ? '${formatter.format(filter.dateTo!)} 23:59:59' : '${formatter.format(defaultTo)} 23:59:59';
      
      final idTierStr = (filter.tier != null && filter.tier!.isNotEmpty)
          ? filter.tier!
          : (userId != null && userId.isNotEmpty ? userId : 'all');
      final represStr =
          (filter.representative != null && filter.representative!.isNotEmpty)
              ? filter.representative!
              : (userTierId != null && userTierId.isNotEmpty ? userTierId : 'all');
      final codeDocStr = 'DPR'; // Always fetch 'Bon de Préparation'
      final idEtatStr =
          (filter.status != null && filter.status!.isNotEmpty)
              ? filter.status!
              : 'all';

      const allStr = 'false';
      final allDocsStr = filter.allDocuments ? 'true' : 'false';
      final idArticleStr =
          (filter.articleFilter != null && filter.articleFilter!.isNotEmpty)
              ? filter.articleFilter!
              : 'null';
      final affichAvancStr = filter.advancedFilterActive ? 'true' : 'false';

      final path = '/list-documents/'
          '$fromStr/'
          '$toStr/'
          '$idTierStr/'
          '$represStr/'
          '$codeDocStr/'
          '$idEtatStr/'
          '$allStr/'
          '$allDocsStr/'
          '$idArticleStr/'
          '$affichAvancStr';

      final requestBody = {
        'idDocCommercial': [],
        'idTierModal': null,
        'event': {
          'first': 0,
          'rows': 500, // Load a large list to perform reliable local search
          'sortOrder': 1,
          'filters': {},
          'globalFilter': null
        }
      };

      final response = await _dio.post(
        path,
        data: requestBody,
        queryParameters: userStationId != null && userStationId.isNotEmpty && userStationId != 'Default Station'
            ? {'stationId': userStationId}
            : null,
      );

      if (response.data == null) return [];

      dynamic data = response.data;
      if (data is String && data.trim().isNotEmpty) {
        try {
          data = json.decode(data.trim());
        } catch (_) {
          return [];
        }
      }

      List<dynamic> rawList = [];

      if (data is Map<String, dynamic>) {
        final status = data['status']?.toString();
        if (status == 'error') {
          final msg = data['data']?.toString() ?? '';
          if (msg.contains('Undefined offset') || msg.contains('count():') || msg.contains('array_key_exists')) {
            return [];
          }
          throw Exception('API error: $msg');
        }

        final inner = data['data'] ?? data['content'] ?? data['results'] ?? data['documents'];
        if (inner is List) {
          rawList = inner;
        } else {
          rawList = [data];
        }
      } else if (data is List) {
        rawList = data;
      }

      final preparations = rawList
          .map((e) => BonPreparationMapper.toEntity(BonPreparationDto.fromJson(e as Map<String, dynamic>)))
          .toList();

      AppLogger.d('BonPreparationRepository', 'Fetched ${preparations.length} preparations');
      return preparations;
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<BonPreparation> getBonPreparationDetails(String id) async {
    try {
      final response = await _dio.get('/document/$id');
      if (response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = json.decode(data);
        }
        if (data is Map<String, dynamic>) {
          final dto = BonPreparationDto.fromJson(data);
          return BonPreparationMapper.toEntity(dto);
        }
      }
      throw UnknownApiException('Empty response from details endpoint');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> saveSerialNumbers({
    required String documentId,
    required String lineId,
    required List<String> serialNumbers,
    String? idClassedocument,
    Map<String, dynamic>? rawArticleJson,
  }) async {
    try {
      final List<Map<String, dynamic>> listNumSerie = [];
      
      final articleId = rawArticleJson?['idArticle'] ?? rawArticleJson?['id'] ?? '';
      
      for (final sn in serialNumbers) {
        listNumSerie.add({
          "id": "",
          "editNumSerie": true,
          "NumSerie": sn,
          "etat": "add",
          "idArticle": articleId,
          "newScenario": true,
          "idClassedocument": idClassedocument ?? "1403",
          "iddocument": documentId,
          "natureES": "S",
          "idLigne": lineId
        });
      }

      final Map<String, dynamic> dataPayload = Map<String, dynamic>.from(rawArticleJson ?? {});
      dataPayload['id'] = lineId;
      dataPayload['NumSerie'] = "0";
      dataPayload['listNumSerie'] = listNumSerie;
      dataPayload['ligneTaxeProduit'] ??= [];
      dataPayload['periodique'] ??= "0";

      final requestBody = {
        "data": dataPayload
      };

      AppLogger.d('BonPreparationRepository', 'Sending editLigne request: $requestBody');
      await _dio.post(
        '/Document/editLigne',
        data: requestBody,
      );
      AppLogger.d('BonPreparationRepository', 'Saved all serial numbers: $serialNumbers for line $lineId');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<List<String>> getSerialNumbersByBonSort(
    String idlignedocument, {
    String? productCode,
    String? lineId,
  }) async {
    try {
      final response = await _dio.get('/numSerie/getByNumBonSort/$idlignedocument');
      if (response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = json.decode(data);
        }
        
        List<String> results = [];
        if (data is List) {
          for (var item in data) {
            if (item is String) {
              results.add(item);
            } else if (item is Map<String, dynamic>) {
              final sn = item['NumSerie'] ?? item['numSerie'] ?? item['num_serie'] ?? item['serialNumber'] ?? item['serial_number'] ?? item['sn'];
              if (sn != null) {
                final code = item['codeArticle'] ?? item['code_article'] ?? item['code'] ?? item['ref'] ?? item['refArticle'] ?? item['ref_article'];
                
                bool isMatch = true;
                if (code != null && productCode != null && code.toString().trim().toLowerCase() != productCode.trim().toLowerCase()) {
                  isMatch = false;
                }
                
                final lineIdInItem = item['idligne'] ?? item['idLigne'] ?? item['id_ligne'];
                if (lineIdInItem != null && lineId != null && lineIdInItem.toString().trim() != lineId.trim()) {
                  isMatch = false;
                }
                
                if (isMatch) {
                  results.add(sn.toString().trim());
                }
              }
            }
          }
        } else if (data is Map<String, dynamic>) {
          final list = data['data'] ?? data['content'] ?? data['results'] ?? data['serialNumbers'] ?? data['numSeries'];
          if (list is List) {
            for (var item in list) {
              if (item is String) {
                results.add(item);
              } else if (item is Map<String, dynamic>) {
                final sn = item['NumSerie'] ?? item['numSerie'] ?? item['num_serie'] ?? item['serialNumber'] ?? item['serial_number'] ?? item['sn'];
                if (sn != null) {
                  final code = item['codeArticle'] ?? item['code_article'] ?? item['code'] ?? item['ref'] ?? item['refArticle'] ?? item['ref_article'];
                  final lineIdInItem = item['idligne'] ?? item['idLigne'] ?? item['id_ligne'];
                  
                  bool isMatch = true;
                  if (code != null && productCode != null && code.toString().trim().toLowerCase() != productCode.trim().toLowerCase()) {
                    isMatch = false;
                  }
                  if (lineIdInItem != null && lineId != null && lineIdInItem.toString().trim() != lineId.trim()) {
                    isMatch = false;
                  }
                  
                  if (isMatch) {
                    results.add(sn.toString().trim());
                  }
                }
              }
            }
          } else {
            final sn = data['NumSerie'] ?? data['numSerie'] ?? data['num_serie'] ?? data['serialNumber'] ?? data['serial_number'] ?? data['sn'];
            if (sn != null) {
              results.add(sn.toString().trim());
            }
          }
        }
        return results;
      }
      return [];
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, String>> getSerialNumberIds(String idlignedocument) async {
    try {
      final response = await _dio.get('/numSerie/getByNumBonSort/$idlignedocument');
      final Map<String, String> results = {};
      if (response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = json.decode(data);
        }
        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final id = item['id']?.toString();
              final sn = item['NumSerie'] ?? item['numSerie'] ?? item['num_serie'];
              if (id != null && sn != null) {
                results[sn.toString().trim()] = id.toString();
              }
            }
          }
        }
      }
      return results;
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> deleteSerialNumber(String id) async {
    try {
      await _dio.delete('/numSerie/delete/$id');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final bonPreparationRepositoryProvider = Provider<BonPreparationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BonPreparationRepositoryImpl(dio);
});
