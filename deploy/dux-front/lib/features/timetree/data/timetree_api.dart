import 'package:dio/dio.dart';

class TimetreeApi {
  final Dio _dio;
  TimetreeApi(this._dio);

  // Menu endpoint
  Future<Response> getMenu() async {
    return _dio.get('/api/timetree/menu');
  }

  // Dashboard endpoint
  Future<Response> getDashboard() async {
    return _dio.get('/api/timetree/dashboard');
  }

  // Categories CRUD
  Future<Response> getCategories() async {
    return _dio.get('/api/timetree/categories');
  }

  Future<Response> getCategory(String id) async {
    return _dio.get('/api/timetree/categories/$id');
  }

  Future<Response> createCategory(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/categories', data: data);
  }

  Future<Response> updateCategory(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/categories/$id', data: data);
  }

  Future<Response> deleteCategory(String id) async {
    return _dio.delete('/api/timetree/categories/$id');
  }

  Future<Response> activateCategory(String id) async {
    return _dio.patch('/api/timetree/categories/$id/activate');
  }

  Future<Response> deactivateCategory(String id) async {
    return _dio.patch('/api/timetree/categories/$id/deactivate');
  }

  // Pages CRUD
  Future<Response> getPages() async {
    return _dio.get('/api/timetree/pages');
  }

  Future<Response> getPage(String id) async {
    return _dio.get('/api/timetree/pages/$id');
  }

  Future<Response> createPage(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/pages', data: data);
  }

  Future<Response> updatePage(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/pages/$id', data: data);
  }

  Future<Response> deletePage(String id) async {
    return _dio.delete('/api/timetree/pages/$id');
  }

  // Groups CRUD
  Future<Response> getGroups() async {
    return _dio.get('/api/timetree/groups');
  }

  Future<Response> getGroup(String id) async {
    return _dio.get('/api/timetree/groups/$id');
  }

  Future<Response> createGroup(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/groups', data: data);
  }

  Future<Response> updateGroup(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/groups/$id', data: data);
  }

  Future<Response> deleteGroup(String id) async {
    return _dio.delete('/api/timetree/groups/$id');
  }

  // Roles
  Future<Response> getRoles() async {
    return _dio.get('/api/timetree/roles');
  }

  Future<Response> assignRoleToGroup(String groupId, String roleCode) async {
    return _dio.post('/api/timetree/groups/$groupId/roles', data: {'roleCode': roleCode});
  }

  Future<Response> removeRoleFromGroup(String groupId, String roleCode) async {
    return _dio.delete('/api/timetree/groups/$groupId/roles/$roleCode');
  }

  // Permissions
  Future<Response> assignCategoryToGroup(String categoryId, List<String> groupIds) async {
    return _dio.post('/api/timetree/categories/$categoryId/groups', data: {'groupIds': groupIds});
  }

  Future<Response> assignPageToGroup(String pageId, List<String> groupIds) async {
    return _dio.post('/api/timetree/pages/$pageId/groups', data: {'groupIds': groupIds});
  }

  Future<Response> getPermissions() async {
    return _dio.get('/api/timetree/permissions');
  }

  // Members CRUD
  Future<Response> getMembers() async {
    return _dio.get('/api/timetree/members');
  }

  Future<Response> createMember(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/members', data: data);
  }

  Future<Response> updateMember(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/members/$id', data: data);
  }

  Future<Response> deleteMember(String id) async {
    return _dio.delete('/api/timetree/members/$id');
  }

  // Calendars CRUD
  Future<Response> getCalendars() async {
    return _dio.get('/api/timetree/calendars');
  }

  Future<Response> createCalendar(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/calendars', data: data);
  }

  Future<Response> updateCalendar(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/calendars/$id', data: data);
  }

  Future<Response> deleteCalendar(String id) async {
    return _dio.delete('/api/timetree/calendars/$id');
  }

  Future<Response> addMemberToCalendar(String calendarId, String memberId) async {
    return _dio.post('/api/timetree/calendars/$calendarId/members', data: {'memberId': memberId});
  }

  Future<Response> removeMemberFromCalendar(String calendarId, String memberId) async {
    return _dio.delete('/api/timetree/calendars/$calendarId/members/$memberId');
  }

  Future<Response> setCalendarMembers(String calendarId, List<String> memberIds) async {
    return _dio.put('/api/timetree/calendars/$calendarId/members', data: {'memberIds': memberIds});
  }

  // Group membership & assignments
  Future<Response> addMemberToGroup(String groupId, String memberId) async {
    return _dio.post('/api/timetree/groups/$groupId/members', data: {'memberId': memberId});
  }

  Future<Response> removeMemberFromGroup(String groupId, String memberId) async {
    return _dio.delete('/api/timetree/groups/$groupId/members/$memberId');
  }

