// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chatbot/chatbat_screen.dart';

///
/// 2024-07-16 规划一系列有AI加成的使用工具，这里是主入口
///
class AIToolIndex extends StatefulWidget {
  const AIToolIndex({super.key});

  @override
  State createState() => _AIToolIndexState();
}

class _AIToolIndexState extends State<AIToolIndex> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('AI 智能助手'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 入口按钮
          SizedBox(
            height: screenBodyHeight - 50.sp,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              crossAxisCount: 2,
              childAspectRatio: 4 / 3,
              children: <Widget>[
                buildAIToolEntrance(
                  "你问我答",
                  icon: const Icon(Icons.chat_outlined),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatBatScreen(),
                      ),
                    );
                  },
                ),
                buildAIToolEntrance(
                  "拍照翻译(TODO)",
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                buildAIToolEntrance(
                  "翻译助手(TODO)",
                  icon: const Icon(Icons.translate),
                ),
                buildAIToolEntrance(
                  "阅读总结(TODO)",
                  icon: const Icon(Icons.newspaper),
                ),
                buildAIToolEntrance(
                  "聚合搜索(TODO)",
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AI对话云平台入口按钮
  buildAIToolEntrance(
    String label, {
    Icon? icon,
    Color? color,
    void Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5.sp),
        decoration: BoxDecoration(
          // 设置圆角半径为10
          borderRadius: BorderRadius.all(Radius.circular(15.sp)),
          color: color ?? Colors.teal[200],
          // 添加阴影效果
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // 阴影颜色
              spreadRadius: 2, // 阴影的大小
              blurRadius: 5, // 阴影的模糊程度
              offset: Offset(0, 2.sp), // 阴影的偏移量
            ),
          ],
        ),
        child: Center(
          child: ListTile(
            leading: icon ?? const Icon(Icons.chat, color: Colors.blue),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
