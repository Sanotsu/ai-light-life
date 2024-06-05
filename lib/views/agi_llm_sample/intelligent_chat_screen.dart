// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_brief_accounting/models/baidu_ernie_state.dart';
import 'package:uuid/uuid.dart';

import '../../apis/baidu_apis.dart';
import '../../apis/tencent_apis.dart';
import '../../common/utils/db_helper.dart';
import '../../models/llm_chat_state.dart';
import '../../models/tencent_hunyuan_state.dart';
import 'widgets/message_item.dart';

class IntelligentChatScreen extends StatefulWidget {
  // 混元还是erine(不同的公司，而且后者可以有好多个模型进行切换，前者就一个)
  final String llmType;
  // 2024-06-01 点击最近的历史记录对话，可以加载到新的对话页面
  // 那么需要一个标识获取该历史对话的内容
  final String? chatSessionId;
  const IntelligentChatScreen({
    super.key,
    required this.llmType,
    this.chatSessionId,
  });

  @override
  State createState() => _IntelligentChatScreenState();
}

class _IntelligentChatScreenState extends State<IntelligentChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final DBHelper _dbHelper = DBHelper();

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
    text: "努力思考中(等待越久,回复内容越多)  ",
    isFromUser: false,
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 2024-06-01 当前的对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  ChatSession? chatSession;

  // 要修改某个对话的名称
  final TextEditingController _titleController = TextEditingController();

  // 进入对话页面简单预设的一些问题
  List defaultQuestions = [
    "你是一位产品文案。请设计一份PPT大纲，介绍你们公司新推出的防晒霜，要求言简意赅并且具有创意。",
    "你是一位10w+爆款文章的编辑。请结合赛博玄学主题，如电子木鱼、机甲佛祖、星座、塔罗牌、人形锦鲤、工位装修等，用俏皮有网感的语言撰写一篇公众号文章。",
    "你是一个营养师。现在请帮我制定一周的健康减肥食谱。",
    // "小明因为女朋友需要的高额彩礼费而伤心焦虑，请帮我安慰一下他。",
    // "请为一家互联网公司写一则差旅费用管理规则。",
    "我是小区物业人员，小区下周六（9.30号）下午16:00-18:00，因为电力改造施工要停电，请帮我拟一份停电通知。",
    "一只青蛙一次可以跳上1级台阶，也可以跳上2级。求该青蛙跳上一个n级的台阶总共有多少种跳法。",
    // "小王最近天天加班，压力很大，心情很糟。也想着跳槽，但是就业大环境很差，不容易找到新工作。现在他很迷茫，请帮他出出主意。",
    // "使用python3编写一个快速排序算法。",
    // "如果我的邻居持续发出噪音严重影响我的生活，除了民法典1032条，还有什么法条支持居民向噪音发出者维权？",
    // "请帮我写一份通用的加薪申请模板。",
    // "一个长方体的棱长和是144厘米，它的长、宽、高之比是4:3:2，长方体的体积是多少？",
  ];

  @override
  void initState() {
    isErnie = widget.llmType.toLowerCase() != "hunyuan";

    // 千帆大模型有多个免费的模型所以才需要默认设一个；
    // 混元大模型时不会用到这个栏位，就没有初始化给默认值
    if (isErnie) {
      defaultLlm = ErnieLLM.Speed8K;
    }

    // 2024-06-01 为了通用，就在外面传入对话记录编号
    if (widget.chatSessionId != null) {
      getChatInfo(widget.chatSessionId!);
    }

    super.initState();
  }

  // 获取对话列表
  getChatInfo(String chatId) async {
    print("调用了getChatInfo----------");
    var list = await _dbHelper.queryChatList(uuid: chatId);

    if (list.isNotEmpty && list.isNotEmpty) {
      setState(() {
        chatSession = list.first;

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;
      });
    }
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

      // 2024-06-01 注意，在每次添加了对话之后，都把整个对话列表存入对话历史中去
      // 当然，要在占位消息之前
      saveToDb();

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

  saveToDb() async {
    print("处理插入前message的长度${messages.length}");
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid

    if (messages.isNotEmpty && messages.length == 1) {
      // 如果没有对话记录(即上层没有传入，且当前时用户第一次输入文字还没有创建对话记录)，则新建对话记录
      chatSession ??= ChatSession(
        uuid: const Uuid().v4(),
        title: messages.first.text.length > 30
            ? messages.first.text.substring(0, 30)
            : messages.first.text,
        gmtCreate: DateTime.now(),
        messages: messages,
        // 2024-06-01 暂时没用到
        llmName: widget.llmType,
      );

      print("这是输入了第一天消息，生成了初始化的对话$chatSession");

      print("进入了插入$chatSession");
      await _dbHelper.insertChatList([chatSession!]);

      // 如果已经有多个对话了，理论上该对话已经存入db了，只需要修改该对话的实际对话内容即可
    } else if (messages.length > 1) {
      chatSession!.messages = messages;

      print("进入了修改----$chatSession");

      await _dbHelper.updateChatSession(chatSession!);
    }

    // 其他没有对话记录、没有消息列表的情况，就不做任何处理了

    print("++++++++++++++++++++++++++++++");
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
      // 2024-06-03 有时候Chices里面还有note信息
      var tempContent = temp.choices!.first.message.content;
      tempText = tempContent;
      if (!tempContent.contains("以上内容为AI生成，不代表开发者立场，请勿删除或修改本标记")) {
        tempText = "$tempContent\n\n\n\n**${temp.note}**";
      }
    }
    _sendMessage(tempText, isFromUser: false);
  }

  /// 2024-05-31 暂时不根据token的返回来说了，临时直接显示整个对话不超过8千字
  bool isMessageTooLong() =>
      messages.fold(0, (sum, msg) => sum + msg.text.length) > 8000;

  /// 修改自动生成对话的标题
  updateChatTile() {
    setState(() {
      _titleController.text = chatSession!.title;
    });
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("修改对话标题:", style: TextStyle(fontSize: 20.sp)),
          content: TextField(
            controller: _titleController,
            maxLines: 3,
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
        var temp = chatSession!;
        temp.title = _titleController.text.trim();
        // 修改对话的标题
        _dbHelper.updateChatSession(temp);

        // 修改后更新标题
        setState(() {
          chatSession = temp;
        });

        // // 修改成功后重新查询更新(理论上不用重新查询应该也没问题)
        // var b = await _dbHelper.queryChatList(uuid: chatSession!.uuid);
        // setState(() {
        //   chatSession = b.first;
        // });
      }
    });
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();
      messages.add(placeholderMessage);

      // 不是腾讯，就是百度
      if (isErnie) {
        getErnieResponse();
      } else {
        getHunyuanResponse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 对话'),
        actions: [
          // TextButton(
          //   onPressed: () {
          //     // _dbHelper.deleteDB();
          //     _dbHelper.showTableNameList();
          //   },
          //   child: const Text("切换模型"),
          // ),

          /// 如果是百度千帆的模型，可以切换其他免费模型
          if (isErnie)
            DropdownButton<ErnieLLM>(
              value: defaultLlm,
              isDense: true,
              alignment: AlignmentDirectional.centerEnd,
              items: ErnieLLM.values
                  .map<DropdownMenuItem<ErnieLLM>>(
                    (ErnieLLM value) => DropdownMenuItem<ErnieLLM>(
                      value: value,
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        value.name,
                        style: TextStyle(fontSize: 10.sp),
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

          /// 创建新对话
          TextButton(
            onPressed: () {
              // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)？？？
              setState(() {
                chatSession = null;
                messages.clear();
              });
            },
            child: const Text("新对话"),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 如果对话是空，显示预设的问题
          if (messages.isEmpty) ..._buildDefaultQuestionArea(),

          /// 在顶部显示对话标题(避免在appbar显示，内容太挤)
          if (chatSession != null) _buildChatTitleArea(),

          // 标题和对话正文的分割线
          const Divider(),

          /// 显示对话消息主体
          _buildChatListArea(),

          /// 显示输入框和发送按钮
          const Divider(),
          _buildUserSendArea(),
        ],
      ),
    );
  }

  /// 直接进入对话页面，展示预设问题的区域
  _buildDefaultQuestionArea() {
    return [
      const Text("你可以试着问我(对话总长度建议不超过8000字)："),
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
                elevation: 2,
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
    ];
  }

  /// 对话的标题区域
  _buildChatTitleArea() {
    // 点击可修改标题
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          const Icon(Icons.title),
          SizedBox(width: 10.sp),
          Expanded(
            child: Text(
              '${(chatSession != null) ? chatSession?.title : '<暂未建立对话>'}',
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                // color: Theme.of(context).primaryColor,
              ),
              // textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56.sp,
            child: IconButton(
              onPressed: () {
                if (chatSession != null) {
                  updateChatTile();
                }
              },
              icon: Icon(
                Icons.edit,
                size: 18.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对话列表主体
  _buildChatListArea() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController, // 设置ScrollController
        // reverse: true, // 反转列表，使新消息出现在底部
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // 构建MessageItem
          return Padding(
              padding: EdgeInsets.all(5.sp),
              child: Column(
                children: [
                  MessageItem(message: messages[index]),
                  // 如果是大模型回复，可以有一些功能按钮
                  if (!messages[index].isFromUser)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 其中，是大模型最后一条回复，则可以重新生成
                        // 注意，还要排除占位消息
                        if ((index == messages.length - 1) &&
                            messages[index].isPlaceholder != true)
                          TextButton(
                            onPressed: () {
                              regenerateLatestQuestion();
                            },
                            child: const Text("重新生成"),
                          ),
                        // 点击复制该条回复
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: messages[index].text),
                            );

                            EasyLoading.showToast(
                              "已复制",
                              duration: const Duration(seconds: 3),
                              toastPosition: EasyLoadingToastPosition.center,
                            );
                          },
                          icon: Icon(Icons.copy, size: 20.sp),
                        ),
                        // 其他功能(占位)
                        IconButton(
                          onPressed: null,
                          icon: Icon(Icons.thumb_up_alt_outlined, size: 20.sp),
                        ),
                        IconButton(
                          onPressed: null,
                          icon: Icon(Icons.thumb_down_outlined, size: 20.sp),
                        ),
                      ],
                    )
                ],
              ));
        },
      ),
    );
  }

  /// 用户发送消息的区域
  _buildUserSendArea() {
    return Padding(
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

                      // 用户发送消息
                      _sendMessage(userInput);

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
    );
  }
}
