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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isNearBottom = true;
  final Set<int> _selectedIndices = {};
  dynamic _replyingToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().closeChat();
      }
    });
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom(animated: true);
        }
      });
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;

    _isNearBottom = maxScrollExtent - offset <= 100;

    final isScrolledUp = maxScrollExtent - offset > 100;

    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatController>().sendTextMessage(text);

    setState(() {
      _replyingToMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));

    _clearSelection();
  }

  UserStatus _getPresenceStatusText(ChatController state) {
    if (state.isPeerTyping) return UserStatus.typing;
    return state.isPeerOnline ? UserStatus.online : UserStatus.offline;
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
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        setState(() {
          _selectedIndices.clear();
        });
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isSelectionMode
                ? AppBar(
                    key: const ValueKey('SelectionAppBar'),
                    backgroundColor: theme.colorScheme.primary,
                    leading: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _clearSelection,
                    ),
                    title: Text(
                      '${_selectedIndices.length} Selected',
                      style: TextStyle(color: theme.colorScheme.onPrimary),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () => _copySelectedMessages(activeChat),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          _clearSelection();
                        },
                      ),
                    ],
                  )
                : GlassAppBar(
                    key: const ValueKey('GlassAppBar'),
                    name: widget.displayName,
                    status: _getPresenceStatusText(chatState),
                  ),
          ),
        ),
        body: Stack(
          children: [
            activeChat.isEmpty
                ? Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      top: 120,
                      bottom: _replyingToMessage != null ? 220 : 140,
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
                                margin: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDateSeparator(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
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
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    )
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
                                  child: Icon(
                                    Icons.reply,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
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
            Positioned(
              right: 16,
              bottom: _replyingToMessage != null ? 180 : 100,
              child: AnimatedScale(
                scale: _showScrollToBottom ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _showScrollToBottom ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 4,
                    onPressed: () => _scrollToBottom(animated: true),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
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
                        color: theme.colorScheme.surface,
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                          top: BorderSide(color: theme.dividerColor, width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Replying to message",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _replyingToMessage.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: theme.iconTheme.color,
                            ),
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
      ),
    );
  }
}
