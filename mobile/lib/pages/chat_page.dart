import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mob/widgets/chat_screen_modular_widgets.dart';
import 'package:mob/controllers/chat.dart';

class ChatPage extends StatefulWidget {
  final String chatUserId;
  final String displayName;

  const ChatPage({
    super.key,
    required this.chatUserId,
    required this.displayName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().closeChat();
      }
    });
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatController>().sendTextMessage(text);
  }

  String _getPresenceStatusText(ChatController state) {
    if (state.isPeerTyping) return 'typing...';
    return state.isPeerOnline ? 'Online' : 'Offline';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        name: widget.displayName,
        status: _getPresenceStatusText(chatState), 
      ),
      body: chatState.activeChat.isEmpty
          ? const Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: 120,
                bottom: 100,
                left: 16,
                right: 16,
              ),
              itemCount: chatState.activeChat.length,
              itemBuilder: (context, index) {
                final msg = chatState.activeChat[index];
                
                final String cleanSenderId = msg.senderId.trim().toLowerCase();
                final String cleanPeerId = widget.chatUserId.trim().toLowerCase();
                
                final bool isMe = cleanSenderId == 'me' || (cleanSenderId.isNotEmpty && cleanSenderId != cleanPeerId);

                return ChatBubble(
                  message: msg.content,
                  isMe: isMe,
                  timestamp: msg.createdAt,
                  isRead: msg.isRead,
                );
              },
            ),
      bottomNavigationBar: ChatInputArea(
        onSendMessage: _sendMessage,
        onTypingChanged: (isTyping) => context.read<ChatController>().sendTypingNotification(isTyping),
      ),
    );
  }
}