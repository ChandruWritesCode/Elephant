class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['message_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? json['timestamp'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };
 
  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}