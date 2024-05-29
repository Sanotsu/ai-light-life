import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Message {
  final String avatarUrl; // 头像URL
  final String text; // 文本内容
  final DateTime dateTime; // 时间
  final bool isFromUser; // 是否来自用户

  Message({
    required this.avatarUrl,
    required this.text,
    required this.isFromUser,
    required this.dateTime,
  });
}

class MessageItem extends StatelessWidget {
  final Message message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 根据消息来源确定布局方向
    bool isFromEnd = message.isFromUser;
    // MainAxisAlignment alignment =
    //     isFromEnd ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Row(
      // mainAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像，展示机器和用户用于区分即可
        CircleAvatar(
          radius: 20.sp,
          backgroundColor: isFromEnd ? Colors.grey : null,
          child: Icon(isFromEnd ? Icons.bolt : Icons.person),
        ),
        SizedBox(width: 10.sp), // 头像和文本之间的间距
        // 消息内容
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${message.dateTime}',
                // 根据来源设置不同颜色
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isFromEnd ? Colors.blue : Colors.grey,
                ),
              ),
              // 这里可以根据需要添加时间戳等
              Card(
                elevation: 10,
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Text(
                    '${message.isFromUser ? 'Me' : 'Bot'}: ${message.text}',
                    // 根据来源设置不同颜色
                    style: TextStyle(
                      color: isFromEnd ? Colors.blue : Colors.grey,
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
