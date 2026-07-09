import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/message.dart';

enum UserStatus { offline, online }

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final UserStatus? status;
  final bool isGroup;
  final GestureTapCallback? onTitleTap;

  const GlassAppBar({
    super.key,
    required this.name,
    required this.status,
    required this.isGroup,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: GestureDetector(
            onTap: onTitleTap,
            child: Row(
              children: [
                Hero(
                  tag: 'profile',
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
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
                    status != null
                        ? Text(
                            status! == UserStatus.online ? "Online" : "Offline",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ChatBubble extends StatelessWidget {
  final VoidCallback? onQuoteTap;
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final QuotedMessage? quotedMessage;
  final String? senderName;
  final bool isGroup;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.isRead,
    this.quotedMessage,
    this.senderName,
    this.isGroup = false,
    this.onQuoteTap,
  });

  Color _getSenderColor(String name) {
    final hash = name.hashCode;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[hash % colors.length];
  }

  MarkdownStyleSheet _getMarkdownStyle(
    bool isMe,
    Color primaryColor,
    Color onPrimary,
    Color onSurface,
    BuildContext context,
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
        color: isMe ? onPrimary : Theme.of(context).colorScheme.error,
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
              if (isGroup && !isMe && senderName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getSenderColor(senderName!),
                    ),
                  ),
                ),
              if (quotedMessage != null)
                GestureDetector(
                  onTap: onQuoteTap,
                  child: Container(
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
                ),
              MarkdownBody(
                data: message,
                selectable: false,
                styleSheet: _getMarkdownStyle(
                  isMe,
                  theme.colorScheme.primary,
                  theme.colorScheme.onPrimary,
                  theme.colorScheme.onSurface,
                  context,
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
                            ? (isMe
                                  ? Colors.lightBlueAccent
                                  : theme.colorScheme.primary)
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 12.0,
            right: 12.0,
            top: 20,
            bottom: 20 + bottomPadding,
          ),
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
                    errorText: _isOverLimit ? 'character limit exceeded' : null,
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
                          ? BorderSide(color: theme.colorScheme.error, width: 2)
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
                      ? Icon(
                          Icons.not_interested,
                          color: theme.colorScheme.error,
                        )
                      : Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _isOverLimit ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
