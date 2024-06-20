// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'baidu_image2text_screen.dart';
import 'aliyun_text2image_screen.dart';
import 'cus_llm_config/user_cus_model_stepper.dart';
import 'one_chat_screen.dart';

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
                    '智能助手',
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              TextSpan(
                text: "  (Simple AGI LLMs)",
                style: TextStyle(color: Colors.black, fontSize: 15.sp),
              ),
            ],
          ),
        ),
        // title: const Text('智能对话'),
        actions: [
          TextButton(
            // 如果在缓存中存在配置，则跳到到对话页面，如果没有，进入配置页面
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserCusModelStepper(),
                ),
              );
            },
            child: const Text("自行配置"),
          ),
        ],
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
            data: """这里有一些简单的大模型，体验一下AI能量吧。  
            ***智能对话***  
            既能写文案、想点子，又能陪你聊天、答疑解惑。  
            文本翻译、百科问答、情感分析、FAQ、    
            阅读理解、内容创作、代码编写……无所不能。     
            ***文本生图***   
            简单的几句话，就能帮你生成各种风格的图片。  
            ***图像理解***  
            给我一张图，我能回答你关于该图片的有关问题。  

            \n想知道我能做什么？  
            **点击**下面指定功能，快来试一试吧！""",
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
                buildAIToolEntrance(0, "智能对话", color: Colors.blue[200]),
                buildAIToolEntrance(3, "智能对话\n限量测试", color: Colors.blue[200]),
                buildAIToolEntrance(1, "文本生图\n两毛一张", color: Colors.grey[100]),
                buildAIToolEntrance(2, "图像理解", color: Colors.green[100]),
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
              return const OneChatScreen();
            } else if (type == 1) {
              return const AliyunText2ImageScreen();
            } else if (type == 2) {
              return const BaiduImage2TextScreen();
            } else if (type == 3) {
              return const OneChatScreen(isLimitedTest: true);
            } else {
              return const OneChatScreen();
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
