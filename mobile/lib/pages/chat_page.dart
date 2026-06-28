import 'package:flutter/material.dart';
import 'package:mob/widgets/chat_screen_modular_widgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // this class is only for message data
  final List<Map<String, dynamic>> messages = [
    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},

    {"text": "Hey! How's the app coming along?", "isMe": false},
    {"text": "Going great! Just building the UI now.", "isMe": true},
    {"text": "Love the glass morphic effect on the app bar!", "isMe": false},
  ];

  void _addNewMessage(String text) {
    setState(() {
      messages.add({"text": text, "isMe": true});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(name: 'Name', status: 'Activity Status'),
      body: ListView.builder(
        padding: const EdgeInsets.only(
          top: 120,
          bottom: 100,
          left: 16,
          right: 16,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return ChatBubble(message: msg['text'], isMe: msg['isMe']);
        },
      ),
      // Using the modularized Input Area
      bottomNavigationBar: ChatInputArea(onSendMessage: _addNewMessage),
    );
  }
}
