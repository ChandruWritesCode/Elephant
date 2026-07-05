import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
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
  List<dynamic> contactSearchResults = [];

  String? currentChatUserId;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isSearchLoading = false;

  Future<void> initSession(String token) async {
    await _ws.connect(token);
    _ws.stream?.listen(
      (rawFrame) {
        try {
          final decoded = jsonDecode(rawFrame);
          if (decoded is Map<String, dynamic>) {
            _handleIncomingWebSocketEvent(decoded);
          }
        } catch (e) {
          debugPrint("WebSocket payload error: $e");
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
      final targetList = _extractDataList(res.data, ['conversations']);

      inbox = targetList.map((json) => Conversation.fromJson(json)).toList();
      notifyListeners();
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
      final targetList = _extractDataList(res.data, ['messages']);

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
      notifyListeners();
    }
  }

  Future<void> queryUsers(String term) async {
    final String cleanTerm = term.trim();

    if (cleanTerm.isEmpty) {
      contactSearchResults.clear();
      notifyListeners();
      return;
    }

    if (cleanTerm.length < 3) {
      contactSearchResults.clear();
      notifyListeners();
      return;
    }

    isSearchLoading = true;
    notifyListeners();

    try {
      final res = await _api.searchUsers(term);
      contactSearchResults = _extractDataList(res.data, ['users']);
    } catch (e) {
      debugPrint("User query failure: $e");
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
    final cleanContent = text.trim();
    if (currentChatUserId == null || cleanContent.isEmpty) return;

    final targetId = currentChatUserId!;
    final clientMessageId = "cli_${DateTime.now().millisecondsSinceEpoch}";

    _ws.sendChat(messageId: "", targetId: targetId, content: cleanContent);

    final optimisticMsg = Message(
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
    if (type == null) return;

    final String? senderId =
        data['sender_id'] ?? data['sender'] ?? data['receiver_id'];
    final String? cleanSender = senderId?.trim().toLowerCase();
    final String? cleanCurrentChat = currentChatUserId?.trim().toLowerCase();
    final bool isCurrentChat =
        cleanSender != null && cleanSender == cleanCurrentChat;

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
        if (isCurrentChat) {
          activeChat.add(Message.fromJson(data));
          _ws.sendReadReceipt(targetId: currentChatUserId!);
          notifyListeners();
        }
        loadInbox();
        break;

      case 'typing':
        if (isCurrentChat) {
          isPeerTyping = data['content'] == 'true';
          notifyListeners();
        }
        break;

      case 'read_receipt':
        if (isCurrentChat) {
          bool updated = false;
          activeChat = activeChat.map((msg) {
            final String sId = msg.senderId.trim().toLowerCase();
            if (!msg.isRead && (sId == 'me' || sId != cleanCurrentChat)) {
              updated = true;
              return msg.copyWith(isRead: true);
            }
            return msg;
          }).toList();

          if (updated) {
            notifyListeners();
            loadInbox();
          }
        }
        break;
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
}
