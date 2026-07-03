import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../pages/chat_page.dart';
import '../controllers/chat.dart';

class CustomChatCard extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final bool isSelectionMode;
  final GestureLongPressCallback? onLongPress;
  final Function onTapInSelection;

  const CustomChatCard({
    super.key,
    required this.conversation,
    required this.isSelected,
    this.onLongPress,
    required this.onTapInSelection,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final String timeLabel =
        "${conversation.lastMessageTime.hour.toString().padLeft(2, '0')}:${conversation.lastMessageTime.minute.toString().padLeft(2, '0')}";

    return InkWell(
      onLongPress: onLongPress,

      onTap: () async {
        if (isSelectionMode) {
          onTapInSelection();
        } else {
          final controller = context.read<ChatController>();
          await controller.openChat(conversation.chatUserId);

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatUserId: conversation.chatUserId,
                  displayName: conversation.displayName,
                ),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected? Colors.blue.withAlpha(20) : null,
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFD6E4FF),
                    child: Icon(Icons.person, color: Color(0xFF1890FF)),
                  ),
                  isSelected
                      ? Align(
                          alignment: AlignmentGeometry.bottomRight,
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1890FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${conversation.unreadCount}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
