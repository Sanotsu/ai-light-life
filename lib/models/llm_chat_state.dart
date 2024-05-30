/// 人机对话的每一条消息的结果
/// 对话页面就是包含一系列时间顺序排序后的对话消息的list
class ChatMessage {
  final String messageId; // 每个消息有个ID方便整个对话列表的保存？？？
  final String text; // 文本内容
  final DateTime dateTime; // 时间
  final bool isFromUser; // 是否来自用户
  final String? avatarUrl; // 头像URL

  ChatMessage({
    required this.messageId,
    required this.text,
    required this.dateTime,
    required this.isFromUser,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'text': text,
      'date_time': dateTime,
      'is_from_user': isFromUser,
      'avatar_url': avatarUrl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as String,
      text: map['text'] as String,
      dateTime: DateTime.tryParse(map['date_time']) ?? DateTime.now(),
      isFromUser: map['is_from_user'] as bool,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    ChatMessage{
     messageId$messageId, text: $text, 
     dateTime: $dateTime, isFromUser: $isFromUser, avatarUrl: $avatarUrl, 
    }
    ''';
  }
}

/// 对话记录
// 一次对话记录需要一个标题，首次创建的时间，然后包含很多的对话消息
class ChatSession {
  final String uuid;
  final String title;
  final DateTime gmtCreate;
  final List<ChatMessage> messages;
  final String? llmName; // 使用的大模型名称需要记一下吗？

  ChatSession({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.messages,
    this.llmName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmt_create': gmtCreate,
      'messages': messages,
    };
  }

  @override
  String toString() {
    return '''
    ChatSession { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "messages": $messages
    }
    ''';
  }
}
