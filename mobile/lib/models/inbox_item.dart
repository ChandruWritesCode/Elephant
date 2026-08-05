import 'package:mobile/models/conversation.dart';
import 'package:mobile/models/group.dart';

class InboxItem {
  final String id;
  final String title;
  final String? username;
  String lastMessage;
  DateTime timestamp;
  final bool isGroup;
  final bool isRead;
  int unreadCount;
  String? lastMessageSender;
  String? lastMessageSyncStatus;
  bool? lastMessageIsRead;

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
    this.lastMessageIsRead,
    this.lastMessageSyncStatus,
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
    String? lastMessageSender,
    String? lastMessageSyncStatus,
    bool? lastMessageIsRead,
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
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageSyncStatus: lastMessageSyncStatus ?? this.lastMessageSyncStatus,
      lastMessageIsRead: lastMessageIsRead ?? this.lastMessageIsRead,
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
      lastMessageSender: conv.lastMessageSenderId, 
      lastMessageSyncStatus: 'synced',
      lastMessageIsRead: conv.isRead, 
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
      lastMessageSyncStatus: 'synced',
      lastMessageIsRead: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'last_message': lastMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_group': isGroup ? 1 : 0,
      'is_read': isRead ? 1 : 0,
      'unread_count': unreadCount,
      'last_message_sender': lastMessageSender,
      'last_message_sync_status': lastMessageSyncStatus ?? 'synced',
      'last_message_is_read': (lastMessageIsRead ?? false) ? 1 : 0,
    };
  }

  factory InboxItem.fromMap(Map<String, dynamic> map) {
    return InboxItem(
      id: map['id'] as String,
      title: map['title'] as String,
      username: map['username'] as String?,
      lastMessage: map['last_message'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isGroup: (map['is_group'] as int) == 1,
      isRead: (map['is_read'] as int) == 1,
      unreadCount: (map['unread_count'] as int?) ?? 0,
      lastMessageSender: map['last_message_sender'] as String?,
      lastMessageSyncStatus: map['last_message_sync_status'] as String? ?? 'synced',
      lastMessageIsRead: map['last_message_is_read'] != null 
          ? (map['last_message_is_read'] as int) == 1 
          : false,
    );
  }
}