  Future<Response> assignChefToGroup(String groupId, String? chefId) async {
    return _dio.put('/api/timetree/groups/$groupId/chef', data: {'chefId': chefId ?? ''});
  }

  Future<Response> assignCalendarsToGroup(String groupId, List<String> calendarIds) async {
    return _dio.post('/api/timetree/groups/$groupId/calendars', data: {'calendarIds': calendarIds});
  }

  // Custom Fields definitions
  Future<Response> getCustomFields({String? scopeType, String? scopeId}) async {
    return _dio.get('/api/timetree/custom-fields', queryParameters: {
      'scopeType':? scopeType,
      'scopeId':? scopeId,
    });
  }

  Future<Response> getEventFields({String? groupId, String? calendarId, String? eventId}) async {
    return _dio.get('/api/timetree/custom-fields/event-fields', queryParameters: {
      'groupId':? groupId,
      'calendarId':? calendarId,
      'eventId':? eventId,
    });
  }

  Future<Response> getCustomField(String id) async {
    return _dio.get('/api/timetree/custom-fields/$id');
  }

  Future<Response> createCustomField(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/custom-fields', data: data);
  }

  Future<Response> updateCustomField(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/custom-fields/$id', data: data);
  }

  Future<Response> deleteCustomField(String id) async {
    return _dio.delete('/api/timetree/custom-fields/$id');
  }

  Future<Response> reorderCustomFields(List<Map<String, dynamic>> reorderList) async {
    return _dio.post('/api/timetree/custom-fields/reorder', data: reorderList);
  }

  // Custom Field categories
  Future<Response> getCustomFieldCategories() async {
    return _dio.get('/api/timetree/custom-fields/categories');
  }

  Future<Response> createCustomFieldCategory(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/custom-fields/categories', data: data);
  }

  Future<Response> updateCustomFieldCategory(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/custom-fields/categories/$id', data: data);
  }

  Future<Response> deleteCustomFieldCategory(String id) async {
    return _dio.delete('/api/timetree/custom-fields/categories/$id');
  }

  // Custom Field values
  Future<Response> getCustomFieldValues(String entityType, String entityId) async {
    return _dio.get('/api/timetree/custom-fields/values/$entityType/$entityId');
  }

  Future<Response> saveCustomFieldValues(String entityType, String entityId, Map<String, dynamic> values) async {
    return _dio.post('/api/timetree/custom-fields/values/$entityType/$entityId', data: values);
  }


  // Events CRUD
  Future<Response> getEvents({
    List<String>? calendarIds,
    required String start,
    required String end,
  }) async {
    return _dio.get('/api/timetree/events', queryParameters: {
      if (calendarIds != null && calendarIds.isNotEmpty) 'calendarIds': calendarIds,
      'start': start,
      'end': end,
    });
  }

  Future<Response> getEvent(String id) async {
    return _dio.get('/api/timetree/events/$id');
  }

  Future<Response> getEventHistory(String id) async {
    return _dio.get('/api/timetree/events/$id/history');
  }


  Future<Response> createEvent(Map<String, dynamic> data) async {
    return _dio.post('/api/timetree/events', data: data);
  }

  Future<Response> updateEvent(String id, Map<String, dynamic> data) async {
    return _dio.put('/api/timetree/events/$id', data: data);
  }

  Future<Response> deleteEvent(String id) async {
    return _dio.delete('/api/timetree/events/$id');
  }

  // Event Participants
  Future<Response> addParticipant(String id, String memberId) async {
    return _dio.post('/api/timetree/events/$id/participants', data: {'memberId': memberId});
  }

  Future<Response> removeParticipant(String id, String memberId) async {
    return _dio.delete('/api/timetree/events/$id/participants/$memberId');
  }

  // Event Chat
  Future<Response> getEventMessages(String eventId, {int page = 0, int size = 20}) async {
    return _dio.get('/api/timetree/events/$eventId/messages', queryParameters: {
      'page': page,
      'size': size,
    });
  }

  Future<Response> sendEventMessage(
    String eventId,
    String message, {
    String messageType = 'TEXT',
    String? metadata,
  }) async {
    return _dio.post('/api/timetree/events/$eventId/messages', data: {
      'message': message,
      'messageType': messageType,
      'metadata': metadata,
    });
  }

  Future<Response> markChatRead(String eventId) async {
    return _dio.post('/api/timetree/events/$eventId/chat/read');
  }

  Future<Response> getUnreadCounts() async {
    return _dio.get('/api/timetree/events/unread-counts');
  }

  // Event Attachments
  Future<Response> getAttachments(String eventId) async {
    return _dio.get('/api/timetree/events/$eventId/attachments');
  }

