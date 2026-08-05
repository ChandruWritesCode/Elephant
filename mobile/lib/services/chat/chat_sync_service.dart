import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/ws_service.dart';
import '../db_services.dart';

class ChatSyncService {
  final WebSocketService _ws = WebSocketService();

  Future<void> processOfflineQueue(String currentUserId) async {
    final db = await DatabaseHelper.instance.database;

    final pendingActions = await db.query(
      'action_queue',
      orderBy: 'created_at ASC',
    );

    if (pendingActions.isEmpty) return;

    debugPrint("Processing ${pendingActions.length} queued actions...");

    for (var action in pendingActions) {
      final actionId = action['id'] as String;
      final type = action['action_type'] as String;
      final payload = jsonDecode(action['payload'] as String);

      try {
        if (type == 'send_chat' || type == 'send_group_chat') {
          if (_ws.isConnected) {
            if (type == 'send_group_chat') {
              _ws.sendGroupChat(
                messageId: payload['messageId'],
                groupId: payload['groupId'],
                content: payload['content'],
                senderId: currentUserId.isNotEmpty ? currentUserId : 'me',
                replyToMessageId: payload['replyToMessageId'],
              );
            } else {
              _ws.sendChat(
                messageId: payload['messageId'],
                receiverId: payload['receiverId'],
                content: payload['content'],
                replyToMessageId: payload['replyToMessageId'],
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Failed to process queue action $actionId: $e");
        await db.rawUpdate(
          'UPDATE action_queue SET retry_count = retry_count + 1 WHERE id = ?',
          [actionId],
        );
      }
    }
  }
}
