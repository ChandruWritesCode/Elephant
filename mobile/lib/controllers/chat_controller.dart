import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth_state.dart';
import 'package:mobile/models/group.dart';
import 'package:mobile/models/inbox_item.dart';
import 'package:mobile/pages/chat/chat_details_page.dart';
import 'package:mobile/cache/database/services/db_services.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api_services.dart';
import '../services/ws_service.dart';
import '../services/auth_service.dart';

class ChatController extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();
  final AuthService _auth = AuthService();
  final AuthState _user = AuthState();
  final Uuid _uuid = const Uuid();
  final Set<String> _fetchedGroups = {};

  StreamSubscription? _connectivitySubscription;

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

  bool isOffline = false;

  bool _isLoadingDetails = false;
  bool get isLoadingDetails => _isLoadingDetails;

  List<ChatMember> _currentGroupMembers = [];
  List<ChatMember> get currentGroupMembers => _currentGroupMembers;

  bool _isWsInitialized = false;
  bool _isWsConnecting = false;
  
  int _chatOpenCount = 0; 

  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;

  ChatController() {
    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final bool currentlyOffline = result.contains(ConnectivityResult.none);

      if (isOffline != currentlyOffline) {
        isOffline = currentlyOffline;
        notifyListeners();

        if (!isOffline) {
          _connectWebSocket();
          loadInbox();
        } else {
          isPeerOnline = false;
          isPeerTyping = false;
          _ws.disconnect();
          _isWsInitialized = false;
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isWsInitialized = false;
      _connectWebSocket();
      _processOfflineQueue();
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
    _connectivitySubscription?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  Future<void> _processOfflineQueue() async {
    final db = await DatabaseHelper.instance.database;

    final pendingActions = await db.query(
      'action_queue',
      orderBy: 'created_at ASC',
    );

    if (pendingActions.isEmpty) return;

    debugPrint("Processing ${pendingActions.length} queued actions...");

    for (var action in pendingActions) {
      final actionId = action['id'] as String;
      final type = action['action_type'] as String;
      final payload = jsonDecode(action['payload'] as String);

      try {
        if (type == 'send_chat' || type == 'send_group_chat') {
          if (_ws.isConnected) {
            type == 'send_group_chat'
                ? _ws.sendGroupChat(
                    messageId: payload['messageId'],
                    groupId: payload['groupId'],
                    content: payload['content'],
                    senderId: _user.currentUser?.id ?? 'me',
                    replyToMessageId: payload['replyToMessageId'],
                  )
                : _ws.sendChat(
                    messageId: payload['messageId'],
                    receiverId: payload['receiverId'],
                    content: payload['content'],
                    replyToMessageId: payload['replyToMessageId'],
                  );
          }
        }
      } catch (e) {
        debugPrint("Failed to process queue action $actionId: $e");
        await db.rawUpdate(
          'UPDATE action_queue SET retry_count = retry_count + 1 WHERE id = ?',
          [actionId],
        );
      }
    }
  }

  Future<void> initSession() async {
    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    _chatOpenCount = 0;

    if (_isWsInitialized) return;
    _isWsInitialized = true;

    _connectWebSocket();
    notifyListeners();
  }

  Future<void> clearSessionData() async {
    _ws.disconnect();
    _isWsInitialized = false;
    _reconnectTimer?.cancel();

    inbox.clear();
    activeChat.clear();
    contactSearchResults.clear();
    groupMemberNames.clear();
    userCache.clear();
    _currentGroupMembers.clear();
    currentChatUserId = null;
    isPeerTyping = false;
    isPeerOnline = false;
    _chatOpenCount = 0;
    
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.delete('messages');
      await db.delete('inbox');
      await db.delete('action_queue');
      
      debugPrint("Local SQLite cache successfully wiped for logout.");
    } catch (e) {
      debugPrint("CRITICAL: Failed to wipe SQLite DB on logout: $e");
    }

    notifyListeners();
  }

  void _updateLocalInboxState(
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

      DatabaseHelper.instance.database
          .then((db) {
            db.insert(
              'inbox',
              existingItem.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          })
          .catchError((e) => debugPrint("Failed to save inbox to DB: $e"));
    } else {
      unawaited(loadInbox());
    }

    notifyListeners();
  }

  void _connectWebSocket() async {
    if (_ws.isConnected || _isWsConnecting) return;
    _isWsConnecting = true;

    try {
      _reconnectTimer?.cancel();

      final freshToken = await _auth.getToken();
      if (freshToken == null) {
        _isWsConnecting = false;
        return;
      }

      await _wsSubscription?.cancel();
      _ws.disconnect();

      final bool connected = await _ws.connect(freshToken);

      if (!connected) {
        _triggerReconnectLoop();
        return;
      }

      _processOfflineQueue();

      if (currentChatUserId != null && !isCurrentChatGroup) {
        _ws.sendRequestStatus(targetId: currentChatUserId!);
      }

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
        onError: (err) {
          debugPrint("WS Pipeline Error: $err");
          _triggerReconnectLoop();
        },
        onDone: () {
          debugPrint("WS Pipeline Closed by Server.");
          _triggerReconnectLoop();
        },
      );
    } catch (e) {
      debugPrint("WS Setup Error: $e");
      _triggerReconnectLoop();
    } finally {
      _isWsConnecting = false;
    }
  }

  void _triggerReconnectLoop() {
    _ws.disconnect();
    _isWsInitialized = false;
    _isWsConnecting = false;
    
    if (isPeerOnline) {
      isPeerOnline = false;
      notifyListeners();
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!isOffline) {
        _isWsInitialized = true;
        _connectWebSocket();
      }
    });
  }

  Future<void> _backgroundSyncChatHistoryToDb(
    String chatId,
    bool isGroup,
  ) async {
    if (isOffline) return;

    try {
      final res = await _api.getChatHistory(chatId, isGroup: isGroup);
      final targetList = _extractDataList(res.data, ['messages']);
      final loadedMessages = targetList.reversed
          .map((json) => Message.fromJson(json))
          .toList();

      if (loadedMessages.isEmpty) return;

      final db = await DatabaseHelper.instance.database;
      Batch batch = db.batch();
      for (var msg in loadedMessages) {
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

  Future<List<Message>> getLocalMessagesForChat(String chatId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final localData = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at DESC',
        limit: 50,
        offset: 0,
      );

      return localData
          .map(
            (row) => Message(
              id: row['id'] as String,
              senderId: row['sender_id'] as String,
              receiverId: chatId,
              content: row['content'] as String,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                row['created_at'] as int,
              ),
              isRead: (row['is_read'] as int) == 1,
              replyToMessageId: row['reply_to_id'] as String?,
              syncStatus: row['sync_status'] as String? ?? 'synced',
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching local messages: $e");
      return [];
    }
  }

  Future<void> openChat(String targetUid, {bool isGroup = false}) async {
    if (targetUid.isEmpty || targetUid == 'null') return;

    if (currentChatUserId != targetUid) {
      activeChat.clear();
      isChatHistoryLoading = true;
      _chatOpenCount = 0;
    }

    _chatOpenCount++; 
    currentChatUserId = targetUid;
    isCurrentChatGroup = isGroup;
    isPeerTyping = false;
    isPeerOnline = false;
    groupMemberNames.clear();
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final localData = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [targetUid],
        orderBy: 'created_at DESC', 
        limit: 50,
        offset: 0,
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
          .catchError((e) => debugPrint("Failed to load group members: $e"));
    }

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
          (pending) => loadedMessages.any((loaded) => 
            loaded.id == pending.id || 
            loaded.content.trim() == pending.content.trim()),
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
        receiverId: isCurrentChatGroup ? null : targetUid,
        groupId: isCurrentChatGroup ? targetUid : null,
      );

      _ws.sendRequestStatus(targetId: targetUid);
      unawaited(loadInbox());
    } catch (e) {
      debugPrint("API Timeline tracking fail (Offline?): $e");
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

  void closeChat(String closedChatId) {
    if (currentChatUserId == closedChatId) {
      _chatOpenCount--;
      
      if (_chatOpenCount <= 0) {
        currentChatUserId = null;
        isPeerTyping = false;
        isPeerOnline = false;
        activeChat.clear();
        _chatOpenCount = 0; 
      }
      notifyListeners();
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
    
    _updateLocalInboxState(
      targetId,
      cleanContent,
      optimisticMsg.createdAt,
      false,
      senderId: 'me',
      syncStatus: 'pending',
      isRead: false,
    );
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
      unawaited(loadInbox());
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

  Future<void> _handleIncomingWebSocketEvent(Map<String, dynamic> data) async {
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
        }
        break;

      case 'chat':
      case 'message':
        final incomingMsg = Message.fromJson(data);

        final String echoId =
            data['message_id'] ?? 
            data['messageId'] ?? 
            data['client_message_id'] ?? 
            incomingMsg.id;

        final String dbChatId = data['group_id'] != null
            ? data['group_id'].toString()
            : incomingMsg.senderId;

        try {
          final db = await DatabaseHelper.instance.database;

          final queuedItems = await db.query(
            'action_queue',
            where: 'id = ?',
            whereArgs: [echoId],
          );
          
          final String cleanSenderId = incomingMsg.senderId.trim().toLowerCase();
          final String? myId = _user.currentUser?.id.trim().toLowerCase();
          final bool isMe = (cleanSenderId == 'me' || cleanSenderId == myId);

          final bool isOurMessage = queuedItems.isNotEmpty || isMe;

          if (isOurMessage) {
            int index = activeChat.indexWhere((m) => m.id == echoId || m.id == incomingMsg.id);
            String originalClientId = echoId;

            if (index == -1) {
              index = activeChat.lastIndexWhere((m) => 
                  m.syncStatus == 'pending' && 
                  m.content.trim() == incomingMsg.content.trim());
              
              if (index != -1) {
                originalClientId = activeChat[index].id;
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

              activeChat[index] = activeChat[index].copyWith(
                id: incomingMsg.id,
                syncStatus: 'synced',
              );
              activeChat = [...activeChat];
              notifyListeners();
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
                if (!activeChat.any((msg) => msg.id == incomingMsg.id)) {
                  activeChat = [...activeChat, incomingMsg];
                  notifyListeners();
                }
                _ws.sendReadReceipt(
                  receiverId: isCurrentChatGroup ? null : currentChatUserId,
                  groupId: isCurrentChatGroup ? currentChatUserId : null,
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
              if (!activeChat.any((msg) => msg.id == incomingMsg.id)) {
                activeChat = [...activeChat, incomingMsg];
              }
              _ws.sendReadReceipt(
                receiverId: isCurrentChatGroup ? null : currentChatUserId,
                groupId: isCurrentChatGroup ? currentChatUserId : null,
              );
              notifyListeners();
            }
          }
        } catch (e) {
          debugPrint("Failed to save incoming message to DB: $e");
        }

        final String cleanSenderId = incomingMsg.senderId.trim().toLowerCase();
        final String? myId = _user.currentUser?.id.trim().toLowerCase();
        final bool isMe = (cleanSenderId == 'me' || cleanSenderId == myId);

        _updateLocalInboxState(
          dbChatId,
          incomingMsg.content,
          incomingMsg.createdAt,
          !isCurrentChat,
          senderId: isMe ? 'me' : incomingMsg.senderId,
          syncStatus: 'synced',
          isRead: isCurrentChat,
        );

        break;

      case 'typing':
        if (isCurrentChat) {
          final bool nowTyping =
              data['content'] == 'true' || data['content'] == true;
          if (isPeerTyping != nowTyping) {
            isPeerTyping = nowTyping;
            notifyListeners();
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
        String dbTargetChatId = "";

        if (safeChatId.isNotEmpty) {
          if (isCurrentChatGroup) {
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

            final int inboxIndex = inbox.indexWhere((item) => item.id == dbTargetChatId);
            if (inboxIndex != -1) {
              inbox[inboxIndex].lastMessageIsRead = true;
              
              await db.update(
                'inbox', 
                {'last_message_is_read': 1}, 
                where: 'id = ?', 
                whereArgs: [dbTargetChatId],
              );
            }
            
          } catch (e) {
            debugPrint("Failed to update read receipts in DB: $e");
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
          (pending) => loadedMessages.any((loaded) => 
            loaded.id == pending.id || 
            loaded.content.trim() == pending.content.trim()),
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
              activeChat.first.id != mergedMessages.first.id;
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

    try {
      final response = await _api.getConversations();
      final rawData = _parseResponse(response.data, ['conversations']);

      List<InboxItem> combinedInbox = [];
      for (var json in rawData) {
        try {
          final bool isGroup =
              json['is_group'] == true || json['type'] == 'group';
          if (isGroup) {
            combinedInbox.add(InboxItem.fromGroup(Group.fromJson(json)));
            final String? groupId = json['id'];

            if (groupId != null && !_fetchedGroups.contains(groupId)) {
              _fetchedGroups.add(groupId);
              _api
                  .getGroupMembers(groupId)
                  .then((res) {
                    final members = _extractDataList(res.data, ['members']);
                    bool updatedCache = false;
                    for (var m in members) {
                      final uid = m['user_id'].toString();
                      if (userCache[uid] != (m['display_name'] ?? 'Member')) {
                        userCache[uid] = m['display_name'] ?? 'Member';
                        updatedCache = true;
                      }
                    }
                    if (updatedCache) notifyListeners();
                  })
                  .catchError((_) => _fetchedGroups.remove(groupId));
            }
          } else {
            combinedInbox.add(
              InboxItem.fromConversation(Conversation.fromJson(json)),
            );
          }
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

        if (currentChatUserId != null) {
          unawaited(syncActiveChatSilently());
        }

        try {
          final db = await DatabaseHelper.instance.database;
          Batch batch = db.batch();
          for (var item in inbox) {
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

      for (var missedChat in chatsToCatchUp) {
        if (missedChat.id != currentChatUserId) {
          unawaited(
            _backgroundSyncChatHistoryToDb(missedChat.id, missedChat.isGroup),
          );
        }
      }
    } catch (e) {
      debugPrint(
        "Network Inbox Read Error (Ignored because we have local cache): $e",
      );
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