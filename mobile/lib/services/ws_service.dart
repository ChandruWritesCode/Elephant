import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _pongWatchdog;

  Stream<dynamic>? _broadcastStream;
  Stream<dynamic>? get stream => _broadcastStream;
  bool get isConnected => _isConnected;

  VoidCallback? onConnectionLost;

  Future<bool> connect(String token) async {
    if (_isConnected) return true;
    try {
      final wsUrl = Uri.parse("${Env.wsBaseUrl}?token=$token");
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      _broadcastStream = _channel!.stream.asBroadcastStream();
      _isConnected = true;
      debugPrint("WebSocket Pipeline Connected straight to: ${Env.wsBaseUrl}");

      _startHeartbeat();
      return true;
    } catch (e) {
      _isConnected = false;
      debugPrint("WebSocket connection failure (Handshake rejected): $e");
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      emit({"type": "ping"});

      _pongWatchdog?.cancel();
      _pongWatchdog = Timer(const Duration(seconds: 6), () {
        debugPrint("🚨 WS: Watchdog timed out. Half-open socket detected.");
        disconnect();
        onConnectionLost?.call();
      });
    });
  }

  void registerPong() {
    _pongWatchdog?.cancel();
  }

  void emit(Map<String, dynamic> payload) {
    if (!_isConnected || _channel == null) {
      debugPrint("⚠️ WS: Attempted to emit frame while disconnected.");
      return;
    }
    try {
      final encoded = jsonEncode(payload);
      debugPrint("Sending Payload to WS: $encoded");
      _channel?.sink.add(encoded);
    } catch (e) {
      debugPrint("🚨 WS: Write error on sink (Socket broken): $e");
      disconnect();
      onConnectionLost?.call();
    }
  }

  void sendChat({
    required String messageId,
    required String receiverId,
    required String content,
    String? replyToMessageId,
  }) {
    emit({
      "type": "chat",
      "message_id": messageId,
      "receiver_id": receiverId,
      "content": content,
      "reply_to_message_id": replyToMessageId,
    });
  }

  void sendGroupChat({
    required String messageId,
    required String groupId,
    required String content,
    String? replyToMessageId,
  }) {
    emit({
      "type": "chat",
      "message_id": messageId,
      "group_id": groupId,
      "content": content,
      "reply_to_message_id": replyToMessageId,
    });
  }

  void sendTyping({
    String? receiverId,
    String? groupId,
    required bool isTyping,
  }) {
    emit({
      "type": "typing",
      if (receiverId != null) "receiver_id": receiverId,
      if (groupId != null) "group_id": groupId,
      "content": isTyping.toString(),
    });
  }

  void sendReadReceipt({String? receiverId, String? groupId}) {
    emit({
      "type": "read_receipt",
      if (receiverId != null) "receiver_id": receiverId,
      if (groupId != null) "group_id": groupId,
    });
  }

  void sendRequestStatus({required String targetId}) {
    emit({"type": "request_status", "receiver_id": targetId});
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _pongWatchdog?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _isConnected = false;
    _channel = null;
    debugPrint("WebSocket Pipeline Terminated Cleanly.");
  }
}