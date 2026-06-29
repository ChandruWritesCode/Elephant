class WSMessage {
  final String type;
  final String senderId;
  final String receiverId;
  final String groupId;
  final String content;
  final String messageId;
  final DateTime? timestamp;

  WSMessage({
    required this.type,
    this.senderId = '',
    this.receiverId = '',
    this.groupId = '',
    this.content = '',
    this.messageId = '',
    this.timestamp,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: json['type'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      groupId: json['group_id'] ?? '',
      content: json['content'] ?? '',
      messageId: json['message_id'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (senderId.isNotEmpty) 'sender_id': senderId,
    if (receiverId.isNotEmpty) 'receiver_id': receiverId,
    if (groupId.isNotEmpty) 'group_id': groupId,
    if (content.isNotEmpty) 'content': content,
    if (messageId.isNotEmpty) 'message_id': messageId,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };
}