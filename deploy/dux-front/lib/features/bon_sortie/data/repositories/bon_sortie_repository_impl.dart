import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/models/bon_sortie.dart';
import '../../domain/repositories/bon_sortie_repository.dart';
import '../models/bon_sortie_dto.dart';
import '../mappers/bon_sortie_mapper.dart';

class BonSortieRepositoryImpl implements BonSortieRepository {
  final Dio _dio;

  const BonSortieRepositoryImpl(this._dio);

  @override
  Future<List<BonSortie>> getBonSorties({
    required BonSortieFilter filter,
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
          filter.dateFrom != null
              ? '${formatter.format(filter.dateFrom!)} 00:00:00'
              : '${formatter.format(defaultFrom)} 00:00:00';
      final toStr =
          filter.dateTo != null
              ? '${formatter.format(filter.dateTo!)} 23:59:59'
              : '${formatter.format(defaultTo)} 23:59:59';

      final idTierStr =
          (filter.tier != null && filter.tier!.isNotEmpty)
              ? filter.tier!
              : (userId != null && userId.isNotEmpty ? userId : 'all');
      final represStr =
          (filter.representative != null && filter.representative!.isNotEmpty)
              ? filter.representative!
              : (userTierId != null && userTierId.isNotEmpty ? userTierId : 'all');

      const codeDocStr = 'BS'; // Bon de Sortie
      final idEtatStr =
          (filter.status != null && filter.status!.isNotEmpty)
              ? filter.status!
              : 'all';

      const allStr = 'false';
      final allDocsStr = filter.allDocuments ? 'true' : 'false';
      const idArticleStr = 'null';
      const affichAvancStr = 'false';

      // Use the same /list-documents/ Java proxy route as bon_preparation, with BS document code
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
          'rows': 500,
          'sortOrder': 1,
          'filters': {},
          'globalFilter': null,
        },
      };

      AppLogger.d('BonSortieRepository', 'Fetching from path: $path');

      final response = await _dio.post(
        path,
        data: requestBody,
        queryParameters:
            userStationId != null &&
                    userStationId.isNotEmpty &&
                    userStationId != 'Default Station'
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
          if (msg.contains('Undefined offset') ||
              msg.contains('count():') ||
              msg.contains('array_key_exists')) {
            return [];
          }
          throw Exception('API error: $msg');
        }

        final inner =
            data['data'] ??
            data['content'] ??
            data['results'] ??
            data['documents'];
        if (inner is List) {
          rawList = inner;
        } else {
          rawList = [data];
        }
      } else if (data is List) {
        rawList = data;
      }

      final sorties = rawList
          .map((e) => BonSortieMapper.toEntity(
                BonSortieDto.fromJson(e as Map<String, dynamic>),
              ))
          .toList();

      AppLogger.d('BonSortieRepository', 'Fetched ${sorties.length} bons de sortie');
      return sorties;
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<BonSortie> getBonSortieDetails(String id) async {
    try {
      final response = await _dio.get('/document/$id');
      if (response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = json.decode(data);
        }
        if (data is Map<String, dynamic>) {
          final dto = BonSortieDto.fromJson(data);
          return BonSortieMapper.toEntity(dto);
        }
      }
      throw UnknownApiException('Empty response from details endpoint');
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
      if (response.data == null) return [];

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
            final sn = item['NumSerie'] ?? item['numSerie'] ?? item['num_serie'] ??
                item['serialNumber'] ?? item['serial_number'] ?? item['sn'];
            if (sn != null) {
              final code = item['codeArticle'] ?? item['code_article'] ??
                  item['code'] ?? item['ref'];
              final lineIdInItem = item['idligne'] ?? item['idLigne'] ?? item['id_ligne'];

              bool isMatch = true;
              if (code != null && productCode != null &&
                  code.toString().trim().toLowerCase() != productCode.trim().toLowerCase()) {
                isMatch = false;
              }
              if (lineIdInItem != null && lineId != null &&
                  lineIdInItem.toString().trim() != lineId.trim()) {
                isMatch = false;
              }
              if (isMatch) results.add(sn.toString().trim());
            }
          }
        }
      } else if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['content'] ?? data['results'] ??
            data['serialNumbers'] ?? data['numSeries'];
        if (list is List) {
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              final sn = item['NumSerie'] ?? item['numSerie'] ?? item['num_serie'] ??
                  item['serialNumber'] ?? item['sn'];
              if (sn != null) results.add(sn.toString().trim());
            }
          }
        }
      }

      final finalResults = results.where((s) => s.isNotEmpty).toSet().toList();
      AppLogger.d('BonSortieRepository',
          'Fetched ${finalResults.length} serial numbers for line $idlignedocument');
      return finalResults;
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final bonSortieRepositoryProvider = Provider<BonSortieRepository>((ref) {
  return BonSortieRepositoryImpl(ref.watch(dioProvider));
});
