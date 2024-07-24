import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import '../../../../models/llm_chat_state.dart';
import '../../_components/message_item.dart';

///
/// 这个和 ChatListArea 差不太多
/// 但专门没有滚动、重新生成等，就在对战群聊这里用一下
///
class MessageChatList extends StatelessWidget {
  final List<ChatMessage> messages;

// 2个模型的对战时，消息列表内部就不显示模型名称了
  final bool? isShowLable;

  const MessageChatList({
    super.key,
    required this.messages,
    this.isShowLable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(5.sp),
            child: Column(
              children: [
                /// 构建每个对话消息
                // 模型名称
                if (messages[index].role != 'user' && isShowLable == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 41.sp), // 头像宽度
                      Text(
                        messages[index].modelLabel ?? "<模型名>",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                // 消息主体
                MessageItem(message: messages[index]),

                /// 如果是大模型回复，可以有一些功能按钮
                if (messages[index].role == 'assistant')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      /// 如果不是等待响应才可以点击复制该条回复
                      if (messages[index].isPlaceholder != true)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: messages[index].content),
                            );
                            EasyLoading.showToast(
                              "已复制到剪贴板",
                              duration: const Duration(seconds: 3),
                              toastPosition: EasyLoadingToastPosition.center,
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      SizedBox(width: 10.sp),

                      /// 如果不是等待响应才显示token数量
                      if (messages[index].isPlaceholder != true)
                        Text(
                          "token 总计: ${messages[index].totalTokens}\n输入: ${messages[index].inputTokens} 输出: ${messages[index].outputTokens}",
                          style: TextStyle(fontSize: 10.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      SizedBox(width: 10.sp),
                    ],
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
