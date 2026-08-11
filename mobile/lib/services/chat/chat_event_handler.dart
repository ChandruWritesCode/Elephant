import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/services/signal_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:mobile/controllers/chat/active_chat_controller.dart';
import 'package:mobile/controllers/chat/inbox_controller.dart';
import '../../models/message.dart';
import '../db_services.dart';
import '../../services/ws_service.dart';

class ChatEventHandler {
  final InboxController inboxController;
  final ActiveChatController activeChatController;
  final String currentUserId;
  final WebSocketService _ws = WebSocketService();

  ChatEventHandler({
    required this.inboxController,
    required this.activeChatController,
    required this.currentUserId,
  });

  Future<void> handleIncomingEvent(Map<String, dynamic> data) async {
    final String? type = data['type'];
    if (type == null) return;

    final String? cleanCurrentChat = activeChatController.currentChatUserId
        ?.trim()
        .toLowerCase();
    bool isCurrentChat = false;

    if (cleanCurrentChat != null) {
      if (activeChatController.isCurrentChatGroup) {
        final String? eventGroupId = data['group_id']
            ?.toString()
            .trim()
            .toLowerCase();
        isCurrentChat = (eventGroupId == cleanCurrentChat);
      } else {
        final String? eventSenderId =
            data['sender_id']?.toString().trim().toLowerCase() ??
            data['sender']?.toString().trim().toLowerCase();
        final String? eventReceiverId = data['receiver_id']
            ?.toString()
            .trim()
            .toLowerCase();

        isCurrentChat =
            (eventSenderId == cleanCurrentChat ||
            eventReceiverId == cleanCurrentChat);
      }
    }

    switch (type) {
      case 'user_status':
      case 'status':
        final String? eventUserId = (data['user_id'] ?? data['id'])
            ?.toString()
            .trim()
            .toLowerCase();
        if (eventUserId == cleanCurrentChat &&
            !activeChatController.isCurrentChatGroup) {
          activeChatController.isPeerOnline =
              data['online'] == true || data['content'] == 'online';
          activeChatController.refreshUI();
        }
        break;

      case 'chat':
      case 'message':
        final String? incomingId = data['id']?.toString();
        final String echoId =
            data['message_id']?.toString() ??
            data['messageId']?.toString() ??
            data['client_message_id']?.toString() ??
            incomingId ??
            '';

        final String cleanSenderId = (data['sender_id'] ?? data['sender'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final String cleanReceiverId = (data['receiver_id'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final String myId = currentUserId.trim().toLowerCase();
        final bool isMe = (cleanSenderId == 'me' || cleanSenderId == myId);

        final String dbChatId = data['group_id'] != null
            ? data['group_id'].toString()
            : (isMe ? cleanReceiverId : cleanSenderId);

        try {
          final String rawContent = data['content']?.toString() ?? '';
          if (rawContent.startsWith('{') && rawContent.contains('ciphertext')) {
            final Map<String, dynamic> payload = jsonDecode(rawContent);
            final String remoteSender = data['sender_id']?.toString() ?? '';

            final decryptedText = await SignalService().decryptMessage(
              remoteSender,
              payload['ciphertext'],
              payload['type'],
            );
            data['content'] =
                decryptedText;
          }
        } catch (e) {
          debugPrint(
            "❌ Decryption failed for message. It may be out of sync: $e",
          );
          data['content'] = "🔒 [Message Decryption Failed]";
        }

        try {
          final db = await DatabaseHelper.instance.database;
          final queuedItems = await db.query(
            'action_queue',
            where: 'id = ?',
            whereArgs: [echoId],
          );

          final bool isOurMessage = queuedItems.isNotEmpty || isMe;

          if (isOurMessage) {
            final String newMsgId = incomingId ?? echoId;

            int index = activeChatController.activeChat.indexWhere(
              (m) => m.id == echoId || m.id == newMsgId,
            );
            String originalClientId = echoId;

            if (index == -1) {
              final content = data['content']?.toString().trim() ?? '';
              index = activeChatController.activeChat.lastIndexWhere(
                (m) => m.syncStatus == 'pending' && m.content.trim() == content,
              );
              if (index != -1) {
                originalClientId = activeChatController.activeChat[index].id;
              }
            }

            if (index != -1) {
              final existingMsg = activeChatController.activeChat[index];

              final newList = List<Message>.from(
                activeChatController.activeChat,
              );
              newList[index] = Message(
                id: newMsgId,
                senderId: existingMsg.senderId,
                receiverId: existingMsg.receiverId,
                content: existingMsg.content,
                createdAt: existingMsg.createdAt,
                isRead: existingMsg.isRead,
                replyToMessageId: existingMsg.replyToMessageId,
                quotedMessage: existingMsg.quotedMessage,
                syncStatus: 'synced',
              );

              activeChatController.activeChat = newList;
              activeChatController.refreshUI();

              await db.delete(
                'action_queue',
                where: 'id = ?',
                whereArgs: [originalClientId],
              );
              if (originalClientId != newMsgId) {
                await db.delete(
                  'messages',
                  where: 'id = ?',
                  whereArgs: [originalClientId],
                );
              }

              await db.insert('messages', {
                'id': newMsgId,
                'chat_id': dbChatId,
                'sender_id': existingMsg.senderId,
                'content': existingMsg.content,
                'created_at': existingMsg.createdAt.millisecondsSinceEpoch,
                'is_read': 1,
                'reply_to_id': existingMsg.replyToMessageId,
                'sync_status': 'synced',
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              inboxController.updateLocalInboxState(
                dbChatId,
                existingMsg.content,
                existingMsg.createdAt,
                false,
                senderId: 'me',
                syncStatus: 'synced',
                isRead: true,
              );

              return;
            }
          }

          Message incomingMsg;
          try {
            incomingMsg = Message.fromJson(data);
          } catch (e) {
            debugPrint("❌ Failed to parse peer WS message: $e");
            return;
          }

          await db.insert('messages', {
            'id': incomingMsg.id,
            'chat_id': dbChatId,
            'sender_id': incomingMsg.senderId,
            'content': incomingMsg.content,
            'created_at': incomingMsg.createdAt.millisecondsSinceEpoch,
            'is_read': isCurrentChat ? 1 : 0,
            'reply_to_id': incomingMsg.replyToMessageId,
            'sync_status': 'synced',
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          if (isCurrentChat) {
            if (!activeChatController.activeChat.any(
              (msg) => msg.id == incomingMsg.id,
            )) {
              activeChatController.activeChat = [
                ...activeChatController.activeChat,
                incomingMsg,
              ];
            }
            _ws.sendReadReceipt(
              receiverId: activeChatController.isCurrentChatGroup
                  ? null
                  : activeChatController.currentChatUserId,
              groupId: activeChatController.isCurrentChatGroup
                  ? activeChatController.currentChatUserId
                  : null,
            );
            activeChatController.refreshUI();
          }

          inboxController.updateLocalInboxState(
            dbChatId,
            incomingMsg.content,
            incomingMsg.createdAt,
            !isCurrentChat,
            senderId: incomingMsg.senderId,
            syncStatus: 'synced',
            isRead: isCurrentChat,
          );
        } catch (e) {
          debugPrint("Failed to save incoming message to DB: $e");
        }
        break;

      case 'typing':
        if (isCurrentChat) {
          final bool nowTyping =
              data['content'] == 'true' || data['content'] == true;
          if (activeChatController.isPeerTyping != nowTyping) {
            activeChatController.isPeerTyping = nowTyping;
            activeChatController.refreshUI();
          }
        }
        break;

      case 'read_receipt':
        final String payloadSender = (data['sender_id'] ?? '')
            .toString()
            .toLowerCase();
        final String payloadReceiver = (data['receiver_id'] ?? '')
            .toString()
            .toLowerCase();
        final String payloadGroup = (data['group_id'] ?? '')
            .toString()
            .toLowerCase();
        final String safeChatId = (activeChatController.currentChatUserId ?? '')
            .toLowerCase();

        bool isRelevantToThisChat = false;
        String dbTargetChatId = "";

        if (safeChatId.isNotEmpty) {
          if (activeChatController.isCurrentChatGroup) {
            isRelevantToThisChat = (payloadGroup == safeChatId);
            dbTargetChatId = payloadGroup;
          } else {
            isRelevantToThisChat =
                (payloadSender == safeChatId || payloadReceiver == safeChatId);
            dbTargetChatId = safeChatId;
          }
        }

        if (dbTargetChatId.isNotEmpty) {
          try {
            final db = await DatabaseHelper.instance.database;
            await db.update(
              'messages',
              {'is_read': 1},
              where: 'chat_id = ? COLLATE NOCASE AND sender_id = ?',
              whereArgs: [dbTargetChatId, 'me'],
            );
            inboxController.markInboxItemAsRead(dbTargetChatId);
          } catch (e) {
            debugPrint("Failed to update read receipts in DB: $e");
          }
        }

        if (isRelevantToThisChat) {
          bool updated = false;

          activeChatController.activeChat = activeChatController.activeChat.map(
            (msg) {
              final String msgSenderId = msg.senderId.trim().toLowerCase();
              if (!msg.isRead &&
                  (msgSenderId == 'me' || msgSenderId != safeChatId)) {
                updated = true;
                return Message(
                  id: msg.id,
                  senderId: msg.senderId,
                  receiverId: msg.receiverId,
                  content: msg.content,
                  createdAt: msg.createdAt,
                  isRead: true,
                  replyToMessageId: msg.replyToMessageId,
                  quotedMessage: msg.quotedMessage,
                  syncStatus: msg.syncStatus,
                );
              }
              return msg;
            },
          ).toList();

          if (updated) {
            activeChatController.refreshUI();
          }
        }
        break;
    }
  }
}
