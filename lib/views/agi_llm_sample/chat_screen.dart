import 'package:flutter/material.dart';

import 'widgets/message_item.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  // 假设的对话数据
  List<Message> messages = [
    Message(
      avatarUrl: 'https://example.com/user-avatar.png',
      text: 'Hello! This is a normal message.',
      isFromUser: true,
      dateTime: DateTime(2023, 12, 14, 12, 23, 34),
    ),
    Message(
      avatarUrl: 'https://example.com/bot-avatar.png',
      text: '```python\nprint("Hello from a code block!")\n```',
      isFromUser: false,
      dateTime: DateTime(2023, 12, 14, 12, 26, 40),
    ),
    Message(
      avatarUrl: 'https://example.com/bot-avatar.png',
      text: """
在Flutter中实现一个对话页面，用户输入一个问题，后台返回一个答案，同时在后台回答问题时用户不能继续输入是可以做到的。
可以通过使用Flutter的TextEditingController来控制用户是否可以输入以及获取输入的内容，同时通过网络请求或其他方式从后台获取答案。

下面是一个简单的示例代码，演示如何在Flutter中实现这个功能：
""",
      isFromUser: true,
      dateTime: DateTime(2023, 12, 14, 12, 26, 40),
    ),
    Message(
      avatarUrl: 'https://example.com/bot-avatar.png',
      text: """```python\nimport 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ConversationPage(),
    );
  }
}```""",
      isFromUser: false,
      dateTime: DateTime(2023, 12, 14, 13, 26, 40),
    ),
    // ... 其他消息
  ];

  void _sendMessage() {
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = Message(
      avatarUrl: 'https://example.com/bot-avatar.png',
      text: _textController.text,
      isFromUser: true,
      dateTime: DateTime.now(),
    );

    setState(() {
      messages.add(temp);
      _textController.clear();
      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Demo'),
        actions: const [
          TextButton(
            onPressed: null,
            child: Text("切换模型"),
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示对话消息
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 设置ScrollController
              // reverse: true, // 反转列表，使新消息出现在底部
              itemCount: messages.length,
              itemBuilder: (context, index) {
                // 构建MessageItem
                return MessageItem(
                  message: messages[index],
                );
              },
            ),
          ),
          // 输入框和发送按钮
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        const InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                TextButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
