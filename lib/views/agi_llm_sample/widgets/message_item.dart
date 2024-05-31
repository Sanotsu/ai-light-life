import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_brief_accounting/common/constants.dart';
import 'package:intl/intl.dart';

import '../../../models/llm_chat_state.dart';

class MessageItem extends StatelessWidget {
  final ChatMessage message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 根据消息来源确定布局方向
    bool isFromUser = message.isFromUser;
    // MainAxisAlignment alignment =
    //     isFromEnd ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Row(
      // mainAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 3.sp),
        // 头像，展示机器和用户用于区分即可
        CircleAvatar(
          radius: 18.sp,
          backgroundColor: isFromUser ? Colors.grey : null,
          child: Icon(isFromUser ? Icons.person : Icons.bolt),
        ),
        SizedBox(width: 3.sp), // 头像和文本之间的间距
        // 消息内容
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 这里可以根据需要添加时间戳等
              Padding(
                padding: EdgeInsets.only(left: 10.sp),
                child: Text(
                  DateFormat(constDatetimeFormat).format(message.dateTime),
                  // 根据来源设置不同颜色
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isFromUser ? Colors.blue : Colors.black,
                  ),
                ),
              ),
              // 如果是占位的消息，则显示装圈圈
              if (message.isPlaceholder == true)
                Card(
                  elevation: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bot: ${message.text}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const CircularProgressIndicator(),
                    ],
                  ),
                ),

              // 如果不是占位的消息，则正常显示
              if (message.isPlaceholder != true)
                Card(
                  elevation: 10,
                  child: Padding(
                    padding: EdgeInsets.all(5.sp),
                    child: Text(
                      '${message.isFromUser ? 'Me' : 'Bot'}: ${message.text}',
                      // 根据来源设置不同颜色
                      style: TextStyle(
                        color: isFromUser ? Colors.blue : Colors.black,
                      ),
                    ),

                    /// 这里考虑根据md或者代码格式等格式化显示内容
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
