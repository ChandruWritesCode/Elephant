import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:provider/provider.dart';
import 'package:simple_rich_text/simple_rich_text.dart';
import '../models/inbox_item.dart';
import '../pages/chat_page.dart';

class CustomChatCard extends StatelessWidget {
  final InboxItem conversation;
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
    final String timeLabel = _formatTimestamp(conversation.timestamp);
    final bool hasUnread = conversation.unreadCount > 0;
    final chatState = context.watch<ChatController>();

    final currentUserId = context.read<AuthState>().currentUser?.id;

    String? senderName;
    if (conversation.isGroup && conversation.lastMessageSender != null) {
      if (conversation.lastMessageSender == currentUserId) {
        senderName = "You";
      } else {
        senderName =
            chatState.userCache[conversation.lastMessageSender!] ?? "Member";
      }
    }

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: () async {
          if (isSelectionMode) {
            onTapInSelection();
          } else {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatUserId: conversation.id,
                    displayName: conversation.title,
                    isGroup: conversation.isGroup,
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        conversation.isGroup ? Icons.group : Icons.person,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
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
                      conversation.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SimpleRichText(
                      senderName != null
                          ? "*$senderName:* ${conversation.lastMessage.replaceAll('\n', ' ')}"
                          : conversation.lastMessage.replaceAll('\n', ' '),
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        conversation.unreadCount > 99
                            ? "99+"
                            : "${conversation.unreadCount}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
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
