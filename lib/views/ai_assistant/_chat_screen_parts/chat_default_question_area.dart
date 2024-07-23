// default_question_area.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 对话页面预设对话区域
///
class ChatDefaultQuestionArea extends StatelessWidget {
  final List<String> defaultQuestions;
  final Function(String) onQuestionTap;

  const ChatDefaultQuestionArea({
    Key? key,
    required this.defaultQuestions,
    required this.onQuestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: defaultQuestions.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(
                    defaultQuestions[index],
                    style: const TextStyle(color: Colors.blue),
                  ),
                  trailing: const Icon(Icons.touch_app, color: Colors.blue),
                  onTap: () {
                    onQuestionTap(defaultQuestions[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
