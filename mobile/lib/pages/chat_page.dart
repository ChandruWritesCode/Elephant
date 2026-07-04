import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/chat_screen_modular_widgets.dart';
import 'package:mobile/controllers/chat.dart';

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

  bool _showScrollToBottom = false;

  final Set<int> _selectedIndices = {};

  dynamic _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().closeChat();
      }
    });
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final isScrolledUp =
        _scrollController.position.maxScrollExtent - _scrollController.offset >
        100;
    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatController>().sendTextMessage(text);

    setState(() {
      _replyingToMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _copySelectedMessages(List<dynamic> activeChat) {
    final sortedIndices = _selectedIndices.toList()..sort();

    final selectedTexts = sortedIndices
        .map((index) => activeChat[index].content.toString())
        .join('\n');

    Clipboard.setData(ClipboardData(text: selectedTexts));

    _clearSelection();
  }

  String _getPresenceStatusText(ChatController state) {
    if (state.isPeerTyping) return 'typing...';
    return state.isPeerOnline ? 'Online' : 'Offline';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();
    final activeChat = chatState.activeChat;
    final isSelectionMode = _selectedIndices.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,

      appBar: isSelectionMode
          ? AppBar(
              backgroundColor: Colors.blueAccent,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearSelection,
              ),
              title: Text(
                '${_selectedIndices.length} Selected',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () => _copySelectedMessages(activeChat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    // TODO delete on DB
                    _clearSelection();
                  },
                ),
              ],
            )
          : GlassAppBar(
                  name: widget.displayName,
                  status: _getPresenceStatusText(chatState),
                )
                as PreferredSizeWidget,

      body: Stack(
        children: [
          activeChat.isEmpty
              ? const Center(
                  child: Text(
                    "No messages yet",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: 120,
                    bottom: _replyingToMessage != null ? 180 : 120,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: activeChat.length,
                  itemBuilder: (context, index) {
                    final msg = activeChat[index];
                    final bool isSelected = _selectedIndices.contains(index);

                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMsg = activeChat[index - 1];
                      if (!_isSameDay(msg.createdAt, prevMsg.createdAt)) {
                        showDateSeparator = true;
                      }
                    }

                    final String cleanSenderId = msg.senderId
                        .trim()
                        .toLowerCase();
                    final String cleanPeerId = widget.chatUserId
                        .trim()
                        .toLowerCase();
                    final bool isMe =
                        cleanSenderId == 'me' ||
                        (cleanSenderId.isNotEmpty &&
                            cleanSenderId != cleanPeerId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDateSeparator(msg.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),

                        GestureDetector(
                          onLongPress: () => _toggleSelection(index),
                          onTap: () {
                            if (isSelectionMode) _toggleSelection(index);
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.transparent,
                            child: Dismissible(
                              key: ValueKey(
                                msg.createdAt.toString() + index.toString(),
                              ),
                              direction: DismissDirection.startToEnd,
                              confirmDismiss: (direction) async {
                                setState(() {
                                  _replyingToMessage = msg;
                                });
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 16),
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.reply,
                                  color: Colors.grey,
                                ),
                              ),
                              child: ChatBubble(
                                message: msg.content,
                                isMe: isMe,
                                timestamp: msg.createdAt,
                                isRead: msg.isRead,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: _replyingToMessage != null ? 140 : 90,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _scrollToBottom,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: const Border(
                        left: BorderSide(color: Colors.blue, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Replying to message",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _replyingToMessage.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              setState(() => _replyingToMessage = null),
                        ),
                      ],
                    ),
                  ),
                ChatInputArea(
                  onSendMessage: _sendMessage,
                  onTypingChanged: (isTyping) => context
                      .read<ChatController>()
                      .sendTypingNotification(isTyping),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
