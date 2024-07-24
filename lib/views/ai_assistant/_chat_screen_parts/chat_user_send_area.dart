import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 用户发送区域
/// aggregate_search 和 chat_bot 都可以用
///
class ChatUserSendArea extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isBotThinking;
  final String userInput;
  final Function(String) onChanged;
  final VoidCallback onSendPressed;
  final bool Function()? isMessageTooLong;

  const ChatUserSendArea({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isBotThinking,
    required this.userInput,
    required this.onChanged,
    required this.onSendPressed,
    this.isMessageTooLong,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 1,
              onChanged: onChanged,
            ),
          ),
          IconButton(
            onPressed: isBotThinking || userInput.isEmpty
                ? null
                : () {
                    // 有传长度限制函数、且限制的结果为true，才显示弹窗
                    if (isMessageTooLong != null && isMessageTooLong!()) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('对话过长'),
                            content: const Text(
                              '注意，由于免费API的使用压力，单个聊天对话的总长度不能超过8000字，请新开对话，谢谢。',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      FocusScope.of(context).unfocus();
                      onSendPressed();
                    }
                  },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
