import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/services/chat/chat_event_handler.dart';
import 'package:mobile/services/chat/chat_sync_service.dart';
import '../../services/ws_service.dart';
import '../../services/auth_service.dart';

class ChatConnectionController extends ChangeNotifier
    with WidgetsBindingObserver {
  final WebSocketService _ws = WebSocketService();
  final AuthService _auth = AuthService();
  final ChatSyncService _syncService = ChatSyncService();
  final ChatEventHandler eventHandler;

  bool isOffline = false;
  bool _isWsConnecting = false;
  Timer? _reconnectTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _wsSubscription;

  ChatConnectionController({required this.eventHandler}) {
    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final bool currentlyOffline = result.contains(ConnectivityResult.none);

      if (isOffline != currentlyOffline) {
        isOffline = currentlyOffline;
        notifyListeners();

        if (!isOffline) {
          connectWebSocket();
          eventHandler.inboxController
              .loadInbox();
        } else {
          eventHandler.activeChatController.isPeerOnline = false;
          eventHandler.activeChatController.isPeerTyping = false;
          eventHandler.activeChatController.refreshUI();

          _ws.disconnect();
        }
      }
    });
  }

  Future<void> connectWebSocket() async {
    if (_ws.isConnected || _isWsConnecting) return;
    _isWsConnecting = true;

    try {
      _reconnectTimer?.cancel();

      final token = await _auth.getToken();
      if (token == null) {
        _isWsConnecting = false;
        return;
      }

      await _wsSubscription?.cancel();
      _ws.disconnect();

      final connected = await _ws.connect(token);
      if (!connected) {
        _triggerReconnectLoop();
        return;
      }

      _syncService.processOfflineQueue(eventHandler.currentUserId);

      final currentChatId = eventHandler.activeChatController.currentChatUserId;
      if (currentChatId != null &&
          !eventHandler.activeChatController.isCurrentChatGroup) {
        _ws.sendRequestStatus(targetId: currentChatId);
      }

      _wsSubscription = _ws.stream?.listen(
        (rawFrame) {
          try {
            debugPrint("📥 WS Received: $rawFrame");
            final decoded = jsonDecode(rawFrame);
            if (decoded is Map<String, dynamic>) {
              eventHandler.handleIncomingEvent(decoded);
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
    _isWsConnecting = false;

    if (eventHandler.activeChatController.isPeerOnline) {
      eventHandler.activeChatController.isPeerOnline = false;
      eventHandler.activeChatController.refreshUI();
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!isOffline) {
        connectWebSocket();
      }
    });
  }

  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _ws.disconnect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      connectWebSocket();
      _syncService.processOfflineQueue(
        eventHandler.currentUserId,
      );
      eventHandler.inboxController
          .loadInbox();
    } else if (state == AppLifecycleState.paused) {
      _reconnectTimer?.cancel();
      _ws.disconnect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _wsSubscription?.cancel();
    _reconnectTimer?.cancel();
    _ws.disconnect();
    super.dispose();
  }
}
