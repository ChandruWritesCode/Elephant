import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/group.dart';
import 'package:mobile/models/inbox_item.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api.dart';
import '../services/ws.dart';

class ChatController extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  // List<Conversation> inbox = [];
  List<Message> activeChat = [];
  List<dynamic> contactSearchResults = [];

  String? currentChatUserId;
  String? _sessionToken;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isSearchLoading = false;
  bool _isWsInitialized = false;
  bool isChatHistoryLoading = false;

  StreamSubscription? _wsSubscription;

  Future<void> initSession(String token) async {
    _sessionToken = token;
    if (_isWsInitialized) return;
    _isWsInitialized = true;
    _connectWebSocket();
    await loadInbox();
  }

  void _connectWebSocket() async {
    if (_sessionToken == null) return;

    await _wsSubscription?.cancel();
    await _ws.connect(_sessionToken!);

    _wsSubscription = _ws.stream?.listen(
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
      onDone: () {
        _ws.disconnect();
        _isWsInitialized = false;
        Future.delayed(const Duration(seconds: 3), () {
          if (_sessionToken != null) {
            _isWsInitialized = true;
            _connectWebSocket();
          }
        });
      },
    );
  }

  Future<void> openChat(String targetUid) async {
    if (targetUid.isEmpty || targetUid == 'null') return;

    currentChatUserId = targetUid;
    activeChat.clear();
    isPeerTyping = false;
    isPeerOnline = false;
    isChatHistoryLoading = true;
    notifyListeners();

    try {
      final res = await _api.getChatHistory(targetUid);
      if (currentChatUserId != targetUid) return;

      final targetList = _extractDataList(res.data, ['messages']);
      final loadedMessages = await Isolate.run(() {
        return targetList.reversed
            .map((json) => Message.fromJson(json))
            .toList();
      });

      if (currentChatUserId != targetUid) return;

      activeChat = loadedMessages;
      _ws.sendReadReceipt(targetId: targetUid);
      _ws.sendRequestStatus(targetId: targetUid);
      unawaited(loadInbox());
    } catch (e) {
      debugPrint("Timeline tracking fail: $e");
    } finally {
      isChatHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> queryUsers(String term) async {
    final String cleanTerm = term.trim();
    if (cleanTerm.isEmpty || cleanTerm.length < 3) {
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

  Future<void> sendTextMessage(String text, {Message? replyingTo}) async {
    final cleanContent = text.trim();
    if (currentChatUserId == null || cleanContent.isEmpty) return;

    final targetId = currentChatUserId!;
    final clientMessageId = "cli_${DateTime.now().millisecondsSinceEpoch}";

    QuotedMessage? quoted;
    if (replyingTo != null) {
      quoted = QuotedMessage(
        id: replyingTo.id,
        senderId: replyingTo.senderId,
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
    );

    activeChat.add(optimisticMsg);
    notifyListeners();

    try {
      await _api.sendMessage(
        targetId,
        cleanContent,
        replyToMessageId: replyingTo?.id,
      );
      unawaited(loadInbox());
    } catch (e) {
      if (e is DioException) {
        debugPrint("BACKEND REJECTION REASON: ${e.response?.data}");
      } else {
        debugPrint("Failed to send message: $e");
      }
      activeChat.removeWhere((msg) => msg.id == clientMessageId);
      notifyListeners();
    }
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
        data['sender_id'] ??
        data['sender'] ??
        data['receiver_id'] ??
        data['user_id'] ??
        data['reader_id'];
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
        final incomingMsg = Message.fromJson(data);
        final clientMsgId = data['client_message_id'] ?? data['message_id'];
        final isFromMe =
            incomingMsg.senderId == 'me' ||
            data['sender_id'] == 'me' ||
            cleanSender == _sessionToken;

        final existingIndex = activeChat.indexWhere(
          (m) => m.id == clientMsgId || m.id == incomingMsg.id,
        );

        if (existingIndex != -1) {
          activeChat[existingIndex] = incomingMsg;
        } else if (isCurrentChat || isFromMe) {
          activeChat.add(incomingMsg);
          if (!isFromMe) {
            _ws.sendReadReceipt(targetId: currentChatUserId!);
          }
        }
        notifyListeners();
        loadInbox();
        break;

      case 'typing':
        if (isCurrentChat) {
          isPeerTyping = data['content'] == 'true';
          notifyListeners();
        }
        break;

      case 'read_receipt':
        if (isCurrentChat || cleanSender == cleanCurrentChat) {
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

  // Inside ChatController

  List<InboxItem> inbox = [];

  
  // Future<void> loadInbox() async {
  //   try {
  //     final res = await _api.getConversations();
  //     final targetList = _extractDataList(res.data, ['conversations']);
  //     inbox = targetList.map((json) => Conversation.fromJson(json)).toList();
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint("Inbox read error: $e");
  //   }
  // }


  Future<void> loadInbox() async {
    try {
      final responses = await Future.wait([
        _api.getConversations(),
      ]);

      final conversationRes = responses[0];
      final groupRes = responses[1];

      final rawConversations = _extractDataList(conversationRes.data, [
        'conversations',
      ]);
      final rawGroups = _extractDataList(groupRes.data, [
        'groups',
      ]);

      final mappedConversations = rawConversations
          .map((json) => Conversation.fromJson(json))
          .map((conv) => InboxItem.fromConversation(conv))
          .toList();

      final mappedGroups = rawGroups
          .map((json) => Group.fromJson(json))
          .map((group) => InboxItem.fromGroup(group))
          .toList();

      final combinedInbox = [...mappedConversations, ...mappedGroups];
      combinedInbox.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      inbox = combinedInbox;
      notifyListeners();
    } catch (e) {
      debugPrint("Inbox read error: $e");
    }
  }
}
