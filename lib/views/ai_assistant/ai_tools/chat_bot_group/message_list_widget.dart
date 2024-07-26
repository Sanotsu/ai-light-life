import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import '../../../../models/llm_chat_state.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_components/message_item.dart';

///
/// 这个和 ChatListArea 差不太多
/// 但专门没有滚动、重新生成等，就在对战群聊这里用一下
///
class MessageChatList extends StatefulWidget {
  final List<ChatMessage> messages;

// 2个模型的对战时，消息列表内部就不显示模型名称了
  final bool? isShowLable;

  const MessageChatList({
    super.key,
    required this.messages,
    this.isShowLable = true,
  });

  @override
  State<MessageChatList> createState() => _MessageChatListState();
}

class _MessageChatListState extends State<MessageChatList> {
  // 2024-07-26
  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 这里直接把连续对话的文本进行缩放，所有用到的都会生效
  double _textScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();

    _textScaleFactor = MyGetStorage().getChatListAreaScale();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScaleFactor),
        ),
        child: ListView.builder(
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.all(5.sp),
              child: Column(
                children: [
                  /// 构建每个对话消息
                  // 模型名称
                  if (widget.messages[index].role != 'user' &&
                      widget.isShowLable == true)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 41.sp), // 头像宽度
                        Text(
                          widget.messages[index].modelLabel ?? "<模型名>",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  // 消息主体
                  MessageItem(message: widget.messages[index]),

                  /// 如果是大模型回复，可以有一些功能按钮
                  if (widget.messages[index].role == 'assistant')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        /// 如果不是等待响应才可以点击复制该条回复
                        if (widget.messages[index].isPlaceholder != true)
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                    text: widget.messages[index].content),
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
                        if (widget.messages[index].isPlaceholder != true)
                          Text(
                            "token 总计: ${widget.messages[index].totalTokens}\n输入: ${widget.messages[index].inputTokens} 输出: ${widget.messages[index].outputTokens}",
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
