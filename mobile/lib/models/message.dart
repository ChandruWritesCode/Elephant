class QuotedMessage {
  final String id;
  final String senderId;
  final String senderDisplayName;
  final String content;

  QuotedMessage({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.content,
  });

  factory QuotedMessage.fromJson(Map<String, dynamic> json) {
    return QuotedMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderDisplayName:
          json['sender_display_name'] ?? json['sender_name'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'sender_display_name': senderDisplayName,
    'content': content,
  };
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToMessageId;
  final QuotedMessage? quotedMessage;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.replyToMessageId,
    this.quotedMessage,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['client_message_id'] ?? json['message_id'] ?? json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      replyToMessageId: json['reply_to_message_id'],
      quotedMessage: json['quoted_message'] != null
          ? QuotedMessage.fromJson(json['quoted_message'])
          : null,
    );
  }

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId,
      quotedMessage: quotedMessage,
    );
  }
}
