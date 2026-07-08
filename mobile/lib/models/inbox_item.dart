import 'package:mobile/models/conversation.dart';
import 'package:mobile/models/group.dart';

class InboxItem {
  final String id;
  final String title;
  final String? username;
  final String lastMessage;
  final DateTime timestamp;
  final bool isGroup;
  final bool isRead;
  final int unreadCount;
  final String? lastMessageSender;

  InboxItem({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.isGroup,
    this.isRead = true,
    this.unreadCount = 0,
    this.username,
    this.lastMessageSender,
  });

  InboxItem copyWith({
    String? id,
    String? title,
    String? lastMessage,
    String? username,
    DateTime? timestamp,
    bool? isGroup,
    bool? isRead,
    int? unreadCount,
  }) {
    return InboxItem(
      id: id ?? this.id,
      username: username ?? this.username,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      isGroup: isGroup ?? this.isGroup,
      isRead: isRead ?? this.isRead,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory InboxItem.fromConversation(Conversation conv) {
    return InboxItem(
      id: conv.chatUserId,
      username: conv.username,
      title: conv.displayName,
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
      timestamp: group.lastMessageAt,
      isGroup: true,
      isRead: true,
      unreadCount: 0,
      lastMessageSender: group.lastMessageSender,
      lastMessage: group.lastMessage,
    );
  }
}
