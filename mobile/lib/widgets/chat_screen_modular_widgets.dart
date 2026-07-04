import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; 

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String status;

  const GlassAppBar({super.key, required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.4),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD6E4FF),
                child: Icon(Icons.person, color: Color(0xFF1890FF)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: status == "typing..."
                          ? Colors.green
                          : Colors.black54,
                      fontSize: 12,
                      fontWeight: status == "typing..."
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

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedTime =
        "${timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1890FF) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: message,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                strong: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                em: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
                del: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  decoration: TextDecoration.lineThrough,
                ),
                code: TextStyle(
                  backgroundColor: isMe ? Colors.blue[800] : Colors.grey[300],
                  color: isMe ? Colors.blue[50] : Colors.red[800],
                  fontFamily: 'monospace',
                ),
                a: TextStyle(
                  color: isMe ? Colors.blue[100] : Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
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

  final int _charLimit = 5000; // limit
  bool _isOverLimit = false;

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
    return SafeArea(
      top: false,
      bottom: false,
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
                        maxLengthEnforcement: .none,
                        style: TextStyle(
                          color: _isOverLimit ? Colors.red : Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Write a message...",
                          hintStyle: const TextStyle(color: Colors.black38),
                          fillColor: _isOverLimit
                              ? Colors.red.withValues(alpha: 0.1)
                              : const Color(0xFFF5F5F5),
                          filled: true,
                          errorText: _isOverLimit
                              ? 'character limit exceeded'
                              : null,
                          counterStyle: TextStyle(
                            color: _isOverLimit ? Colors.red : Colors.black54,
                            fontWeight: _isOverLimit
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: _isOverLimit
                                ? const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: _isOverLimit
                                ? const BorderSide(color: Colors.red, width: 2)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: _isOverLimit
                                ? const BorderSide(
                                    color: Colors.red,
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
                          : const Icon(Icons.send, color: Color(0xFF1890FF)),
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
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.black54),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(),
    );
  }
}
