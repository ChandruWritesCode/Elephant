class Conversation {
  final String chatUserId;
  final String username;
  final String displayName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String senderId;
  final bool isRead;
  final int unreadCount;

  Conversation({
    required this.chatUserId,
    required this.username,
    required this.displayName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.senderId,
    required this.isRead,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      chatUserId: json['chat_user_id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time'] ?? DateTime.now().toIso8601String()).toLocal(),
      senderId: json['sender_id'] ?? '',
      isRead: json['is_read'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}