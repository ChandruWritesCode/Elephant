import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../models/group.dart';
import '../../models/inbox_item.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../services/api_services.dart';
import '../../services/db_services.dart';

class InboxController extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<InboxItem> inbox = [];

  void clearInbox() {
    inbox = [];
  }

  Future<void> loadInbox({
    bool isOffline = false,
    String? currentChatId,
  }) async {
    // 1. Load from Local Cache
    try {
      final db = await DatabaseHelper.instance.database;
      final localData = await db.query('inbox', orderBy: 'timestamp DESC');
      if (localData.isNotEmpty) {
        inbox = localData.map((map) => InboxItem.fromMap(map)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to load local inbox cache: $e");
    }

    if (isOffline) return;

    // 2. Fetch from Network
    try {
      final response = await _api.getConversations();
      final rawData = _parseResponse(response.data, ['conversations']);
      final db = await DatabaseHelper.instance.database;

      List<InboxItem> combinedInbox = [];
      for (var json in rawData) {
        try {
          final bool isGroup =
              json['is_group'] == true || json['type'] == 'group';

          InboxItem item;
          if (isGroup) {
            item = InboxItem.fromGroup(Group.fromJson(json));
          } else {
            item = InboxItem.fromConversation(Conversation.fromJson(json));
          }

          if (item.lastMessage.contains('ciphertext') ||
              item.lastMessage.contains('🔒')) {
            final localMsg = await db.query(
              'messages',
              where:
                  'chat_id = ? AND content NOT LIKE ? AND content NOT LIKE ?',
              whereArgs: [item.id, '%ciphertext%', '%🔒%'],
              orderBy: 'created_at DESC',
              limit: 1,
            );

            if (localMsg.isNotEmpty) {
              item.lastMessage = localMsg.first['content'].toString();
            } else {
              item.lastMessage = "🔒 Encrypted Message";
            }
          }

          combinedInbox.add(item);
        } catch (e) {
          debugPrint("BAD JSON OBJECT: $json");
        }
      }

      combinedInbox.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      List<InboxItem> chatsToCatchUp = [];
      for (var newConv in combinedInbox) {
        final oldConvIndex = inbox.indexWhere((c) => c.id == newConv.id);
        if (oldConvIndex == -1 ||
            inbox[oldConvIndex].timestamp.isBefore(newConv.timestamp)) {
          chatsToCatchUp.add(newConv);
        }
      }

      if (_hasInboxChanged(inbox, combinedInbox)) {
        inbox = combinedInbox;
        notifyListeners();
        _saveInboxToDb(inbox);
      }

      for (var missedChat in chatsToCatchUp) {
        if (missedChat.id != currentChatId) {
          unawaited(
            _backgroundSyncChatHistoryToDb(missedChat.id, missedChat.isGroup),
          );
        }
      }
    } catch (e) {
      debugPrint("Network Inbox Read Error: $e");
    }
  }

  void updateLocalInboxState(
    String chatId,
    String lastMessage,
    DateTime timestamp,
    bool incrementUnread, {
    String? senderId,
    String syncStatus = 'synced',
    bool isRead = false,
  }) {
    final int index = inbox.indexWhere((item) => item.id == chatId);

    if (index != -1) {
      final existingItem = inbox[index];
      existingItem.lastMessage = lastMessage;
      existingItem.timestamp = timestamp;
      existingItem.lastMessageSender = senderId;
      existingItem.lastMessageSyncStatus = syncStatus;
      existingItem.lastMessageIsRead = isRead;

      if (incrementUnread) {
        existingItem.unreadCount += 1;
      }

      inbox.removeAt(index);
      inbox.insert(0, existingItem);

      DatabaseHelper.instance.database.then((db) {
        db.insert(
          'inbox',
          existingItem.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } else {
      unawaited(loadInbox());
    }
    notifyListeners();
  }

  Future<void> markInboxItemAsRead(String dbTargetChatId) async {
    final int inboxIndex = inbox.indexWhere(
      (item) => item.id == dbTargetChatId,
    );
    if (inboxIndex != -1) {
      inbox[inboxIndex].lastMessageIsRead = true;
      notifyListeners();

      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'inbox',
          {'last_message_is_read': 1},
          where: 'id = ?',
          whereArgs: [dbTargetChatId],
        );
      } catch (e) {
        debugPrint("Failed to update inbox read status: $e");
      }
    }
  }

  Future<void> _backgroundSyncChatHistoryToDb(
    String chatId,
    bool isGroup,
  ) async {
    try {
      final res = await _api.getChatHistory(chatId, isGroup: isGroup);
      final targetList = _parseResponse(res.data, ['messages']);
      final loadedMessages = targetList.reversed
          .map((json) => Message.fromJson(json))
          .toList();

      if (loadedMessages.isEmpty) return;

      final db = await DatabaseHelper.instance.database;
      Batch batch = db.batch();
      for (var msg in loadedMessages) {
        if (msg.content.contains('ciphertext') || msg.content.contains('🔒')) {
          continue;
        }

        batch.insert('messages', {
          'id': msg.id,
          'chat_id': chatId,
          'sender_id': msg.senderId,
          'content': msg.content,
          'created_at': msg.createdAt.millisecondsSinceEpoch,
          'is_read': msg.isRead ? 1 : 0,
          'reply_to_id': msg.replyToMessageId,
          'sync_status': 'synced',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("Background sync failed for $chatId: $e");
    }
  }

  Future<void> _saveInboxToDb(List<InboxItem> items) async {
    try {
      final db = await DatabaseHelper.instance.database;
      Batch batch = db.batch();
      for (var item in items) {
        batch.insert(
          'inbox',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (dbError) {
      debugPrint("Failed to save fresh inbox to DB: $dbError");
    }
  }

  bool _hasInboxChanged(List<InboxItem> oldList, List<InboxItem> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      final old = oldList[i];
      final current = newList[i];
      if (old.id != current.id ||
          old.lastMessage != current.lastMessage ||
          old.timestamp != current.timestamp ||
          old.unreadCount != current.unreadCount ||
          old.lastMessageSyncStatus != current.lastMessageSyncStatus) {
        return true;
      }
    }
    return false;
  }

  List<dynamic> _parseResponse(dynamic data, List<String> primaryKeys) {
    if (data is List) return data;
    if (data is Map) {
      for (var key in primaryKeys) {
        if (data.containsKey(key) && data[key] is List) return data[key];
      }
      if (data.containsKey('data') && data['data'] is List) return data['data'];
    }
    return [];
  }
}
