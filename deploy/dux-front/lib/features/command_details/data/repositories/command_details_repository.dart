import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
import '../../../commands/data/models/command_dto.dart';
import '../../../commands/data/mappers/command_mapper.dart';
import '../../domain/repositories/command_details_repository.dart';
import '../services/command_details_api_service.dart';

import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';
import 'dart:convert';

/// Concrete implementation of [CommandDetailsRepository].
class CommandDetailsRepositoryImpl implements CommandDetailsRepository {
  final CommandDetailsApiService _apiService;
  final Dio _dio;

  const CommandDetailsRepositoryImpl(this._apiService, this._dio);

  @override
  Future<Command> getCommandDetails(String id) async {
    final rawData = await _apiService.fetchCommandDetails(id);
    final dto = CommandDto.fromJson(rawData);
    return CommandMapper.toEntity(dto);
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
      AppLogger.d('CommandDetailsRepository',
          'Fetched ${finalResults.length} serial numbers for line $idlignedocument');
      return finalResults;
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final commandDetailsRepositoryProvider = Provider<CommandDetailsRepository>((ref) {
  return CommandDetailsRepositoryImpl(
    ref.watch(commandDetailsApiServiceProvider),
    ref.watch(dioProvider),
  );
});
