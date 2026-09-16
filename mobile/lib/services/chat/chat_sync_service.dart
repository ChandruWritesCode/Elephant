import 'dart:convert';
import 'package:flutter/material.dart';
import '../../controllers/chat/active_chat_controller.dart';
import '../../services/ws_service.dart';
import '../db_services.dart';

class ChatSyncService {
  final WebSocketService _ws = WebSocketService();
  bool _isSyncing = false;

  Future<void> processOfflineQueue(
    String currentUserId, {
    ActiveChatController? activeChatController,
  }) async {
    if (_isSyncing || !_ws.isConnected) return;
    _isSyncing = true;

    try {
      final db = await DatabaseHelper.instance.database;

      final pendingActions = await db.query(
        'action_queue',
        where: 'retry_count < ?',
        whereArgs: [5],
        orderBy: 'created_at ASC',
      );

      if (pendingActions.isEmpty) return;

      debugPrint("Processing ${pendingActions.length} queued offline actions...");

      for (var action in pendingActions) {
        if (!_ws.isConnected) break;

        final actionId = action['id'] as String;
        final type = action['action_type'] as String;
        final payload = jsonDecode(action['payload'] as String);

        try {
          if (type == 'send_chat') {
            _ws.sendChat(
              messageId: payload['messageId'],
              receiverId: payload['receiverId'],
              content: payload['content'],
              replyToMessageId: payload['replyToMessageId'],
            );
          } else if (type == 'send_group_chat') {
            _ws.sendGroupChat(
              messageId: payload['messageId'],
              groupId: payload['groupId'],
              content: payload['content'],
              replyToMessageId: payload['replyToMessageId'],
            );
          }

          await Future.delayed(const Duration(milliseconds: 50));

          await db.update(
            'messages',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [actionId],
          );

          await db.delete(
            'action_queue',
            where: 'id = ?',
            whereArgs: [actionId],
          );

          activeChatController?.markMessageAsSynced(actionId);

        } catch (e) {
          debugPrint("Failed to flush queue action $actionId: $e");
          await db.rawUpdate(
            'UPDATE action_queue SET retry_count = retry_count + 1 WHERE id = ?',
            [actionId],
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}