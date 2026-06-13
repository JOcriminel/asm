import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';

class AuditLogItem {
  final String action;
  final String documentId;
  final String lineId;
  final String serialNumber;
  final String userId;
  final DateTime timestamp;

  AuditLogItem({
    required this.action,
    required this.documentId,
    required this.lineId,
    required this.serialNumber,
    required this.userId,
    required this.timestamp,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      action: json['action'] ?? '',
      documentId: json['documentId'] ?? '',
      lineId: json['lineId'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      userId: json['userId'] ?? 'system',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    return DateFormat('dd/MM HH:mm').format(timestamp);
  }
}

class ActivityFeedRepository {
  final Dio _dio;

  ActivityFeedRepository(this._dio);

  Future<List<AuditLogItem>> getFeed({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/dashboard/feed', queryParameters: {
        'page': page,
        'size': size,
      });
      
      final content = response.data['content'] as List?;
      if (content == null) return [];
      
      return content.map((e) => AuditLogItem.fromJson(e)).toList();
    } catch (e) {
      AppLogger.e('ActivityFeedRepository', 'Failed to fetch feed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final activityFeedRepositoryProvider = Provider<ActivityFeedRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ActivityFeedRepository(dio);
});
