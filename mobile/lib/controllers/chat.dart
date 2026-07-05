import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api.dart';
import '../services/ws.dart';

import 'dart:async';
import 'dart:isolate';

class ChatController extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  List<Conversation> inbox = [];
  List<Message> activeChat = [];
  List<dynamic> contactSearchResults = [];
  String? currentChatUserId;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isSearchLoading = false;

  Future<void> initSession(String token) async {
    _ws.disconnect();

    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    notifyListeners();

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

  void clearSessionData() {
    _ws.disconnect();
    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    notifyListeners();
  }

  Future<void> loadInbox() async {
    try {
      final res = await _api.getConversations();
      dynamic targetData;

      if (res.data is List) {
        targetData = res.data;
      } else if (res.data is Map) {
        targetData = res.data['data'] ?? res.data['conversations'] ?? res.data;
      }

      if (targetData is List) {
        inbox = targetData.map((json) => Conversation.fromJson(json)).toList();
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
      dynamic targetData;

      activeChat = await Isolate.run(() {
        return targetList.reversed
            .map((json) => Message.fromJson(json))
            .toList();
      });

      _ws.sendReadReceipt(targetId: targetUid);
      _ws.sendRequestStatus(targetId: targetUid);

      notifyListeners();

      unawaited(loadInbox());
    } catch (e) {
      debugPrint("Timeline tracking fail: $e");
    }
    notifyListeners();
  }

  Future<void> queryUsers(String term) async {
    final String cleanTerm = term.trim();
    if (cleanTerm.length < 3) {
      contactSearchResults.clear();
      notifyListeners();
      return;
    }

    isSearchLoading = true;
    notifyListeners();

    try {
      final res = await _api.searchUsers(cleanTerm);
      if (res.data == null) {
        contactSearchResults = [];
      } else if (res.data is List) {
        contactSearchResults = res.data;
      } else if (res.data is Map) {
        if (res.data['data'] != null && res.data['data'] is List) {
          contactSearchResults = res.data['data'];
        } else if (res.data['users'] != null && res.data['users'] is List) {
          contactSearchResults = res.data['users'];
        } else {
          contactSearchResults = [];
        }
      }
    } catch (e) {
      debugPrint("User query pipeline failure: $e");
      contactSearchResults.clear();
    } finally {
      isSearchLoading = false;
      notifyListeners();
    }
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

    final String clientMessageId =
        "cli_${DateTime.now().millisecondsSinceEpoch}";
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
    final String? senderId =
        data['sender_id'] ?? data['sender'] ?? data['receiver_id'];

    if (type == null) return;

    final String? cleanSender = senderId?.trim().toLowerCase();
    final String? cleanCurrentChat = currentChatUserId?.trim().toLowerCase();

    switch (type) {
      case 'user_status':
      case 'status':
        final String? eventUserId = (data['user_id'] ?? data['id'])
            ?.toString()
            .trim()
            .toLowerCase();
        if (eventUserId == cleanCurrentChat) {
          isPeerOnline = data['online'] == true || data['content'] == 'online';
          notifyListeners();
        }
        break;
      case 'chat':
      case 'message':
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
