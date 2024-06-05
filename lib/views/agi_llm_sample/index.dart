// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_brief_accounting/common/constants.dart';
import 'package:intl/intl.dart';

import '../../common/utils/db_helper.dart';
import '../../models/llm_chat_state.dart';
import 'intelligent_chat_screen.dart';

class AgiLlmSample extends StatefulWidget {
  const AgiLlmSample({super.key});

  @override
  State createState() => _AgiLlmSampleState();
}

class _AgiLlmSampleState extends State<AgiLlmSample> {
  final DBHelper _dbHelper = DBHelper();

  List<ChatSession> chatHsitory = [];
  // 要修改某个对话的名称
  final TextEditingController _selectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Free AGI LLMs'),
        title: const Text('智能对话'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Text(
                  '最近对话',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () async {
                  // 获取历史记录

                  //  await _dbHelper.deleteDB();

                  var a = await _dbHelper.queryChatList();

                  setState(() {
                    chatHsitory = a;
                  });
                  print("历史记录$a");

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
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
            data: """这里有一些免费的对话大模型。  
            来体验一下新的AI时代浪潮吧。  
            \n作为你的智能伙伴，  
            我既能写文案、想点子，  
            又能陪你聊天、答疑解惑。  
            \n文本翻译、FAQ、百科问答、情感分析、  
            阅读理解、内容创作、代码编写……  
            \n想知道我能做什么？  
            **点击**下面任意大模型，快来试一试吧！""",
          ),
          Divider(height: 50.sp),
          SizedBox(
            height: 0.25.sh,
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
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      // 设置圆角半径为10
                      borderRadius: BorderRadius.all(Radius.circular(30.sp)),
                      color: Colors.blue[100],
                    ),
                    // color: Colors.teal[100],
                    child: Center(
                      child: Text(
                        "百度千帆",
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
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
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      // 设置圆角半径为10
                      borderRadius: BorderRadius.all(Radius.circular(30.sp)),
                      color: Colors.teal[200],
                    ),
                    // color: Colors.teal[100],
                    child: Center(
                      child: Text(
                        '腾讯混元',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // 一般抽屉默认在左边，这样就在右边了
      // 2024-06-03 还是觉得一边对话一边可以修改和删除比较好，但这样没办法统一记录千帆和混元的所有对话
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            SizedBox(
              // 调整DrawerHeader的高度
              height: 60.sp,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.lightGreen[100]),
                child: const Center(child: Text('最近对话')),
              ),
            ),
            ...(chatHsitory.map((e) => buildGestureItems(e)).toList()),
          ],
        ),
      ),
    );
  }

  buildGestureItems(ChatSession e) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntelligentChatScreen(
              llmType: e.llmName,
              chatSessionId: e.uuid,
            ),
          ),
        );
      },
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 5.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: TextStyle(fontSize: 12.sp),
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat(constDatetimeFormat).format(e.gmtCreate),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80.sp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUpdateBotton(e),
                  _buildDeleteBotton(e),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 直接使用listtile感觉自定义不够高，限制较大
  buildTileItems(ChatSession e) {
    return ListTile(
      title: Text(
        e.title,
        style: TextStyle(fontSize: 13.sp),
      ),
      subtitle: Text(
        DateFormat(constDatetimeFormat).format(e.gmtCreate),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // // 自定义的按钮
          // SizedBox(
          //   width: 30,
          //   height: 30,
          //   child: RawMaterialButton(
          //     constraints: BoxConstraints.tight(Size(15, 15.sp)),
          //     onPressed: () {
          //       // 在这里处理按钮点击事件
          //     },
          //     shape: const CircleBorder(),
          //     child: Icon(Icons.edit, size: 15.sp),
          //   ),
          // ),
          _buildDeleteBotton(e),
          _buildUpdateBotton(e),
        ],
      ),
      onTap: () {
        print(e.llmName);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntelligentChatScreen(
              llmType: e.llmName,
              chatSessionId: e.uuid,
            ),
          ),
        ).then((value) {
          print("chatscreen的返回---$value");
        });
      },
    );
  }

  _buildUpdateBotton(ChatSession e) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          setState(() {
            _selectionController.text = e.title;
          });
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("修改对话记录标题:", style: TextStyle(fontSize: 18.sp)),
                content: TextField(
                  controller: _selectionController,
                  maxLines: 2,
                  // autofocus: true,
                  // onChanged: (v) {
                  //   print("onChange: $v");
                  // },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              var temp = e;
              temp.title = _selectionController.text.trim();
              // 修改对话的标题
              _dbHelper.updateChatSession(temp);

              // 修改成功后重新查询更新
              var b = await _dbHelper.queryChatList();
              setState(() {
                chatHsitory = b;
              });
            }
          });
        },
        icon: Icon(
          Icons.edit,
          size: 16.sp,
          color: Theme.of(context).primaryColor,
        ),
        iconSize: 18.sp,
      ),
    );
  }

  _buildDeleteBotton(ChatSession e) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("确认删除对话记录:", style: TextStyle(fontSize: 18.sp)),
                content: Text(e.title),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              // 先删除
              _dbHelper.deleteChatById(e.uuid);

              // 然后重新查询并更新
              var b = await _dbHelper.queryChatList();
              setState(() {
                chatHsitory = b;
              });
            }
          });
        },
        icon: Icon(
          Icons.delete,
          size: 16.sp,
          color: Theme.of(context).primaryColor,
        ),
        iconSize: 18.sp,
        padding: EdgeInsets.all(0.sp),
      ),
    );
  }
}
