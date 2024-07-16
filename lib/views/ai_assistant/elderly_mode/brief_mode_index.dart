// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';

import 'brief_one_chat_screen.dart';

///
/// 2024-07-14 极简模式，入口内容更简洁，配合全局大字模式
/// 只显示免费的文本对话模型，没有自定义配置或者图像理解、图像生成等内容
///
class BriefAIChatIndex extends StatefulWidget {
  const BriefAIChatIndex({super.key});

  @override
  State createState() => _BriefAIChatIndexState();
}

class _BriefAIChatIndexState extends State<BriefAIChatIndex> {
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
        title: RichText(
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          text: TextSpan(
            children: [
              // 为了分类占的宽度一致才用的，只是显示的话可不必
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 50.sp),
                  child: const Text('AI 智能助手'),
                ),
              ),
              // TextSpan(
              //   text: "  (Simple AGI LLMs)",
              //   style: TextStyle(color: Colors.black, fontSize: 15.sp),
              // ),
            ],
          ),
        ),

        // title: const Text('智能对话'),
        actions: [
          TextButton(
            // 如果在缓存中存在配置，则跳到到对话页面，如果没有，进入配置页面
            onPressed: () {},
            child: const Text("应用配置"),
          ),
        ],
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
              crossAxisCount: 1,
              childAspectRatio: 5 / 2,
              children: <Widget>[
                buildAIToolEntrance(
                  0,
                  "你问我答",
                  icon: const Icon(Icons.chat),
                  color: Colors.blue[100],
                ),
                buildAIToolEntrance(
                  2,
                  "你说我画",
                  icon: const Icon(Icons.image),
                  color: Colors.grey[100],
                ),
                buildAIToolEntrance(
                  3,
                  "分析图片",
                  icon: const Icon(Icons.photo_camera),
                  color: Colors.green[100],
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
    int type,
    String label, {
    Icon? icon,
    Color? color,
  }) {
    return InkWell(
      onTap: () {
        // 0, "智能对话-免费"
        // 2, "文本生图
        // 3, "图像理解
        if (type == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BriefChatScreen()),
          );
        } else if (type == 2) {
          commonHintDialog(context, "提示", "暂不支持", msgFontSize: 20.sp);
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const AliyunText2ImageScreen(),
          //   ),
          // );
        } else if (type == 3) {
          commonHintDialog(context, "提示", "暂不支持", msgFontSize: 20.sp);
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const BaiduImage2TextScreen(),
          //   ),
          // );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BriefChatScreen()),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(8.sp),
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
            title: Text(
              label,
              style: TextStyle(
                fontSize: 36.sp,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            leading: icon ?? const Icon(Icons.chat, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
