import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/services/storage_service.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class TimetreeWebSocketService {
  final Ref _ref;
  StompClient? _client;
  final _connectionController = StreamController<bool>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  final Map<String, List<Function(Map<String, dynamic>)>> _subscriptions = {};
  
  // Offline queue for chat messages
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _isConnected = false;

  TimetreeWebSocketService(this._ref);

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  /// Stream of server-pushed unread notification counts.
  /// Emits a new value whenever the backend pushes { "type": "UNREAD_COUNT", "count": N }.
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  Future<void> connect() async {
    if (_client != null) return;

    final storage = _ref.read(storageServiceProvider);
    final token = await storage.read('auth_token');

    if (token == null || token.isEmpty) {
      AppLogger.e('WebSocket', 'Cannot connect: Missing auth token');
      return;
    }

    // Derive WebSocket URL from the configured API base URL.
    // AppConfig.baseUrl is e.g. "https://host.ngrok.io/api/dux"
    // We need                   "wss://host.ngrok.io/ws"
    final apiUri = Uri.parse(AppConfig.baseUrl);
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    final baseUrl = '$wsScheme://${apiUri.host}/ws';
    AppLogger.i('WebSocket', 'Connecting to $baseUrl');

    _client = StompClient(
      config: StompConfig(
        url: baseUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: _onStompError,
        onWebSocketError: _onWebSocketError,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
          'passcode': token,
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    AppLogger.i('WebSocket', 'Connected successfully');
    _isConnected = true;
    _connectionController.add(true);

    // Resubscribe all active subscriptions
    _subscriptions.forEach((destination, callbacks) {
      _client!.subscribe(
        destination: destination,
        callback: (frame) {
          final body = jsonDecode(frame.body ?? '{}');
          for (final callback in callbacks) {
            callback(body);
          }
        },
      );
    });

    // Subscribe to unicast notification queue (notifications + UNREAD_COUNT pushes)
    _client!.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        final body = jsonDecode(frame.body ?? '{}') as Map<String, dynamic>;
        if (body['type'] == 'UNREAD_COUNT') {
          final count = (body['count'] as num?)?.toInt() ?? 0;
          AppLogger.i('WebSocket', 'UNREAD_COUNT update received: $count');
          _unreadCountController.add(count);
        } else {
          // Forward to any registered /user/queue/notifications handlers
          final callbacks = _subscriptions['/user/queue/notifications'];
          if (callbacks != null) {
            for (final cb in callbacks) {
              cb(body);
            }
          }
        }
      },
    );

    // Subscribe to unicast ACKs for offline queue delivery confirmation
    _client!.subscribe(
      destination: '/user/queue/ack',
      callback: (frame) {
        final ack = jsonDecode(frame.body ?? '{}');
        final clientMessageId = ack['clientMessageId'];
        if (clientMessageId != null) {
          AppLogger.i('WebSocket', 'ACK received for clientMessageId: $clientMessageId');
          _offlineQueue.removeWhere((msg) => msg['clientMessageId'] == clientMessageId);
        }
      },
    );

    // Replay offline message queue
    _replayOfflineQueue();
  }

  void _onDisconnect(StompFrame frame) {
    AppLogger.i('WebSocket', 'Disconnected');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onStompError(StompFrame frame) {
    AppLogger.e('WebSocket', 'STOMP Error: ${frame.body}');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onWebSocketError(dynamic error) {
    AppLogger.e('WebSocket', 'WebSocket Error: $error');
    _isConnected = false;
    _connectionController.add(false);
    
    if (error.toString().contains('401')) {
      Future.microtask(() {
        _ref.read(authControllerProvider.notifier).logout();
      });
    }
  }

  void subscribe(String destination, Function(Map<String, dynamic>) onMessage) {
    final callbacks = _subscriptions.putIfAbsent(destination, () => []);
    callbacks.add(onMessage);

    if (_isConnected && _client != null) {
      _client!.subscribe(
        destination: destination,
        callback: (frame) {
          final body = jsonDecode(frame.body ?? '{}');
          onMessage(body);
        },
      );
    }
  }

  void unsubscribe(String destination) {
    _subscriptions.remove(destination);
    // Note: Stomp client handles actual unsubscribing or we can rely on connection drops,
    // but in stomp_dart_client we can also disconnect/reconnect or use subscription objects.
  }

  bool send(String destination, Map<String, dynamic> body, {Map<String, String>? headers}) {
    final Map<String, String> stompHeaders = headers ?? {};
    if (body.containsKey('clientMessageId')) {
      stompHeaders['clientMessageId'] = body['clientMessageId'].toString();
    }

    if (_isConnected && _client != null) {
      try {
        _client!.send(
          destination: destination,
          headers: stompHeaders,
          body: jsonEncode(body),
        );
        return true;
      } catch (e) {
        AppLogger.e('WebSocket', 'stomp client send failed with exception: $e');
        _isConnected = false;
        _connectionController.add(false);
      }
    }

    AppLogger.w('WebSocket', 'Offline or send failed. Caching message in queue: $body');
    // If this is a chat message, cache it in the offline queue
    if (destination.contains('.send') && body.containsKey('clientMessageId')) {
      _offlineQueue.add({
        'destination': destination,
        'headers': stompHeaders,
        ...body,
      });
    }
    return false;
  }

  void _replayOfflineQueue() {
    if (_offlineQueue.isEmpty) return;
    AppLogger.i('WebSocket', 'Replaying ${_offlineQueue.length} offline messages');
    final messages = List<Map<String, dynamic>>.from(_offlineQueue);
    for (final msg in messages) {
      final dest = msg['destination'];
      final Map<String, String> stompHeaders = Map<String, String>.from(msg['headers'] ?? {});
      final body = Map<String, dynamic>.from(msg)
        ..remove('destination')
        ..remove('headers');
      send(dest, body, headers: stompHeaders);
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _unreadCountController.close();
  }
}

final timetreeWebSocketServiceProvider = Provider<TimetreeWebSocketService>((ref) {
  return TimetreeWebSocketService(ref);
});
