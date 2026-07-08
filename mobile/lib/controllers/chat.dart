import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:mobile/controllers/auth.dart';
import 'package:mobile/models/group.dart';
import 'package:mobile/models/inbox_item.dart';
import 'package:mobile/pages/chat_details_page.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api.dart';
import '../services/ws.dart';
import '../services/auth.dart';

class ChatController extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();
  final AuthService _auth = AuthService();
  // final AuthState _user = AuthState();

  List<Message> activeChat = [];
  List<dynamic> contactSearchResults = [];
  List<InboxItem> inbox = [];
  Map<String, String> groupMemberNames = {};
  Map<String, String> userCache = {};

  String? currentChatUserId;
  bool isPeerTyping = false;
  bool isPeerOnline = false;
  bool isSearchLoading = false;
  bool isChatHistoryLoading = false;
  bool isCurrentChatGroup = false;

  bool _isLoadingDetails = false;
  bool get isLoadingDetails => _isLoadingDetails;

  List<ChatMember> _currentGroupMembers = [];
  List<ChatMember> get currentGroupMembers => _currentGroupMembers;

  bool _isWsInitialized = false;

  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;

  ChatController() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isWsInitialized = false;
      _connectWebSocket();
      loadInbox();
    } else if (state == AppLifecycleState.paused) {
      _reconnectTimer?.cancel();
      _ws.disconnect();
      _isWsInitialized = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSubscription?.cancel();
    _reconnectTimer?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  Future<void> initSession() async {
    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;

    // _startBackgroundSync();

    if (_isWsInitialized) return;
    _isWsInitialized = true;

    _connectWebSocket();
    notifyListeners();
  }

  void clearSessionData() {
    _ws.disconnect();
    _isWsInitialized = false;
    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    notifyListeners();
  }

  void _connectWebSocket() async {

    if (_ws.isConnected) return;

    _reconnectTimer?.cancel();

    final freshToken = await _auth.getToken();
    if (freshToken == null) return;

    await _wsSubscription?.cancel();
    _ws.disconnect();
    await _ws.connect(freshToken);

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

        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 3), () {
          _isWsInitialized = true;
          _connectWebSocket();
        });
      },
    );
  }

  Future<void> openChat(String targetUid, {bool isGroup = false}) async {
    if (targetUid.isEmpty || targetUid == 'null') return;

    currentChatUserId = targetUid;
    isCurrentChatGroup = isGroup;
    activeChat.clear();
    isPeerTyping = false;
    isPeerOnline = false;
    isChatHistoryLoading = true;
    groupMemberNames.clear();

    if (isGroup) {
      _api
          .getGroupMembers(targetUid)
          .then((memberRes) {
            if (currentChatUserId != targetUid) return;
            final memberList = _extractDataList(memberRes.data, ['members']);

            _currentGroupMembers = memberList
                .map((json) => ChatMember.fromJson(json))
                .toList();

            for (var member in memberList) {
              userCache[member['user_id'].toString()] =
                  member['display_name'] ?? 'Member';
              groupMemberNames[member['user_id'].toString()] =
                  member['display_name'] ?? 'Unknown';
            }
            notifyListeners();
          })
          .catchError((e) {
            debugPrint("Failed to load group members: $e");
          });
    }

    notifyListeners();

    try {
      final res = await _api.getChatHistory(targetUid, isGroup: isGroup);
      if (currentChatUserId != targetUid) return;

      final targetList = _extractDataList(res.data, ['messages']);
      final loadedMessages = targetList.reversed
          .map((json) => Message.fromJson(json))
          .toList();

      if (currentChatUserId != targetUid) return;

      activeChat = loadedMessages;
      _ws.sendReadReceipt(
        receiverId: isCurrentChatGroup ? null : targetUid,
        groupId: isCurrentChatGroup ? targetUid : null,
      );

      _ws.sendRequestStatus(targetId: targetUid);

      unawaited(loadInbox());
    } catch (e) {
      debugPrint("Timeline tracking fail: $e");
    } finally {
      isChatHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupMembers(String groupId) async {
    try {
      _isLoadingDetails = true;
      notifyListeners();

      final response = await _api.getGroupMembers(groupId);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        _currentGroupMembers = data
            .map((json) => ChatMember.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching members: $e");
    } finally {
      _isLoadingDetails = false;
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
    String? senderId,
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
      isCurrentChatGroup && senderId != null
          ? _ws.sendGroupChat(
              messageId: "",
              groupId: targetId,
              content: cleanContent,
              senderId: senderId,
              replyToMessageId: replyingTo?.id,
            )
          : _ws.sendChat(
              messageId: "",
              receiverId: targetId,
              content: cleanContent,
              replyToMessageId: replyingTo?.id,
            );
      unawaited(loadInbox());
    } catch (e) {
      debugPrint("Failed to send message: $e");
      activeChat.removeWhere((msg) => msg.id == clientMessageId);
      notifyListeners();
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

  void _handleIncomingWebSocketEvent(Map<String, dynamic> data) {
    final String? type = data['type'];
    if (type == null) return;

    final String? cleanCurrentChat = currentChatUserId?.trim().toLowerCase();

    bool isCurrentChat = false;
    if (cleanCurrentChat != null) {
      if (isCurrentChatGroup) {
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
        if (eventUserId == cleanCurrentChat && !isCurrentChatGroup) {
          isPeerOnline = data['online'] == true || data['content'] == 'online';
          notifyListeners();
          // if (isPeerOnline) unawaited(syncActiveChatSilently());
        }
        break;

      case 'chat':
      case 'message':
        if (isCurrentChat) {
          activeChat.add(Message.fromJson(data));
          _ws.sendReadReceipt(
            receiverId: isCurrentChatGroup ? null : currentChatUserId,
            groupId: isCurrentChatGroup ? currentChatUserId : null,
          );
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

            // if (!isPeerTyping) {
            //   Future.delayed(const Duration(milliseconds: 500), () {
            //     unawaited(syncActiveChatSilently());
            //   });
            // }
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
        final String safeChatId = (currentChatUserId ?? '').toLowerCase();

        bool isRelevantToThisChat = false;
        if (safeChatId.isNotEmpty) {
          if (isCurrentChatGroup) {
            isRelevantToThisChat = (payloadGroup == safeChatId);
          } else {
            isRelevantToThisChat =
                (payloadSender == safeChatId || payloadReceiver == safeChatId);
          }
        }

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
          // unawaited(syncActiveChatSilently());
        }
        break;
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

      bool hasChanges = activeChat.length != loadedMessages.length;
      if (!hasChanges && activeChat.isNotEmpty && loadedMessages.isNotEmpty) {
        hasChanges =
            activeChat.last.id != loadedMessages.last.id ||
            activeChat.first.id != loadedMessages.first.id;
      }

      if (hasChanges) {
        activeChat = loadedMessages;
        notifyListeners();
        _ws.sendReadReceipt(
          receiverId: isCurrentChatGroup ? null : targetUid,
          groupId: isCurrentChatGroup ? targetUid : null,
        );
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
      final response = await _api.getConversations();
      // debugPrint("RAW INBOX DATA: ${response.data}");
      final rawData = _parseResponse(response.data, ['conversations']);

      List<InboxItem> combinedInbox = [];

      for (var json in rawData) {
        try{final bool isGroup =
            json['is_group'] == true || json['type'] == 'group';

        if (isGroup) {
          combinedInbox.add(InboxItem.fromGroup(Group.fromJson(json)));

          final String? groupId = json['id'];
            if (groupId != null) {
              _api
                  .getGroupMembers(groupId)
                  .then((res) {
                    final members = _extractDataList(res.data, ['members']);
                    bool updatedCache = false;
                    for (var m in members) {
                      final uid = m['user_id'].toString();
                      final name = m['display_name'] ?? 'Member';
                      if (userCache[uid] != name) {
                        userCache[uid] = name;
                        updatedCache = true;
                      }
                    }
                    if (updatedCache) notifyListeners();
                  })
                  .catchError((_) {});
            }

        } else {
          combinedInbox.add(
            InboxItem.fromConversation(Conversation.fromJson(json)),
          );
        }} catch (e){
          debugPrint("❌ CRASH ON ITEM PARSE: $e");
          debugPrint("❌ BAD JSON OBJECT: $json");
        }
      }

      combinedInbox.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_hasInboxChanged(inbox, combinedInbox)) {
        inbox = combinedInbox;
        notifyListeners();
        if (currentChatUserId != null) {
          unawaited(syncActiveChatSilently());
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ MAJOR INBOX READ ERROR: $e");
      debugPrint("❌ STACK TRACE: $stackTrace");
    }
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

  bool _hasInboxChanged(List<InboxItem> oldList, List<InboxItem> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      final old = oldList[i];
      final current = newList[i];
      if (old.id != current.id ||
          old.lastMessage != current.lastMessage ||
          old.timestamp != current.timestamp ||
          old.unreadCount != current.unreadCount) {
        return true;
      }
    }
    return false;
  }
}
