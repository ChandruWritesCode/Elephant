import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

enum UserStatus { offline, online, typing }

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final UserStatus status;

  const GlassAppBar({super.key, required this.name, required this.status});

  String _getStatusText() {
    switch (status) {
      case UserStatus.typing:
        return "typing...";
      case UserStatus.online:
        return "Online";
      case UserStatus.offline:
        return "Offline";
    }
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
                      color: status == UserStatus.typing
                          ? Colors.green
                          : theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: status == UserStatus.typing
                          ? FontWeight.bold
                          : FontWeight.normal,
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
  final dynamic quotedMessage;

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
          maxWidth:
              MediaQuery.of(context).size.width *
              0.75, // Keeps a max width so it doesn't touch the edges
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
        // IntrinsicWidth forces the container to only be as wide as its widest child
        child: IntrinsicWidth(
          child: Column(
            // Stretch makes elements like the timestamp row expand to the intrinsic width boundary
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
                  child: Text(
                    quotedMessage.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isMe
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
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
  bool _showFormattingToolbar = false;
  final int _charLimit = 5000;
  bool _isOverLimit = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showFormattingToolbar = _focusNode.hasFocus;
      });
    });
  }

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

  void _insertMarkdown(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.start == selection.end) {
      final newText = text + prefix + suffix;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - suffix.length,
        ),
      );
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
    }
    _handleOnChange(_controller.text);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _showFormattingToolbar
                      ? Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _FormatButton(
                                icon: Icons.format_bold,
                                onPressed: () => _insertMarkdown('**', '**'),
                              ),
                              _FormatButton(
                                icon: Icons.format_italic,
                                onPressed: () => _insertMarkdown('*', '*'),
                              ),
                              _FormatButton(
                                icon: Icons.format_strikethrough,
                                onPressed: () => _insertMarkdown('~~', '~~'),
                              ),
                              _FormatButton(
                                icon: Icons.code,
                                onPressed: () => _insertMarkdown('`', '`'),
                              ),
                              _FormatButton(
                                icon: Icons.link,
                                onPressed: () => _insertMarkdown('[', '](url)'),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    IconButton(
                      icon: _isOverLimit
                          ? const Icon(Icons.not_interested)
                          : Icon(Icons.send, color: theme.colorScheme.primary),
                      onPressed: _isOverLimit ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _FormatButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: theme.iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
      ),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(),
    );
  }
}
