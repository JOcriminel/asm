import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_message_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_attachment_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_attachment.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_notification_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_chat_tab.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_attachments_tab.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_attachments_provider.dart';

Widget buildTestHarness(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Timetree Chat, Attachments & Notifications DTO & Model Tests', () {
    test('TimetreeMessageDto parsing and domain mapping', () {
      final json = {
        'id': 'msg-1',
        'eventId': 'event-10',
        'message': 'Hello world',
        'messageType': 'TEXT',
        'metadata': 'custom_payload',
        'sentAt': '2026-06-23T12:00:00.000',
        'sender': {
          'id': 'mem-5',
          'username': 'user1',
          'fullName': 'User One',
          'email': 'user1@test.com',
          'role': 'MEMBER',
        }
      };

      final dto = TimetreeMessageDto.fromJson(json);
      expect(dto.id, 'msg-1');
      expect(dto.eventId, 'event-10');
      expect(dto.message, 'Hello world');
      expect(dto.messageType, 'TEXT');
      expect(dto.metadata, 'custom_payload');
      expect(dto.sender.fullName, 'User One');

      final domain = TimetreeMessage.fromDto(dto);
      expect(domain.id, 'msg-1');
      expect(domain.messageType, TimetreeMessageType.text);
      expect(domain.sender.username, 'user1');
    });

    test('TimetreeAttachmentDto parsing and domain mapping', () {
      final json = {
        'id': 'att-2',
        'eventId': 'event-10',
        'fileName': 'report.pdf',
        'filePath': '/uploads/report.pdf',
        'fileType': 'application/pdf',
        'uploadedBy': 'chef1',
        'uploadedAt': '2026-06-23T12:30:00.000',
        'originalFilename': 'raw_report.pdf',
        'storedFilename': 'report.pdf',
        'fileSize': 2048576,
      };

      final dto = TimetreeAttachmentDto.fromJson(json);
      expect(dto.id, 'att-2');
      expect(dto.fileName, 'report.pdf');
      expect(dto.fileSize, 2048576);

      final domain = TimetreeAttachment.fromDto(dto);
      expect(domain.id, 'att-2');
      expect(domain.sizeFormatted, '2.0 MB');
    });

    test('TimetreeNotificationDto parsing and domain mapping', () {
      final json = {
        'id': 'not-3',
        'recipientId': 'mem-5',
        'title': 'New Event Update',
        'content': 'L\'événement a été modifié.',
        'type': 'EVENT_UPDATE',
        'entityType': 'EVENT',
        'entityId': '125',
        'actionType': 'UPDATED',
        'isRead': false,
        'createdAt': '2026-06-23T12:45:00.000',
      };

      final dto = TimetreeNotificationDto.fromJson(json);
      expect(dto.id, 'not-3');
      expect(dto.entityType, 'EVENT');
      expect(dto.entityId, '125');
      expect(dto.isRead, false);

      final domain = TimetreeNotification.fromDto(dto);
      expect(domain.id, 'not-3');
      expect(domain.isRead, false);
    });
  });

  group('TimetreeChatTab Widget Tests', () {
    testWidgets('renders empty state correctly', (tester) async {
      final override = timetreeChatProvider('event-1').overrideWith(
        (ref) => _FakeChatNotifier(
          const TimetreeChatState(messages: [], isLoading: false),
        ),
      );

      await tester.pumpWidget(
        buildTestHarness(const TimetreeChatTab(eventId: 'event-1'), [override]),
      );

      expect(find.text('Discussion vide'), findsOneWidget);
      expect(find.text('Soyez le premier à envoyer un message !'), findsOneWidget);
    });

    testWidgets('renders loading state correctly', (tester) async {
      final override = timetreeChatProvider('event-1').overrideWith(
        (ref) => _FakeChatNotifier(
          const TimetreeChatState(messages: [], isLoading: true),
        ),
      );

      await tester.pumpWidget(
        buildTestHarness(const TimetreeChatTab(eventId: 'event-1'), [override]),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TimetreeAttachmentsTab Widget Tests', () {
    testWidgets('renders empty files state', (tester) async {
      final override = timetreeAttachmentsProvider('event-1').overrideWith(
        (ref) => _FakeAttachmentsNotifier(
          const TimetreeAttachmentsState(attachments: [], isLoading: false),
        ),
      );

      await tester.pumpWidget(
        buildTestHarness(const TimetreeAttachmentsTab(eventId: 'event-1'), [override]),
      );

      expect(find.text('Aucun fichier partagé'), findsOneWidget);
    });
  });
}

class _FakeChatNotifier extends StateNotifier<TimetreeChatState> implements TimetreeChatNotifier {
  _FakeChatNotifier(super.state);

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> sendMessage(String text, {String type = 'TEXT', String? metadata}) async {}

  @override
  Future<void> markRead() async {}
}

class _FakeAttachmentsNotifier extends StateNotifier<TimetreeAttachmentsState> implements TimetreeAttachmentsNotifier {
  _FakeAttachmentsNotifier(super.state);

  @override
  Future<void> loadAttachments() async {}

  @override
  Future<void> uploadFile(String filePath, String fileName) async {}

  @override
  Future<void> deleteAttachment(String attachmentId) async {}

  @override
  Future<List<int>> downloadAttachment(String attachmentId) async => [];
}
