import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../models/message.dart';
import '../../services/api_services.dart';
import '../../services/ws_service.dart';
import '../../services/db_services.dart';

class ActiveChatController extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();
  final Uuid _uuid = const Uuid();

  List<Message> activeChat = [];
  String? currentChatUserId;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isChatHistoryLoading = false;
  bool isCurrentChatGroup = false;
  int chatOpenCount = 0;

  void refreshUI() {
    notifyListeners();
  }

  Future<void> openChat(String targetUid, {bool isGroup = false}) async {
    if (targetUid.isEmpty || targetUid == 'null') return;

    if (currentChatUserId != targetUid) {
      activeChat.clear();
      isChatHistoryLoading = true;
      chatOpenCount = 0;
    }

    chatOpenCount++;
    currentChatUserId = targetUid;
    isCurrentChatGroup = isGroup;
    isPeerTyping = false;
    isPeerOnline = false;
    notifyListeners();

    // 1. Load Local DB Messages
    try {
      final db = await DatabaseHelper.instance.database;
      final localData = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [targetUid],
        orderBy: 'created_at DESC',
        limit: 50,
      );

      if (localData.isNotEmpty && currentChatUserId == targetUid) {
        activeChat = localData
            .map(
              (row) => Message(
                id: row['id'] as String,
                senderId: row['sender_id'] as String,
                receiverId: targetUid,
                content: row['content'] as String,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  row['created_at'] as int,
                ),
                isRead: (row['is_read'] as int) == 1,
                replyToMessageId: row['reply_to_id'] as String?,
                syncStatus: row['sync_status'] as String? ?? 'synced',
              ),
            )
            .toList()
            .reversed
            .toList();

        isChatHistoryLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Local cache read failed: $e");
    }

    // 2. Fetch Network History
    try {
      final res = await _api.getChatHistory(targetUid, isGroup: isGroup);
      if (currentChatUserId != targetUid) return;

      final targetList = _extractDataList(res.data, ['messages']);
      final loadedMessages = targetList.reversed
          .map((json) => Message.fromJson(json))
          .toList();

      if (currentChatUserId != targetUid) return;

      if (loadedMessages.isNotEmpty) {
        final pendingMessages = activeChat
            .where((m) => m.syncStatus == 'pending')
            .toList();

        pendingMessages.removeWhere(
          (pending) => loadedMessages.any(
            (loaded) =>
                loaded.id == pending.id ||
                loaded.content.trim() == pending.content.trim(),
          ),
        );

        activeChat = [...loadedMessages, ...pendingMessages];

        final db = await DatabaseHelper.instance.database;
        Batch batch = db.batch();
        for (var msg in loadedMessages) {
          batch.insert('messages', {
            'id': msg.id,
            'chat_id': targetUid,
            'sender_id': msg.senderId,
            'content': msg.content,
            'created_at': msg.createdAt.millisecondsSinceEpoch,
            'is_read': msg.isRead ? 1 : 0,
            'reply_to_id': msg.replyToMessageId,
            'sync_status': 'synced',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }

      _ws.sendReadReceipt(
        receiverId: isGroup ? null : targetUid,
        groupId: isGroup ? targetUid : null,
      );

      _ws.sendRequestStatus(targetId: targetUid);
    } catch (e) {
      debugPrint("API Timeline tracking fail: $e");
    } finally {
      isChatHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncActiveChatSilently() async {
    if (currentChatUserId == null) return;
    final String targetUid = currentChatUserId!;

    try {
      final res = await _api.getChatHistory(
        targetUid,
        isGroup: isCurrentChatGroup,
      );
      if (currentChatUserId != targetUid) return;

      final targetList = _extractDataList(res.data, ['messages']);
      final loadedMessages = targetList.reversed
          .map((json) => Message.fromJson(json))
          .toList();

      if (currentChatUserId != targetUid) return;

      if (loadedMessages.isNotEmpty) {
        for (int i = 0; i < loadedMessages.length; i++) {
          final existingMsg = activeChat.firstWhere(
            (m) => m.id == loadedMessages[i].id,
            orElse: () => loadedMessages[i],
          );

          if (existingMsg.quotedMessage != null &&
              loadedMessages[i].quotedMessage != null) {
            if (loadedMessages[i].quotedMessage!.senderDisplayName.isEmpty) {
              loadedMessages[i] = Message(
                id: loadedMessages[i].id,
                senderId: loadedMessages[i].senderId,
                receiverId: loadedMessages[i].receiverId,
                content: loadedMessages[i].content,
                createdAt: loadedMessages[i].createdAt,
                isRead: loadedMessages[i].isRead,
                replyToMessageId: loadedMessages[i].replyToMessageId,
                quotedMessage: existingMsg.quotedMessage,
              );
            }
          }
        }

        final pendingMessages = activeChat
            .where((m) => m.syncStatus == 'pending')
            .toList();

        pendingMessages.removeWhere(
          (pending) => loadedMessages.any(
            (loaded) =>
                loaded.id == pending.id ||
                loaded.content.trim() == pending.content.trim(),
          ),
        );

        final mergedMessages = [...loadedMessages, ...pendingMessages];

        try {
          final db = await DatabaseHelper.instance.database;
          Batch batch = db.batch();
          for (var msg in loadedMessages) {
            batch.insert('messages', {
              'id': msg.id,
              'chat_id': targetUid,
              'sender_id': msg.senderId,
              'content': msg.content,
              'created_at': msg.createdAt.millisecondsSinceEpoch,
              'is_read': msg.isRead ? 1 : 0,
              'reply_to_id': msg.replyToMessageId,
              'sync_status': 'synced',
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
        } catch (dbError) {
          debugPrint("Silent Sync DB save failed: $dbError");
        }

        bool hasChanges = activeChat.length != mergedMessages.length;
        if (!hasChanges && activeChat.isNotEmpty && mergedMessages.isNotEmpty) {
          hasChanges =
              activeChat.last.id != mergedMessages.last.id ||
              activeChat.first.id != mergedMessages.first.id ||
              activeChat.any((m) => m.syncStatus == 'pending');
        }

        if (hasChanges) {
          activeChat = mergedMessages;
          notifyListeners();
          _ws.sendReadReceipt(
            receiverId: isCurrentChatGroup ? null : targetUid,
            groupId: isCurrentChatGroup ? targetUid : null,
          );
        }
      }
    } catch (e) {
      debugPrint("Silent chat sync fail: $e");
    }
  }

  Future<void> sendTextMessage(
    String text, {
    Message? replyingTo,
    String? replyingToName,
    String? senderId,
  }) async {
    final cleanContent = text.trim();
    if (currentChatUserId == null || cleanContent.isEmpty) return;

    final targetId = currentChatUserId!;
    final clientMessageId = _uuid.v4();

    QuotedMessage? quoted;
    if (replyingTo != null) {
      quoted = QuotedMessage(
        id: replyingTo.id,
        senderId: replyingTo.senderId,
        senderDisplayName: replyingToName ?? 'Unknown',
        content: replyingTo.content,
      );
    }

    final optimisticMsg = Message(
      id: clientMessageId,
      senderId: "me",
      receiverId: targetId,
      content: cleanContent,
      createdAt: DateTime.now(),
      isRead: false,
      replyToMessageId: replyingTo?.id,
      quotedMessage: quoted,
      syncStatus: 'pending',
    );

    activeChat = [...activeChat, optimisticMsg];
    notifyListeners();

    try {
      await DatabaseHelper.instance.insertMessage({
        'id': clientMessageId,
        'chat_id': targetId,
        'sender_id': 'me',
        'content': cleanContent,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_read': 0,
        'reply_to_id': replyingTo?.id,
        'sync_status': 'pending',
      });

      final payload = {
        'messageId': clientMessageId,
        'receiverId': isCurrentChatGroup ? null : targetId,
        'groupId': isCurrentChatGroup ? targetId : null,
        'content': cleanContent,
        'replyToMessageId': replyingTo?.id,
      };

      await DatabaseHelper.instance.queueAction(
        clientMessageId,
        isCurrentChatGroup ? 'send_group_chat' : 'send_chat',
        payload,
      );

      isCurrentChatGroup && senderId != null
          ? _ws.sendGroupChat(
              messageId: clientMessageId,
              groupId: targetId,
              content: cleanContent,
              senderId: senderId,
              replyToMessageId: replyingTo?.id,
            )
          : _ws.sendChat(
              messageId: clientMessageId,
              receiverId: targetId,
              content: cleanContent,
              replyToMessageId: replyingTo?.id,
            );

      if (_ws.isConnected) {
        markMessageAsSynced(clientMessageId);
      }

    } catch (e) {
      debugPrint("Immediate send failed, message queued: $e");
    }
  }

  void sendTypingNotification(bool typing) {
    if (currentChatUserId != null) {
      _ws.sendTyping(
        receiverId: isCurrentChatGroup ? null : currentChatUserId,
        groupId: isCurrentChatGroup ? currentChatUserId : null,
        isTyping: typing,
      );
    }
  }

  void closeChat(String closedChatId) {
    if (currentChatUserId == closedChatId) {
      chatOpenCount--;
      if (chatOpenCount <= 0) {
        currentChatUserId = null;
        isPeerTyping = false;
        isPeerOnline = false;
        activeChat.clear();
        chatOpenCount = 0;
      }
      notifyListeners();
    }
  }

  List<dynamic> _extractDataList(dynamic data, List<String> fallbackKeys) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'];
      for (final key in fallbackKeys) {
        if (data[key] is List) return data[key];
      }
    }
    return [];
  }

  Future<List<Message>> getLocalMessagesForChat(String chatId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'chat_id = ? COLLATE NOCASE',
        whereArgs: [chatId],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => Message.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching local messages for chat search/copy: $e");
      return [];
    }
  }

  Future<void> markMessageAsSynced(String messageId) async {
    final index = activeChat.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final existingMsg = activeChat[index];

      final newList = List<Message>.from(activeChat);

      newList[index] = Message(
        id: existingMsg.id,
        senderId: existingMsg.senderId,
        receiverId: existingMsg.receiverId,
        content: existingMsg.content,
        createdAt: existingMsg.createdAt,
        isRead: existingMsg.isRead,
        replyToMessageId: existingMsg.replyToMessageId,
        quotedMessage: existingMsg.quotedMessage,
        syncStatus: 'synced',
      );

      activeChat = newList;
      notifyListeners();

      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'messages',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [messageId],
        );
        await db.delete(
          'action_queue',
          where: 'id = ?',
          whereArgs: [messageId],
        );
      } catch (e) {
        debugPrint("Failed to update DB sync status: $e");
      }
    }
  }

  void addRealTimeMessage(Message newMsg) {
    if (currentChatUserId == null) return;

    bool belongsToCurrentChat =
        (isCurrentChatGroup && newMsg.receiverId == currentChatUserId) ||
        (!isCurrentChatGroup &&
            (newMsg.senderId == currentChatUserId ||
                newMsg.receiverId == currentChatUserId));

    if (belongsToCurrentChat) {
      final existingIndex = activeChat.indexWhere((m) => m.id == newMsg.id);

      if (existingIndex == -1) {
        activeChat = [...activeChat, newMsg];
        notifyListeners();

        _ws.sendReadReceipt(
          receiverId: isCurrentChatGroup ? null : currentChatUserId,
          groupId: isCurrentChatGroup ? currentChatUserId : null,
        );
      } else {
        if (activeChat[existingIndex].syncStatus == 'pending') {
          markMessageAsSynced(newMsg.id);
        }
      }
    }
  }
}