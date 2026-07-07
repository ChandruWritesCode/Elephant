import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/message.dart';
import 'package:provider/provider.dart';
import 'package:mobile/controllers/chat.dart';

enum UserStatus { offline, online }

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final UserStatus status;

  const GlassAppBar({super.key, required this.name, required this.status});

  String _getStatusText() {
    return status == UserStatus.online ? "Online" : "Offline";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.textTheme.titleLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final QuotedMessage? quotedMessage;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.isRead,
    this.quotedMessage,
  });

  MarkdownStyleSheet _getMarkdownStyle(
    bool isMe,
    Color primaryColor,
    Color onPrimary,
    Color onSurface,
  ) {
    return MarkdownStyleSheet(
      p: TextStyle(color: isMe ? onPrimary : onSurface, fontSize: 15),
      strong: TextStyle(
        color: isMe ? onPrimary : onSurface,
        fontWeight: FontWeight.bold,
      ),
      em: TextStyle(
        color: isMe ? onPrimary : onSurface,
        fontStyle: FontStyle.italic,
      ),
      del: TextStyle(
        color: isMe
            ? onPrimary.withValues(alpha: 0.7)
            : onSurface.withValues(alpha: 0.5),
        decoration: TextDecoration.lineThrough,
      ),
      code: TextStyle(
        backgroundColor: isMe
            ? primaryColor.withValues(alpha: 0.8)
            : Colors.grey.withValues(alpha: 0.3),
        color: isMe ? onPrimary : Colors.red[800],
        fontFamily: 'monospace',
      ),
      a: TextStyle(
        color: isMe ? onPrimary.withValues(alpha: 0.9) : primaryColor,
        decoration: TextDecoration.underline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String formattedTime = DateFormat.jm().format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quotedMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.15,
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quotedMessage!.senderDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quotedMessage!.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isMe
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.8,
                                )
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              MarkdownBody(
                data: message,
                selectable: false,
                styleSheet: _getMarkdownStyle(
                  isMe,
                  theme.colorScheme.primary,
                  theme.colorScheme.onPrimary,
                  theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        color: isMe
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? Colors.lightBlueAccent
                            : theme.colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatInputArea extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool)? onTypingChanged;

  const ChatInputArea({
    super.key,
    required this.onSendMessage,
    this.onTypingChanged,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  Timer? _typingTimer;
  final int _charLimit = 5000;
  bool _isOverLimit = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      widget.onTypingChanged?.call(false);
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleOnChange(String text) {
    setState(() {
      _isOverLimit = text.length > _charLimit;
    });

    final hasText = text.trim().isNotEmpty;

    if (hasText && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      widget.onTypingChanged?.call(true);
    }

    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _isTyping) {
          setState(() {
            _isTyping = false;
          });
          widget.onTypingChanged?.call(false);
        }
      });
    } else if (_isTyping) {
      setState(() {
        _isTyping = false;
      });
      widget.onTypingChanged?.call(false);
    }
  }

  void _submit() {
    _isOverLimit = false;
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _typingTimer?.cancel();
      widget.onSendMessage(text);
      _controller.clear();
      if (_isTyping) {
        setState(() {
          _isTyping = false;
        });
        widget.onTypingChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      bottom: true,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _handleOnChange,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: _charLimit,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    style: TextStyle(
                      color: _isOverLimit
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => _isOverLimit
                        ? Text('$currentLength/$maxLength')
                        : null,
                    decoration: InputDecoration(
                      hintText: "Write a message...",
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      fillColor: _isOverLimit
                          ? theme.colorScheme.error.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      filled: true,
                      errorText: _isOverLimit
                          ? 'character limit exceeded'
                          : null,
                      counterStyle: TextStyle(
                        color: _isOverLimit
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: _isOverLimit
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: _isOverLimit
                            ? BorderSide(
                                color: theme.colorScheme.error,
                                width: 1.5,
                              )
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: _isOverLimit
                            ? BorderSide(
                                color: theme.colorScheme.error,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: _isOverLimit
                            ? BorderSide(
                                color: theme.colorScheme.error,
                                width: 1.5,
                              )
                            : BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: IconButton(
                    icon: _isOverLimit
                        ? const Icon(Icons.not_interested)
                        : Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _isOverLimit ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().openChat(widget.chatUserId);
      }
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

    final offset = _scrollController.offset;
    _isNearBottom = offset <= 300;
    final isScrolledUp = offset > 300;

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
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatController>().sendTextMessage(
      text,
      replyingTo: _replyingToMessage,
    );

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

    if (activeChat.length != _previousMessageCount) {
      final isNewMessage = activeChat.length > _previousMessageCount;
      _previousMessageCount = activeChat.length;

      if (isNewMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom(animated: true);
        });
      }
    }

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _selectedIndices.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
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
            if (chatState.isChatHistoryLoading && activeChat.isEmpty)
              Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            else if (activeChat.isEmpty)
              Center(
                child: Text(
                  "No messages yet.\nSay hi!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ListView.builder(
                key: const ValueKey('list'),
                controller: _scrollController,
                reverse: true,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(
                  bottom: 140,
                  top: 140,
                  left: 16,
                  right: 16,
                ),
                itemCount: activeChat.length + (chatState.isPeerTyping ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        height: _replyingToMessage != null ? 80 : 0,
                      ),
                    );
                  }

                  if (chatState.isPeerTyping && index == 1) {
                    return _AnimatedMessageItem(
                      key: const ValueKey('typing_indicator'),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8, top: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              16,
                            ).copyWith(bottomLeft: const Radius.circular(4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "typing...",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final int msgIndex = index - (chatState.isPeerTyping ? 2 : 1);
                  final int realIndex = activeChat.length - 1 - msgIndex;
                  final msg = activeChat[realIndex];
                  final bool isSelected = _selectedIndices.contains(realIndex);

                  bool showDateSeparator = false;
                  if (realIndex == 0) {
                    showDateSeparator = true;
                  } else {
                    final prevMsg = activeChat[realIndex - 1];
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

                  QuotedMessage? displayQuote = msg.quotedMessage;

                  if (msg.replyToMessageId != null &&
                      msg.replyToMessageId!.isNotEmpty) {
                    if (displayQuote == null ||
                        displayQuote.senderDisplayName.isEmpty) {
                      Message? parentMsg;
                      try {
                        parentMsg = activeChat.firstWhere(
                          (m) => m.id == msg.replyToMessageId,
                        );
                      } catch (_) {}

                      if (parentMsg != null) {
                        final String pSenderId = parentMsg.senderId
                            .trim()
                            .toLowerCase();
                        displayQuote = QuotedMessage(
                          id: parentMsg.id,
                          senderId: pSenderId,
                          senderDisplayName:
                              (pSenderId == 'me' ||
                                  (pSenderId.isNotEmpty &&
                                      pSenderId != cleanPeerId))
                              ? "You"
                              : widget.displayName,
                          content: parentMsg.content,
                        );
                      }
                    }
                  }

                  final String? targetReplyId =
                      msg.replyToMessageId ?? displayQuote?.id;

                  if (targetReplyId != null && targetReplyId.isNotEmpty) {
                    Message? parentMsg;
                    try {
                      parentMsg = activeChat.firstWhere(
                        (m) => m.id == targetReplyId,
                      );
                    } catch (_) {}

                    final String pSenderId =
                        (parentMsg?.senderId ?? displayQuote?.senderId ?? '')
                            .trim()
                            .toLowerCase();

                    String calculatedName =
                        displayQuote?.senderDisplayName ?? '';
                    if (calculatedName.trim().isEmpty ||
                        calculatedName == 'Unknown' ||
                        calculatedName == 'null') {
                      calculatedName = "Previous Message";
                    }

                    if (pSenderId.isNotEmpty) {
                      if (pSenderId == 'me' ||
                          (pSenderId != cleanPeerId &&
                              pSenderId !=
                                  widget.chatUserId.trim().toLowerCase())) {
                        calculatedName = "You";
                      } else {
                        calculatedName = widget.displayName;
                      }
                    }

                    displayQuote = QuotedMessage(
                      id: targetReplyId,
                      senderId: pSenderId,
                      senderDisplayName: calculatedName,
                      content:
                          displayQuote?.content ??
                          parentMsg?.content ??
                          'Message not loaded',
                    );
                  }

                  return _AnimatedMessageItem(
                    key: ValueKey(
                      msg.id?.toString() ??
                          msg.createdAt.millisecondsSinceEpoch.toString(),
                    ),
                    child: Column(
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
                          onLongPress: () {
                            HapticFeedback.selectionClick();
                            _toggleSelection(realIndex);
                          },
                          onTap: () {
                            if (isSelectionMode) {
                              _toggleSelection(realIndex);
                            }
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SwipeToReply(
                                isMe: isMe,
                                onReply: () {
                                  setState(() {
                                    _replyingToMessage = msg;
                                  });
                                },
                                child: ChatBubble(
                                  message: msg.content,
                                  isMe: isMe,
                                  timestamp: msg.createdAt,
                                  isRead: msg.isRead,
                                  quotedMessage: displayQuote,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
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
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _replyingToMessage != null ? 1.0 : 0.0,
                      child: _replyingToMessage != null
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 4,
                                  ),
                                  top: BorderSide(
                                    color: theme.dividerColor,
                                    width: 1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Replying to ${_replyingToMessage != null && (_replyingToMessage.senderId.trim().toLowerCase() == 'me' || _replyingToMessage.senderId.trim().toLowerCase() != widget.chatUserId.trim().toLowerCase()) ? 'You' : widget.displayName}",
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
                                    onPressed: () => setState(
                                      () => _replyingToMessage = null,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
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

class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;

  const _AnimatedMessageItem({super.key, required this.child});

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _vibrated = false;
  final double _replyThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;

      if (widget.isMe) {
        if (_dragOffset > 0) _dragOffset = 0;
        if (_dragOffset < -_replyThreshold) {
          _dragOffset =
              -_replyThreshold + ((_dragOffset + _replyThreshold) * 0.15);
        }
      } else {
        if (_dragOffset < 0) _dragOffset = 0;
        if (_dragOffset > _replyThreshold) {
          _dragOffset =
              _replyThreshold + ((_dragOffset - _replyThreshold) * 0.15);
        }
      }

      if (_dragOffset.abs() >= _replyThreshold && !_vibrated) {
        HapticFeedback.lightImpact();
        _vibrated = true;
      } else if (_dragOffset.abs() < _replyThreshold) {
        _vibrated = false;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _replyThreshold) {
      widget.onReply();
    }
    _vibrated = false;

    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final double iconOpacity = (_dragOffset.abs() / _replyThreshold).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: widget.isMe ? null : 20,
            right: widget.isMe ? 20 : null,
            child: Opacity(
              opacity: iconOpacity,
              child: Transform.scale(
                scale: 0.5 + (0.5 * iconOpacity),
                child: Icon(
                  Icons.reply,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
