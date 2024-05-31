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
  late ErnieLLM? defaultLlm;

  // 如果是混元大模型，只有1个模型接口可选，就不用构建下拉选择了
  // 只有时百度的千帆大模型，才能构建多个可选的模型
  bool isErnie = false;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    text: "奋力思考中……",
    isFromUser: false,
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 进入对话页面简单预设的一些问题
  List defaultQuestions = [
    "你是一位产品文案。请设计一份PPT大纲，介绍你们公司新推出的防晒霜，要求言简意赅并且具有创意。",
    "你是一位10w+爆款文章的编辑。请结合赛博玄学主题，如电子木鱼、机甲佛祖、星座、塔罗牌、人形锦鲤、工位装修等，用俏皮有网感的语言撰写一篇公众号文章。",
    "假如你是一对热恋情侣中的男生。现在你女朋友到生理期了，你应该为她做些什么？",
    "使用python3编写一个快速排序算法。",
  ];

  @override
  void initState() {
    isErnie = widget.llmType.toLowerCase() != "hunyuan";

    // 千帆大模型有多个免费的模型所以才需要默认设一个；
    // 混元大模型时不会用到这个栏位，就没有初始化给默认值
    if (isErnie) {
      defaultLlm = ErnieLLM.Speed8K;
    }

    super.initState();
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
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

        // 不是腾讯，就是百度
        if (isErnie) {
          getErnieResponse();
        } else {
          getHunyuanResponse();
        }
      }
    });
  }

  // 获取调用千帆大模型API的响应
  getErnieResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<ErnieMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => ErnieMessage(
              content: e.text,
              role: e.isFromUser ? "user" : "assistant",
            ))
        .toList();

    // 注意：一定确保使用千帆大模型时，有默认的模型
    var temp = await getErnieSpeedResponse(msgs, llmName: defaultLlm!);

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    var tempText = "当前使用人数角度，千帆AI未响应，请稍候重试。";
    if (temp.errorCode != null) {
      tempText =
          "千帆API接口报错: {Code: ${temp.errorCode}, Msg: ${temp.errorMsg}}，请切换其他模型试试。";
    } else if (temp.result != null) {
      tempText = temp.result!;
    }
    _sendMessage(tempText, isFromUser: false);
  }

  // 获取调用混元大模型API的响应
  getHunyuanResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<HunyuanMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => HunyuanMessage(
              content: e.text,
              role: e.isFromUser ? "user" : "assistant",
            ))
        .toList();

    var temp = await getHunyuanLiteResponse(msgs);

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    // ？？？2024-05-31 混元响应的消息文本时一个List<Choice>?，
    // 暂时推测非流式响应时，只有第一个值能取到正常消息
    var tempText = "当前使用人数角度，混元AI未响应，请稍候重试。";
    if (temp.errorMsg != null) {
      tempText =
          "混元API接口报错: {Code: ${temp.errorMsg!.code}, Msg: ${temp.errorMsg!.message}}，请切换其他模型试试。";
    } else if (temp.choices != null && temp.choices!.isNotEmpty) {
      tempText = temp.choices!.first.message.content;
    }
    _sendMessage(tempText, isFromUser: false);
  }

  /// 2024-05-31 暂时不根据token的返回来说了，临时直接显示整个对话不超过8千字
  bool isMessageTooLong() =>
      messages.fold(0, (sum, msg) => sum + msg.text.length) > 8000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          const TextButton(
            onPressed: null,
            child: Text("切换模型"),
          ),
          if (isErnie)
            DropdownButton<ErnieLLM>(
              value: defaultLlm,
              isDense: true,
              items: ErnieLLM.values
                  .map<DropdownMenuItem<ErnieLLM>>(
                    (ErnieLLM value) => DropdownMenuItem<ErnieLLM>(
                      value: value,
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        value.name,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (ErnieLLM? newValue) {
                setState(() {
                  defaultLlm = newValue!;
                });
              },
            ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 如果是空，显示预设的问题
          if (messages.isEmpty) const Text("你可以试着问我："),
          if (messages.isEmpty)
            Expanded(
              flex: 2,
              child: ListView.builder(
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
                return Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: MessageItem(message: messages[index]),
                );
              },
            ),
          ),
          // 输入框和发送按钮
          const Divider(),
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '可以向我提任何问题哦 ٩(๑❛ᴗ❛๑)۶',
                      border: OutlineInputBorder(), // 添加边框
                    ),
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (String? text) {
                      if (text != null) {
                        setState(() {
                          userInput = text.trim();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  // 如果AI正在响应，或者输入框没有任何文字，不让点击发送
                  onPressed: isBotThinking || userInput.isEmpty
                      ? null
                      : () {
                          if (!isMessageTooLong()) {
                            // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                            FocusScope.of(context).unfocus();

                            _sendMessage(userInput, isFromUser: true);

                            // 发送完要清空记录用户输的入变量
                            setState(() {
                              userInput = "";
                            });
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('对话过长'),
                                  content: const Text(
                                    '注意，由于免费API的使用压力，单个聊天对话的总长度不能超过8000字，请新开对话，谢谢。',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('确定'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
