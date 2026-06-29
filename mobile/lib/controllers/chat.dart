import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api.dart';
import '../services/ws.dart';

class ChatController extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  List<Conversation> inbox = [];
  List<Message> activeChat = [];
  String? currentChatUserId;
  bool isPeerTyping = false;
  bool isPeerOnline = false;

  Future<void> initSession(String token) async {
    await _ws.connect(token);
    _ws.stream?.listen(
      (rawFrame) {
        try {
          _handleIncomingWebSocketEvent(jsonDecode(rawFrame));
        } catch (e) {
          debugPrint("WebSocket stream payload error: $e");
        }
      },
      onError: (err) => debugPrint("WS Pipeline Error: $err"),
      onDone: () => _ws.disconnect(),
    );
    await loadInbox();
  }

  Future<void> loadInbox() async {
    try {
      final res = await _api.getConversations();
      if (res.data['success'] == true && res.data['data'] != null) {
        final List rawList = res.data['data'];
        inbox = rawList.map((json) => Conversation.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Inbox read error: $e");
    }
  }

  Future<void> openChat(String targetUid) async {
    currentChatUserId = targetUid;
    activeChat.clear();
    isPeerTyping = false;
    isPeerOnline = false; 
    notifyListeners();

    try {
      final res = await _api.getChatHistory(targetUid);
      if (res.data['success'] == true && res.data['data'] != null) {
        final List rawHistory = res.data['data'];
        activeChat = rawHistory.map((json) => Message.fromJson(json)).toList().reversed.toList();
      }
      _ws.sendReadReceipt(targetId: targetUid);
      _ws.sendRequestStatus(targetId: targetUid); 
      await loadInbox();
    } catch (e) {
      debugPrint("Timeline tracking fail: $e");
    }
    notifyListeners();
  }

  void closeChat() {
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    activeChat.clear();
    notifyListeners();
  }

  void sendTextMessage(String text) {
    if (currentChatUserId == null || text.trim().isEmpty) return;

    final String clientMessageId = "cli_${DateTime.now().millisecondsSinceEpoch}";
    final String targetId = currentChatUserId!;
    final String cleanContent = text.trim();

    _ws.sendChat(messageId: "", targetId: targetId, content: cleanContent);

    final Message optimisticMsg = Message(
      id: clientMessageId,
      senderId: "me",
      receiverId: targetId,
      content: cleanContent,
      createdAt: DateTime.now(),
      isRead: false,
    );

    activeChat.add(optimisticMsg);
    notifyListeners();
    loadInbox();
  }

  void sendTypingNotification(bool typing) {
    if (currentChatUserId != null) {
      _ws.sendTyping(targetId: currentChatUserId!, isTyping: typing);
    }
  }

  void _handleIncomingWebSocketEvent(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? senderId = data['sender_id'];

    if (type == null) return;

    final String? cleanSender = senderId?.trim().toLowerCase();
    final String? cleanCurrentChat = currentChatUserId?.trim().toLowerCase();

    switch (type) {
      case 'user_status':
        final String? eventUserId = data['user_id']?.toString().trim().toLowerCase();
        if (eventUserId == cleanCurrentChat) {
          isPeerOnline = data['online'] == true;
          notifyListeners();
        }
        break;
      case 'chat':
        if (cleanSender != null && cleanSender == cleanCurrentChat) {
          activeChat.add(Message.fromJson(data));
          _ws.sendReadReceipt(targetId: currentChatUserId!);
          notifyListeners();
        } else {
          loadInbox();
        }
        break;
      case 'typing':
        if (cleanSender != null && cleanSender == cleanCurrentChat) {
          isPeerTyping = data['content'] == 'true';
          notifyListeners();
        }
        break;
      case 'read_receipt':
        if (cleanSender != null && cleanSender == cleanCurrentChat) {
          activeChat = activeChat.map((msg) {
            final String sId = msg.senderId.trim().toLowerCase();
            if (sId == 'me' || sId != cleanCurrentChat) {
              return msg.copyWith(isRead: true);
            }
            return msg;
          }).toList();
          notifyListeners();
          loadInbox();
        }
        break;
    }
  }
}