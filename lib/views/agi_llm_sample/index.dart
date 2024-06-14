// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'baidu_image2text_screen.dart';
import 'common_chat_screen.dart';
import 'aliyun_text2image_screen.dart';

class AgiLlmSample extends StatefulWidget {
  const AgiLlmSample({super.key});

  @override
  State createState() => _AgiLlmSampleState();
}

class _AgiLlmSampleState extends State<AgiLlmSample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: Text(
                    'Free AGI LLMs',
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              TextSpan(
                text: "  (智能助手)",
                style: TextStyle(color: Colors.black, fontSize: 15.sp),
              ),
            ],
          ),
        ),
        // title: const Text('智能对话'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 显示对话消息
          // const Text(
          //   """这里有一些免费的对话大模型。\n来体验一下新的AI时代浪潮吧。
          //   \n作为你的智能伙伴，\n我既能写文案、想点子，\n又能陪你聊天、答疑解惑。
          //   \n文本翻译、FAQ、百科问答、情感分析、\n阅读理解、内容创作、代码编写……
          //   \n想知道我能做什么？\n点击 下面任意大模型，快来试一试吧！""",
          // ),
          const MarkdownBody(
            data: """这里有一些免费的对话大模型。  
            来体验一下新的AI时代浪潮吧。  
            \n作为你的智能伙伴，  
            我既能写文案、想点子，  
            又能陪你聊天、答疑解惑。  
            \n文本翻译、FAQ、百科问答、情感分析、  
            阅读理解、内容创作、代码编写……  
            \n想知道我能做什么？  
            **点击**下面大模型分类，快来试一试吧！""",
          ),
          Divider(height: 50.sp),
          SizedBox(
            height: 0.3.sh,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
              crossAxisCount: 2,
              childAspectRatio: 2 / 1,
              children: <Widget>[
                buildAIToolEntrance(0, "文生文", color: Colors.blue[200]),
                buildAIToolEntrance(1, "文生图", color: Colors.grey[100]),
                buildAIToolEntrance(2, "图生文", color: Colors.green[100]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AI对话云平台入口按钮(默认非流式)
  buildAIToolEntrance(int type, String label, {Color? color}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            if (type == 0) {
              return const CommonChatScreen();
            } else if (type == 1) {
              return const AliyunText2ImageScreen();
            } else {
              return const BaiduImage2TextScreen();
            }
          }),
        );
      },
      child: Container(
        padding: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          // 设置圆角半径为10
          borderRadius: BorderRadius.all(Radius.circular(30.sp)),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
