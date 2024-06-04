import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  } else {
    return Container();
  }
}

commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
