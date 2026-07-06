class QuotedMessage {
  final String id;
  final String senderId;
  final String content;

  QuotedMessage({
    required this.id,
    required this.senderId,
    required this.content,
  });

  factory QuotedMessage.fromJson(Map<String, dynamic> json) {
    return QuotedMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
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
      id: json['id'] ?? json['message_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['timestamp'] ??
            DateTime.now().toIso8601String(),
      ).toLocal(),
      isRead: json['is_read'] ?? false,
      replyToMessageId: json['reply_to_message_id'],
      quotedMessage: json['quoted_message'] != null
          ? QuotedMessage.fromJson(json['quoted_message'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };

    if (replyToMessageId != null) map['reply_to_message_id'] = replyToMessageId;
    if (quotedMessage != null) map['quoted_message'] = quotedMessage!.toJson();

    return map;
  }

  Message copyWith({
    bool? isRead,
    String? replyToMessageId,
    QuotedMessage? quotedMessage,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      quotedMessage: quotedMessage ?? this.quotedMessage,
    );
  }
}
