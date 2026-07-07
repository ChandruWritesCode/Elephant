import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  Stream<dynamic>? get stream => _channel?.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected) return;
    try {
      final wsUrl = Uri.parse("${Env.wsBaseUrl}?token=$token");
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      debugPrint("WebSocket Pipeline Connected straight to: ${Env.wsBaseUrl}");
    } catch (e) {
      _isConnected = false;
      debugPrint("WebSocket connection failure: $e");
    }
  }

  void emit(Map<String, dynamic> payload) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode(payload));
  }

  void sendChat({
    required String messageId,
    required String targetId,
    required String content,
  }) {
    emit({
      "type": "chat",
      "message_id": messageId,
      "receiver_id": targetId,
      "content": content,
    });
  }

  void sendTyping({required String targetId, required bool isTyping}) {
    emit({
      "type": "typing",
      "receiver_id": targetId,
      "content": isTyping.toString(),
    });
  }

  void sendReadReceipt({required String targetId}) {
    emit({"type": "read_receipt", "receiver_id": targetId});
  }

  void sendRequestStatus({required String targetId}) {
    emit({"type": "request_status", "receiver_id": targetId});
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
    debugPrint("WebSocket Pipeline Terminated Cleanly.");
  }

}