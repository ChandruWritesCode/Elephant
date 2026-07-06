import 'package:mobile/models/conversation.dart';
import 'package:mobile/models/group.dart';

class InboxItem {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final bool isGroup;
  final bool isRead;
  final int unreadCount;

  InboxItem({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.isGroup,
    this.isRead = true,
    this.unreadCount = 0,
  });

  factory InboxItem.fromConversation(Conversation conv) {
    return InboxItem(
      id: conv.chatUserId,
      title: conv.username,
      lastMessage: conv.lastMessage,
      timestamp: conv.lastMessageTime,
      isGroup: false,
      isRead: conv.isRead,
      unreadCount: conv.unreadCount,
    );
  }

  factory InboxItem.fromGroup(Group group) {
    return InboxItem(
      id: group.id,
      title: group.name,
      lastMessage: 'Tap to view group',
      timestamp: group.createdAt,
      isGroup: true,
      isRead: true,
      unreadCount: 0,
    );
  }
}
