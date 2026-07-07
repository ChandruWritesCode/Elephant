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

class ChatController extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  List<Message> activeChat = [];
  List<dynamic> contactSearchResults = [];
  List<InboxItem> inbox = [];

  String? currentChatUserId;
  String? _sessionToken;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isSearchLoading = false;
  bool _isWsInitialized = false;
  bool isChatHistoryLoading = false;

  StreamSubscription? _wsSubscription;
  Timer? _backgroundSyncTimer;

  ChatController() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_sessionToken != null) {
        _isWsInitialized = false;
        _connectWebSocket();
        loadInbox();
        _startBackgroundSync();
      }
    } else if (state == AppLifecycleState.paused) {
      _backgroundSyncTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSubscription?.cancel();
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> initSession(String token) async {
    _sessionToken = token;
    _startBackgroundSync();
    if (_isWsInitialized) return;
    _isWsInitialized = true;
    _connectWebSocket();
    await loadInbox();
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadInbox();

      if (currentChatUserId != null) {
        syncActiveChatSilently();
      }
    });
  }

  void _connectWebSocket() async {
    if (_sessionToken == null) return;

    await _wsSubscription?.cancel();
    await _ws.connect(_sessionToken!);

    _wsSubscription = _ws.stream?.listen(
      (rawFrame) {
        unawaited(loadInbox());

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

  Future<void> sendTextMessage(
    String text, {
    Message? replyingTo,
    String? replyingToName,
  }) async {
    final cleanContent = text.trim();
    if (currentChatUserId == null || cleanContent.isEmpty) return;

    final targetId = currentChatUserId!;
    final clientMessageId = "cli_${DateTime.now().millisecondsSinceEpoch}";

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

          if (isPeerOnline) unawaited(syncActiveChatSilently());
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
          final bool nowTyping =
              data['content'] == 'true' || data['content'] == true;

          if (isPeerTyping != nowTyping) {
            isPeerTyping = nowTyping;
            notifyListeners();

            if (!isPeerTyping) {
              Future.delayed(const Duration(milliseconds: 500), () {
                unawaited(syncActiveChatSilently());
              });
            }
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
        final String safeChatId = (currentChatUserId ?? '').toLowerCase();

        final bool isRelevantToThisChat =
            safeChatId.isNotEmpty &&
            (payloadSender == safeChatId || payloadReceiver == safeChatId);

        if (isRelevantToThisChat) {
          bool updated = false;

          activeChat = activeChat.map((msg) {
            final String msgSenderId = msg.senderId.trim().toLowerCase();

            if (!msg.isRead &&
                (msgSenderId == 'me' || msgSenderId != safeChatId)) {
              updated = true;
              return msg.copyWith(isRead: true);
            }
            return msg;
          }).toList();

          if (updated) {
            notifyListeners();
          }

          unawaited(syncActiveChatSilently());
        }
        break;
    }
  }

  Future<void> syncActiveChatSilently() async {
    if (currentChatUserId == null) return;
    final String targetUid = currentChatUserId!;

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
              quotedMessage:
                  existingMsg.quotedMessage,
            );
          }
        }
      }

      bool hasChanges = activeChat.length != loadedMessages.length;
      if (!hasChanges && activeChat.isNotEmpty && loadedMessages.isNotEmpty) {
        hasChanges =
            activeChat.last.id != loadedMessages.last.id ||
            activeChat.first.id != loadedMessages.first.id;
      }

      if (hasChanges) {
        activeChat = loadedMessages;
        notifyListeners();
        _ws.sendReadReceipt(targetId: targetUid);
      }
    } catch (e) {
      debugPrint("Silent chat sync fail: $e");
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

  Future<void> loadInbox() async {
    try {
      final responses = await Future.wait([
        _api.getConversations(),
        _api.getGroups(),
      ]);

      final conversationRes = responses[0];
      final groupRes = responses[1];

      final rawConversations = _extractDataList(conversationRes.data, [
        'conversations',
      ]);
      final rawGroups = _extractDataList(groupRes.data, ['groups']);

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

      if (inbox.length != combinedInbox.length ||
          (inbox.isNotEmpty &&
              combinedInbox.isNotEmpty &&
              inbox.first.id != combinedInbox.first.id) ||
          (inbox.isNotEmpty &&
              combinedInbox.isNotEmpty &&
              inbox.first.lastMessage != combinedInbox.first.lastMessage)) {
        inbox = combinedInbox;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Inbox read error: $e");
    }
  }
}
