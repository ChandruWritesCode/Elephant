import 'package:flutter/material.dart';
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
  final WebSocketService _ws =
      WebSocketService();

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
            (data['sender_id'] ?? data['sender'] ?? data['receiver_id'])
                ?.toString()
                .trim()
                .toLowerCase();
        isCurrentChat = (eventSenderId == cleanCurrentChat);
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
        Message incomingMsg;
        try {
          incomingMsg = Message.fromJson(data);
        } catch (e) {
          debugPrint("❌ Failed to parse incoming WS message: $e");
          debugPrint("❌ Raw data was: $data");
          return;
        }

        final String echoId =
            data['message_id'] ??
            data['messageId'] ??
            data['client_message_id'] ??
            incomingMsg.id;

        final String cleanSenderId = incomingMsg.senderId.trim().toLowerCase();
        final String myId = currentUserId.trim().toLowerCase();
        final bool isMe = (cleanSenderId == 'me' || cleanSenderId == myId);

        final String dbChatId = data['group_id'] != null
            ? data['group_id'].toString()
            : (isMe ? incomingMsg.receiverId : incomingMsg.senderId);

        try {
          final db = await DatabaseHelper.instance.database;
          final queuedItems = await db.query(
            'action_queue',
            where: 'id = ?',
            whereArgs: [echoId],
          );

          final bool isOurMessage = queuedItems.isNotEmpty || isMe;

          if (isOurMessage) {
            int index = activeChatController.activeChat.indexWhere(
              (m) => m.id == echoId || m.id == incomingMsg.id,
            );
            String originalClientId = echoId;

            if (index == -1) {
              index = activeChatController.activeChat.lastIndexWhere(
                (m) =>
                    m.syncStatus == 'pending' &&
                    m.content.trim() == incomingMsg.content.trim(),
              );
              if (index != -1) {
                originalClientId = activeChatController.activeChat[index].id;
              }
            }

            if (index != -1) {
              await db.delete(
                'action_queue',
                where: 'id = ?',
                whereArgs: [originalClientId],
              );
              if (originalClientId != incomingMsg.id) {
                await db.delete(
                  'messages',
                  where: 'id = ?',
                  whereArgs: [originalClientId],
                );
              }

              await db.insert('messages', {
                'id': incomingMsg.id,
                'chat_id': dbChatId,
                'sender_id': incomingMsg.senderId,
                'content': incomingMsg.content,
                'created_at': incomingMsg.createdAt.millisecondsSinceEpoch,
                'is_read': 1,
                'reply_to_id': incomingMsg.replyToMessageId,
                'sync_status': 'synced',
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              activeChatController.activeChat[index] = activeChatController
                  .activeChat[index]
                  .copyWith(id: incomingMsg.id, syncStatus: 'synced');
              activeChatController.activeChat = [
                ...activeChatController.activeChat,
              ];
              activeChatController.refreshUI();
            } else {
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
                  activeChatController.refreshUI();
                }
                _ws.sendReadReceipt(
                  receiverId: activeChatController.isCurrentChatGroup
                      ? null
                      : activeChatController.currentChatUserId,
                  groupId: activeChatController.isCurrentChatGroup
                      ? activeChatController.currentChatUserId
                      : null,
                );
              }
            }
          } else {
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
          }
        } catch (e) {
          debugPrint("Failed to save incoming message to DB: $e");
        }

        inboxController.updateLocalInboxState(
          dbChatId,
          incomingMsg.content,
          incomingMsg.createdAt,
          !isCurrentChat &&
              !isMe,
          senderId: isMe ? 'me' : incomingMsg.senderId,
          syncStatus: 'synced',
          isRead: isCurrentChat || isMe,
        );
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
                return msg.copyWith(isRead: true);
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
