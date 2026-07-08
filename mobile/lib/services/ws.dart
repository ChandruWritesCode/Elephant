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

      await _channel!.ready;

      _isConnected = true;
      debugPrint("WebSocket Pipeline Connected straight to: ${Env.wsBaseUrl}");
    } catch (e) {
      _isConnected = false;
      debugPrint("WebSocket connection failure (Handshake rejected): $e");
    }
  }

  void emit(Map<String, dynamic> payload) {
    if (!_isConnected) return;
    debugPrint("Sending Payload to WS: ${jsonEncode(payload)}");
    _channel?.sink.add(jsonEncode(payload));
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
    required String senderId,
  }) {
    emit({
      "type": "chat",
      "message_id": messageId,
      "group_id": groupId,
      "content": content,
      "reply_to_message_id": replyToMessageId,
      "sender_id": senderId,
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
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
    debugPrint("WebSocket Pipeline Terminated Cleanly.");
  }
}
