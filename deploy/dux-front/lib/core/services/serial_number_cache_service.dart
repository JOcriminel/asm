import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../utils/logger.dart';

/// Service to manage Global Serial Numbers via the Java Backend H2 database.
class SerialNumberCacheService {
  final Dio _dio;

  SerialNumberCacheService(this._dio);

  /// Track serial numbers globally after successful save
  Future<void> saveSerialNumbers(String documentId, List<String> serials) async {
    for (var sn in serials) {
      final cleanSn = sn.trim().toLowerCase();
      if (cleanSn.isNotEmpty) {
        try {
          await _dio.post('/numSerie/track', queryParameters: {
            'sn': cleanSn,
            'documentId': documentId,
          });
        } catch (e) {
          AppLogger.e('SerialNumberCacheService', 'Failed to track SN: $cleanSn', e);
        }
      }
    }
  }

  /// Untrack a serial number globally after it's deleted
  Future<void> untrackSerialNumber(String sn) async {
    final cleanSn = sn.trim().toLowerCase();
    if (cleanSn.isNotEmpty) {
      try {
        await _dio.delete('/numSerie/untrack/$cleanSn');
      } catch (e) {
        AppLogger.e('SerialNumberCacheService', 'Failed to untrack SN: $cleanSn', e);
      }
    }
  }

  /// Finds the document ID for a given serial number using global DB.
  Future<String?> findDocumentId(String serialNumber) async {
    final cleanSn = serialNumber.trim().toLowerCase();
    if (cleanSn.isEmpty) return null;
    try {
      final response = await _dio.get('/numSerie/check/$cleanSn');
      if (response.data != null) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        if (data['exists'] == true) {
          return data['documentId'];
        }
      }
    } catch (e) {
      AppLogger.e('SerialNumberCacheService', 'Failed to check SN: $cleanSn', e);
    }
    return null;
  }

  /// Checks if a serial number is already assigned to a DIFFERENT document ID.
  Future<String?> getDuplicateDocumentId(String serialNumber, String currentDocumentId) async {
    final docId = await findDocumentId(serialNumber);
    if (docId != null && docId != currentDocumentId) {
      return docId;
    }
    return null;
  }
}

final serialNumberCacheServiceProvider = Provider<SerialNumberCacheService>((ref) {
  return SerialNumberCacheService(ref.watch(dioProvider));
});
