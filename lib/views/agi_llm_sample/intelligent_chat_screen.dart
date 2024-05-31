// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_brief_accounting/models/baidu_ernie_state.dart';
import 'package:uuid/uuid.dart';

import '../../apis/baidu_apis.dart';
import '../../apis/tencent_apis.dart';
import '../../models/llm_chat_state.dart';
import '../../models/tencent_hunyuan_state.dart';
import 'widgets/message_item.dart';

class IntelligentChatScreen extends StatefulWidget {
  // 混元还是erine(不同的公司，而且后者可以有好多个模型进行切换，前者就一个)
  final String llmType;
  const IntelligentChatScreen({super.key, required this.llmType});

  @override
  State createState() => _IntelligentChatScreenState();
}

class _IntelligentChatScreenState extends State<IntelligentChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

// 默认使用的大模型，可以自行切换。
// 预计希望在同一次对话时，即便切换了模型，也会带上上下文。
// 那就要注意数量了，8K的限制
  var defaultLlm = ErnieLLM.Speed128K.name;

  // 如果是混元大模型，只有1个模型接口可选，就不用构建下拉选择了
  // 只有时百度的文心大模型，才能构建多个可选的模型
  bool isErnie = false;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 等待AI响应时的占位的消息，在构建查询的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    text: "奋力思考中……",
    isFromUser: false,
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  List defaultQuestions = [
    "你是一位小学语文老师。请设计一份教案，内容需要包含2-3个互动游戏，以帮助学生更好地理解和欣赏辛弃疾《西江月·夜行黄沙道中》这首词。",
    "你是一位10w+爆款文章的编辑。请结合赛博玄学主题，如电子木鱼、机甲佛祖、星座、塔罗牌、人形锦鲤、工位装修等，用俏皮有网感的语言撰写一篇公众号文章。",
    "考公需要准备哪些资料，去哪里找",
    "现在你是一名具备丰富专业知识及教学经验的大学教授，你会对我给出的问题进行详细且专业的解答，注意你需要提供一些浅显易懂的示例帮助我进行理解。下面我给出的第一个问题是：怎样可以提高光电转换效率",
  ];

  @override
  void initState() {
    isErnie = widget.llmType.toLowerCase() != "hunyuan";

    if (isErnie) {
      defaultLlm = ErnieLLM.Speed128K.name;
    } else {
      defaultLlm = 'hunyuan';
    }

    super.initState();
  }

  void _sendMessage(String text, {bool isFromUser = true}) {
    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      text: text,
      isFromUser: isFromUser,
      dateTime: DateTime.now(),
    );

    setState(() {
      // AI思考和用户输入是相反的(如果用户输入了，就是在等到机器回到了)
      isBotThinking = isFromUser;

      messages.add(temp);
      _textController.clear();
      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      if (isFromUser) {
        // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
        // 一定注意要记得AI响应后要删除此占位的消息
        messages.add(placeholderMessage);

        print('defaultLlm.===============)$defaultLlm');

        // 不是腾讯，就是百度
        if (isErnie) {
          getErnieResponse();
        } else {
          getHunyuanResponse();
        }
      }
    });
  }

  getErnieResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<ErnieMessage> msgs =
        messages.where((e) => e.isPlaceholder != true).map((e) {
      return ErnieMessage(
        content: e.text,
        role: e.isFromUser ? "user" : "assistant",
      );
    }).toList();

    print("++++++++++++++++++++++++++++");
    print(msgs);

    var temp = await getErnieSpeedResponse(
      msgs,
      llmName: stringToErnieLlm(defaultLlm),
    );

    // 得到回复后要删除占位的消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    _sendMessage(temp.result ?? "暂无法回答", isFromUser: false);
  }

  getHunyuanResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<HunyuanMessage> msgs =
        messages.where((e) => e.isPlaceholder != true).map((e) {
      return HunyuanMessage(
        content: e.text,
        role: e.isFromUser ? "user" : "assistant",
      );
    }).toList();

    print("++++++++++++++++++++++++++++");
    print(msgs);

    var temp = await getHunyuanLiteResponse(msgs);

    // 得到回复后要删除占位的消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    _sendMessage(
      temp.choices?.first.message.content ?? "混元暂无法回答",
      isFromUser: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Demo'),
        actions: [
          const TextButton(
            onPressed: null,
            child: Text("切换模型"),
          ),
          if (isErnie)
            DropdownButton<ErnieLLM>(
              value: stringToErnieLlm(defaultLlm),
              items: ErnieLLM.values
                  .map<DropdownMenuItem<ErnieLLM>>((ErnieLLM value) {
                return DropdownMenuItem<ErnieLLM>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
              onChanged: (ErnieLLM? newValue) {
                setState(() {
                  defaultLlm = newValue!.name;
                  // 你可以在这里添加逻辑来处理选中的年月，比如解析为DateTime对象等
                });
              },
              hint: const Text('选择年月'),
            ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 如果是空，显示预设的问题
          if (messages.isEmpty)
            Expanded(
              child: ListView.builder(
                // reverse: true, // 反转列表，使新消息出现在底部
                itemCount: defaultQuestions.length,
                itemBuilder: (context, index) {
                  // 构建MessageItem
                  return InkWell(
                    onTap: () {
                      _sendMessage(defaultQuestions[index]);
                    },
                    child: Card(
                      child: Container(
                        padding: EdgeInsets.all(8.sp),
                        color: Colors.teal[100],
                        child: Text(defaultQuestions[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          // 显示对话消息
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 设置ScrollController
              // reverse: true, // 反转列表，使新消息出现在底部
              itemCount: messages.length,
              itemBuilder: (context, index) {
                // 构建MessageItem
                return MessageItem(
                  message: messages[index],
                );
              },
            ),
          ),
          // 输入框和发送按钮
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        const InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                TextButton(
                  onPressed: isBotThinking
                      ? null
                      : () {
                          // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                          FocusScope.of(context).unfocus();

                          _sendMessage(
                            _textController.text,
                            isFromUser: true,
                          );
                        },
                  child: Text('Send $isBotThinking'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
