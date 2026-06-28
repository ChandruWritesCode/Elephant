import 'dart:ui';

import 'package:flutter/material.dart';


// App bar for chat screen only
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String status;

  const GlassAppBar({super.key, required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          enabled: true,
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: const Color.fromARGB(78, 255, 255, 255)),
        ),
      ),
      title: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 20)),
              Text(status, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
      ],
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// chat area

class ChatInputArea extends StatefulWidget {
  final ValueChanged<String> onSendMessage;

  const ChatInputArea({super.key, required this.onSendMessage});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    widget.onSendMessage(_controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        enabled: true,
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          width: double.infinity,
          color: const Color.fromARGB(78, 255, 255, 255),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Write a message...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _handleSend,
                icon: const Icon(Icons.send, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
