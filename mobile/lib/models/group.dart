class Group {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessageSender;
  final String lastMessage;
  final DateTime lastMessageAt; 

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.lastMessageSender,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    String content = 'No messages yet';

    DateTime msgTime = DateTime.now();
    if (json['last_message_time'] != null) {
      msgTime = DateTime.parse(json['last_message_time']).toLocal();
    } else if (json['created_at'] != null) {
      msgTime = DateTime.parse(json['created_at']);
    }

    final dynamic lastMsgData = json['last_message'];
    if (lastMsgData != null) {
      if (lastMsgData is Map) {
        content = lastMsgData['content'] ?? content;
      } else if (lastMsgData is String) {
        content = lastMsgData;
      }
    }

    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastMessageSender: json['sender_id'],
      lastMessage: content,
      lastMessageAt: msgTime,
    );
  }
}
