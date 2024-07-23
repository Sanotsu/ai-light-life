// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'aggregate_search/index.dart';
import 'chat_bot/index.dart';
import 'document_summary/index.dart';
import 'multi_translator/index.dart';
import 'photo_translation/index.dart';

///
/// 2024-07-16 规划一系列有AI加成的使用工具，这里是主入口
///
class AIToolIndex extends StatefulWidget {
  const AIToolIndex({super.key});

  @override
  State createState() => _AIToolIndexState();
}

class _AIToolIndexState extends State<AIToolIndex> {
  // 部分花费大的工具，默认先不开启了
  bool isEnableMyCose = false;

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
        title: GestureDetector(
          onLongPress: () async {
            // 长按之后，先改变是否使用作者应用的标志
            setState(() {
              isEnableMyCose = !isEnableMyCose;
            });
            EasyLoading.showInfo("${isEnableMyCose ? "已启用" : "已关闭"}作者API Key");
          },
          child: const Text('AI 智能助手'),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "服务生成的所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度或观点。",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 10.sp),
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
                  "你问\n我答",
                  icon: const Icon(Icons.chat_outlined),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatBat(),
                      ),
                    );
                  },
                ),
                buildAIToolEntrance(
                  "拍照\n翻译",
                  icon: const Icon(Icons.photo_camera_outlined),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhotoTranslation(),
                      ),
                    );
                  },
                ),
                buildAIToolEntrance(
                  "翻译\n助手",
                  icon: const Icon(Icons.translate),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MultiTranslator(),
                      ),
                    );
                  },
                ),
                buildAIToolEntrance(
                  "文档\n提要",
                  icon: const Icon(Icons.newspaper),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentSummary(),
                      ),
                    );
                  },
                ),
                buildAIToolEntrance(
                  "全网\n搜索",
                  icon: const Icon(Icons.search),
                  color: Colors.blue[100],
                  onTap: () {
                    if (isEnableMyCose) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AggregateSearch(),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("启用提示"),
                            content: const Text("确定使用实时全网检索服务吗？\n接口价格会稍微高些。"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text("取消"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text("确认"),
                              ),
                            ],
                          );
                        },
                      ).then((value) {
                        if (value == true) {
                          setState(() {
                            isEnableMyCose = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AggregateSearch(),
                            ),
                          );
                        }
                      });
                    }
                  },
                ),
                buildAIToolEntrance(
                  "功能\n占位(TODO)",
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