  Future<Response> getPresignedUploadUrl(String eventId, String fileName, int fileSize, String contentType) async {
    return _dio.post(
      '/api/timetree/events/$eventId/attachments/presigned-upload',
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
      },
    );
  }

  Future<Response> uploadFileToS3(String url, Stream<List<int>> fileStream, int fileSize, String contentType) async {
    return _dio.put(
      url,
      data: fileStream,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: fileSize,
        },
      ),
    );
  }

  Future<Response> confirmAttachmentUpload(String eventId, String fileName, String s3Key, int fileSize, String contentType) async {
    return _dio.post(
      '/api/timetree/events/$eventId/attachments/confirm',
      data: {
        'fileName': fileName,
        's3Key': s3Key,
        'fileSize': fileSize,
        'contentType': contentType,
      },
    );
  }

  Future<Response> getPresignedDownloadUrl(String attachmentId) async {
    return _dio.get('/api/timetree/events/attachments/presigned-download/$attachmentId');
  }

  Future<Response<List<int>>> downloadBytesFromUrl(String url) async {
    return _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<Response> deleteAttachment(String attachmentId) async {
    return _dio.delete('/api/timetree/events/attachments/$attachmentId');
  }

  // Notifications — paginated history
  Future<Response> getNotifications({int page = 0, int size = 20}) async {
    return _dio.get('/api/timetree/notifications', queryParameters: {'page': page, 'size': size});
  }

  // PUT mark single notification as read
  Future<Response> markNotificationRead(String notificationId) async {
    return _dio.put('/api/timetree/notifications/$notificationId/read');
  }

  // PUT mark all notifications as read
  Future<Response> markAllNotificationsRead() async {
    return _dio.put('/api/timetree/notifications/read-all');
  }

  // DELETE a notification
  Future<Response> deleteNotification(String notificationId) async {
    return _dio.delete('/api/timetree/notifications/$notificationId');
  }

  // GET notification preferences
  Future<Response> getNotificationPreferences() async {
    return _dio.get('/api/timetree/notifications/preferences');
  }

  // PUT update notification preferences
  Future<Response> updateNotificationPreferences(Map<String, dynamic> prefs) async {
    return _dio.put('/api/timetree/notifications/preferences', data: prefs);
  }

  // GET calendar activity timeline (paginated, optional action filter)
  Future<Response> getCalendarActivity(String calendarId, {int page = 0, int size = 20, String? action}) async {
    return _dio.get('/api/timetree/calendars/$calendarId/activity', queryParameters: {
      'page': page,
      'size': size,
      if (action != null && action.isNotEmpty) 'action': action,
    });
  }

  Future<Response> resolveEventId(String type, String id) async {
    return _dio.get('/api/timetree/events/resolve-by-entity/$type/$id');
  }

  // Audit Logs
  Future<Response> getAuditLogs({
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    return _dio.get('/api/timetree/admin/audit-logs', queryParameters: {
      if (username != null && username.isNotEmpty) 'username': username,
      if (action != null && action.isNotEmpty) 'action': action,
      if (entityType != null && entityType.isNotEmpty) 'entityType': entityType,
      if (entityId != null && entityId.isNotEmpty) 'entityId': entityId,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<Response> downloadAuditLogsCsv({
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    return _dio.get(
      '/api/timetree/admin/audit-logs/export',
      queryParameters: {
        if (username != null && username.isNotEmpty) 'username': username,
        if (action != null && action.isNotEmpty) 'action': action,
        if (entityType != null && entityType.isNotEmpty) 'entityType': entityType,
        if (entityId != null && entityId.isNotEmpty) 'entityId': entityId,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      options: Options(responseType: ResponseType.bytes),
    );
  }

  // Global Search
  Future<Response> globalSearch(String query) async {
    return _dio.get('/api/timetree/search', queryParameters: {'query': query});
  }

  // Export Events
  Future<Response> exportEventsBytes(String format, {List<String>? calendarIds, String? start, String? end}) async {
    return _dio.get(
      '/api/timetree/export/$format',
      queryParameters: {
        if (calendarIds != null && calendarIds.isNotEmpty) 'calendarIds': calendarIds,
        'start': ?start,
        'end': ?end,
      },
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<Response> registerDevice(String deviceToken, String platform) async {
    return _dio.post('/api/timetree/notifications/devices/register', data: {
      'deviceToken': deviceToken,
      'platform': platform,
    });
  }

  Future<Response> sendAnnouncement(String title, String content, List<String> calendarIds) async {
    return _dio.post('/api/timetree/admin/announcements', data: {
      'title': title,
      'content': content,
      'calendarIds': calendarIds.map(int.parse).toList(),
    });
  }
}


