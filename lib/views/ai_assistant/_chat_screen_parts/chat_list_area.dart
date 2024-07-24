// chat_list_area.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart'; // 确保你已经导入了flutter_easyloading包
import 'package:flutter/services.dart';

import '../../../models/llm_chat_state.dart';
import '../_components/message_item.dart'; // 确保你已经导入了services包

///
/// 对话主页面
/// 注意：这个如果复用，messages可能是
///
class ChatListArea extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function()? regenerateLatestQuestion;
  // 对话文本的缩放，可传值进来进行缩放
  final double textScaleFactor;

  // 目前默认都显示，后续可以按需设定控制
  // 是否显示复制按钮
  // 是否显示重新生成按钮(有传函数就算需要)
  // 是否显示token消耗

  const ChatListArea({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.regenerateLatestQuestion,
    this.textScaleFactor = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
        child: ListView.builder(
          controller: scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.all(5.sp),
              child: Column(
                children: [
                  // 构建每个对话消息
                  MessageItem(message: messages[index]),

                  /// 如果是大模型回复，可以有一些功能按钮
                  if (messages[index].role == 'assistant')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        /// 排除占位消息后，是大模型最后一条回复，则可以重新生成
                        if ((index == messages.length - 1) &&
                            messages[index].isPlaceholder != true)
                          TextButton(
                            onPressed: regenerateLatestQuestion,
                            child: const Text("重新生成"),
                          ),

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
                        /// 2024-07-24 如果是特别大字模式，token就不显示了，可能会溢出
                        if (messages[index].isPlaceholder != true &&
                            textScaleFactor <= 1.6)
                          Text(
                            "token总计: ${messages[index].totalTokens}\n输入: ${messages[index].inputTokens} 输出: ${messages[index].outputTokens}",
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
      ),
    );
  }
}
