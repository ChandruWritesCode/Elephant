import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_rich_text/simple_rich_text.dart';
// Make sure to import your new unified model here!
import '../models/inbox_item.dart';
import '../pages/chat_page.dart';
import '../controllers/chat.dart';

class CustomChatCard extends StatelessWidget {
  final InboxItem conversation; // Changed from Conversation to InboxItem
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

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Changed lastMessageTime to timestamp (from InboxItem model)
    final String timeLabel = _formatTimestamp(conversation.timestamp);
    final bool hasUnread = conversation.unreadCount > 0;

    return Material(
      color: isSelected
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: () async {
          if (isSelectionMode) {
            onTapInSelection();
          } else {
            final controller = context.read<ChatController>();
            print(
              "Tapping on conversation. Target ID is: '${conversation.id}'",
            );
            // Changed chatUserId to id
            controller.openChat(conversation.id);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    // You might need to update ChatPage to accept a generic 'chatId' and 'isGroup' boolean eventually
                    chatUserId: conversation.id,
                    displayName:
                        conversation.title, // Changed displayName to title
                  ),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFD6E4FF),
                      // Dynamically change icon based on isGroup
                      child: Icon(
                        conversation.isGroup ? Icons.group : Icons.person,
                        color: const Color(0xFF1890FF),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title, // Changed displayName to title
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SimpleRichText(
                      conversation.lastMessage.replaceAll('\n', ' '),
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread ? Colors.black87 : Colors.black54,
                        fontSize: 15,
                      ),
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
                    style: TextStyle(
                      color: hasUnread
                          ? const Color(0xFF1890FF)
                          : Colors.black38,
                      fontSize: 12,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasUnread)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1890FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        conversation.unreadCount > 99
                            ? "99+"
                            : "${conversation.unreadCount}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
}
