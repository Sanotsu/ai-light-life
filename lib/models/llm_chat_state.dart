import 'dart:convert';

import 'package:free_brief_accounting/common/constants.dart';
import 'package:intl/intl.dart';

/// 人机对话的每一条消息的结果
/// 对话页面就是包含一系列时间顺序排序后的对话消息的list
class ChatMessage {
  final String messageId; // 每个消息有个ID方便整个对话列表的保存？？？
  final String text; // 文本内容
  final DateTime dateTime; // 时间
  final bool isFromUser; // 是否来自用户
  final String? avatarUrl; // 头像URL
  final bool? isPlaceholder; // 是否是等待响应时的占位消息

  ChatMessage({
    required this.messageId,
    required this.text,
    required this.dateTime,
    required this.isFromUser,
    this.avatarUrl,
    this.isPlaceholder,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'text': text,
      'date_time': dateTime,
      'is_from_user': isFromUser,
      'avatar_url': avatarUrl,
      'is_placeholder': isPlaceholder,
    };
  }

// fromMap 一般是数据库读取时用到
// fromJson 一般是从接口或者其他文本转换时用到
//    2024-06-03 使用parse而不是tryParse就可能会因为格式不对抛出异常
//    但是存入数据不对就是逻辑实现哪里出了问题。使用后者默认值也不知道该使用哪个。
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as String,
      text: map['text'] as String,
      dateTime: DateTime.parse(map['date_time']),
      isFromUser: bool.parse(map['is_from_user']),
      avatarUrl: map['avatar_url'] as String?,
      isPlaceholder: bool.tryParse(map['is_placeholder']),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json["message_id"],
        text: json["text"],
        dateTime: DateTime.parse(json["date_time"]),
        isFromUser: bool.parse(json["is_from_user"]),
        avatarUrl: json["avatar_url"],
        isPlaceholder: bool.tryParse(json["is_placeholder"]),
      );

  Map<String, dynamic> toJson() => {
        "message_id": messageId,
        "text": text,
        "date_time": dateTime,
        "is_from_user": isFromUser,
        "avatar_url": avatarUrl,
        "is_placeholder": isPlaceholder,
      };

  @override
  String toString() {
    // 2024-06-03 这个对话会被作为string存入数据库，然后再被读取转型为ChatMessage。
    // 所以需要是个完整的json字符串，一般fromMap时可以处理
    return '''
    {
     "message_id": "$messageId", 
     "text": ${jsonEncode(text)}, 
     "date_time": "$dateTime", 
     "is_from_user": "$isFromUser", 
     "avatar_url": "$avatarUrl", 
     "is_placeholder":"$isPlaceholder"
    }
    ''';
  }
}

/// 对话记录 这个是存入sqlite的表对应的模型
// 一次对话记录需要一个标题，首次创建的时间，然后包含很多的对话消息
class ChatSession {
  final String uuid;
  // 因为该栏位需要可修改，就不能为final了
  String title;
  final DateTime gmtCreate;
  // 因为该栏位需要可修改，就不能为final了
  List<ChatMessage> messages;
  // 2024-06-01 大模型名称也要记一下，说不定后续要存API的原始返回内容复用
  final String llmName; // 使用的大模型名称需要记一下吗？
  // 2024-06-06 记录了大模型名称，也记一下使用在哪个云平台
  final String? cloudPlatformName;

  ChatSession({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.messages,
    required this.llmName,
    this.cloudPlatformName,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      gmtCreate: DateTime.tryParse(map['gmt_create']) ?? DateTime.now(),
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((messageMap) =>
              ChatMessage.fromMap(messageMap as Map<String, dynamic>))
          .toList(),
      llmName: map['llm_name'] as String,
      cloudPlatformName: map['yun_platform_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmt_create': DateFormat(constDatetimeFormat).format(gmtCreate),
      'messages': messages.toString(),
      'llm_name': llmName,
      'yun_platform_name': cloudPlatformName,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        uuid: json["uuid"],
        messages: List<ChatMessage>.from(
          json["messages"].map((x) => ChatMessage.fromJson(x)),
        ),
        title: json["title"],
        gmtCreate: json["gmt_create"],
        llmName: json["llm_name"],
        cloudPlatformName: json["yun_platform_name"],
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
        "title": title,
        "gmt_create": gmtCreate,
        "llm_name": llmName,
        "yun_platform_name": cloudPlatformName,
      };

  @override
  String toString() {
    return '''
    ChatSession { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "messages": $messages,
      "llmName": $llmName,
      "cloudPlatformName": $cloudPlatformName
    }
    ''';
  }
}
