// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'intelligent_chat_screen.dart';

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
        title: const Text('Free AGI LLMs'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 显示对话消息
          const Expanded(
            child: Text(
              """这里是一些免费的大模型。\n来体验一下新的AGI时代浪潮吧。
            \n作为你的智能伙伴，\n我既能写文案、想点子，\n又能陪你聊天、答疑解惑。
            \n想知道我还能做什么？\n选择下面任意模块，快来试一试！
            \n文本翻译、FAQ、百科问答、情感分析、\n阅读理解、内容创作、代码编写""",
            ),
          ),
          // 输入框和发送按钮
          const Divider(),
          SizedBox(
            height: 0.3.sh,
            child: GridView.count(
              primary: false,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              childAspectRatio: 4 / 3,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntelligentChatScreen(
                          llmType: 'ernie',
                        ),
                      ),
                    ).then((value) {
                      print("chatscreen的返回---$value");
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.teal[100],
                    child: const Text("百度文心大模型"),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntelligentChatScreen(
                          llmType: 'hunyuan',
                        ),
                      ),
                    ).then((value) {
                      print("chatscreen的返回---$value");
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.teal[300],
                    child: const Text('腾讯混元大模型'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
