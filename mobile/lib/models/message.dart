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
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderDisplayName: json['sender_display_name']?.toString() ?? 
                         json['sender_name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
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
  final String syncStatus;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.replyToMessageId,
    this.quotedMessage,
    this.syncStatus = 'synced',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    
    var dateData = json['created_at'] ?? json['timestamp']; 

    if (dateData != null) {
      if (dateData is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(dateData);
      } else {
        String dateString = dateData.toString();
        if (dateString.startsWith('0001-01-01')) {
          parsedDate = DateTime.now(); 
        } else {
          try {
            parsedDate = DateTime.parse(dateString).toLocal();
          } catch (e) {
            parsedDate = DateTime.now();
          }
        }
      }
    }

    return Message(
      id: json['client_message_id']?.toString() ?? 
          json['message_id']?.toString() ?? 
          json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: parsedDate,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      replyToMessageId: json['reply_to_message_id']?.toString(),
      quotedMessage: json['quoted_message'] != null
          ? QuotedMessage.fromJson(json['quoted_message'])
          : null,
      syncStatus: json['sync_status']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'reply_to_id': replyToMessageId,
      'sync_status': syncStatus,
    };
  }

  Message copyWith({
    bool? isRead,
    String? id,
    String? syncStatus,
    String? content,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId,
      receiverId: receiverId,
      content: content ?? this.content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId,
      quotedMessage: quotedMessage,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}