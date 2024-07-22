// ignore_for_file: avoid_print,

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/paid_cc_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/db_tools/db_helper.dart';
import '../../../../models/llm_chat_state.dart';
import '../../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../../models/paid_llm/common_chat_model_spec.dart';
import '../../_components/message_item.dart';
import 'user_send_area.dart';

/// 2024-07-22
/// 目前支持付费的rag只有零一万物，还有点贵
/// 就不开放了，且尽量简单点
///  平台: ApiPlatform.lingyiwanwu.name,
///  模型: CCM.YiLargeRag
///
/// 这个和 chat_bat_screen 有很多相似的代码，需要抽离
class AggregateSearch extends StatefulWidget {
  const AggregateSearch({super.key});

  @override
  State createState() => _AggregateSearchState();
}

class _AggregateSearchState extends State<AggregateSearch> {
  final DBHelper _dbHelper = DBHelper();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // 要修改某个对话的名称
  final TextEditingController _titleController = TextEditingController();

  // 要修改最近对话列表中指定的某个对话的名称
  final _selectedTitleController = TextEditingController();

  /// 级联选择效果：云平台-模型名
  ApiPlatform selectedPlatform = ApiPlatform.lingyiwanwu;
  CCM selectedLlm = CCM.YiLargeRag;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 2024-06-01 当前的对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  ChatSession? chatSession;

  // 最近对话需要的记录历史对话的变量
  List<ChatSession> chatHsitory = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    dateTime: DateTime.now(),
    role: "assistant",
    content: "正在全网搜索最新信息，请稍等……  ",
    isPlaceholder: true,
  );

  // 进入对话页面简单预设的一些问题
  List defaultQuestions = [
    "最近一周的10条国际大事要事新闻。",
    "查看一下今天A股的情况。",
    "搜索一下最近的计算机学科研成果，我希望我的数据来源足够专业。并帮我总结这5条科研成果的大致内容。",
  ];

  //获取指定分类的历史对话
  Future<List<ChatSession>> getHsitoryChats() async {
    // 获取历史记录：默认查询到所有的历史对话，再根据条件过滤(存的时候栏位要一致)
    var list = await _dbHelper.queryChatList(cateType: "rag");

    // 2024-07-22 目前只有零一万物
    list = list.where((e) => e.llmName == selectedLlm.name).toList();
    return list;
  }

  /// 获取指定对话列表
  _getChatInfo(String chatId) async {
    // 默认查询到所有的历史对话(这里有uuid了，应该就只有1条存在才对)
    // 2024-07-22 目前付费的rag只有零一万物
    var list = await _dbHelper.queryChatList(uuid: chatId, cateType: "rag");

    if (list.isNotEmpty && list.isNotEmpty) {
      setState(() {
        chatSession = list.first;
        selectedPlatform = ApiPlatform.lingyiwanwu;
        selectedLlm = CCM.YiLargeRag;

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;
      });
    }
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
  _sendMessage(
    String text, {
    String? role = "user",
    CCUsage? usage,
    List<CCQuote>? quotes,
  }) {
    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: role ?? "user",
      content: text,
      quotes: quotes,
      dateTime: DateTime.now(),
      inputTokens: usage?.promptTokens,
      outputTokens: usage?.completionTokens,
      totalTokens: usage?.totalTokens,
    );

    setState(() {
      // AI思考和用户输入是相反的(如果用户输入了，就是在等到机器回到了)
      isBotThinking = (role == "user");

      messages.add(temp);

      // 2024-06-01 注意，在每次添加了对话之后，都把整个对话列表存入对话历史中去
      // 当然，要在占位消息之前
      _saveToDb();

      _userInputController.clear();
      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      if (role == "user") {
        // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
        // 一定注意要记得AI响应后要删除此占位的消息
        placeholderMessage.dateTime = DateTime.now();
        messages.add(placeholderMessage);

        // 获取AI的响应
        _getLlmResponse();
      }
    });
  }

  // 保存对话到数据库
  _saveToDb() async {
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid

    if (messages.isNotEmpty && messages.length == 1) {
      // 如果没有对话记录(即上层没有传入，且当前时用户第一次输入文字还没有创建对话记录)，则新建对话记录
      chatSession ??= ChatSession(
        uuid: const Uuid().v4(),
        title: messages.first.content.length > 30
            ? messages.first.content.substring(0, 30)
            : messages.first.content,
        gmtCreate: DateTime.now(),
        messages: messages,
        // 2026-06-20 这里记录的自定义模型枚举的值，因为后续查询结果过滤有需要用来判断
        llmName: selectedLlm.name,
        cloudPlatformName: selectedPlatform.name,
        // 2026-06-06 对话历史默认带上类别
        chatType: "rag",
      );

      await _dbHelper.insertChatList([chatSession!]);

      // 如果已经有多个对话了，理论上该对话已经存入db了，只需要修改该对话的实际对话内容即可
    } else if (messages.length > 1) {
      chatSession!.messages = messages;

      await _dbHelper.updateChatSession(chatSession!);
    }

    // 其他没有对话记录、没有消息列表的情况，就不做任何处理了
  }

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getLlmResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<CCMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CCMessage(
              content: e.content,
              role: e.role,
            ))
        .toList();

    // 等待请求响应
    CCRespBody temp;
    //  这里一定要确保存在模型名称，因为要作为http请求参数
    var model = ccmSpecList[selectedLlm]!.model;

    // 2024-07-12 标题要大，不显示流式切换了，只有非流式的
    if (selectedPlatform == ApiPlatform.lingyiwanwu) {
      temp = await getChatResp(ApiPlatform.lingyiwanwu, msgs, model: model);
    } else {
      // 理论上不会存在其他的了
      temp = await getChatResp(ApiPlatform.lingyiwanwu, msgs, model: model);
    }

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中
    var tempText = temp.customReplyText;

    if (temp.error?.code != null) {
      if (!mounted) return;
      tempText = """AI大模型接口错误:
\ncode: ${temp.error?.code} 
\ntype: ${temp.error?.type} 
\nmessage: ${temp.error?.message}
""";
    }

    // 构建token使用数据
    var a = CCUsage(
      promptTokens: temp.usage?.promptTokens ?? 0,
      completionTokens: temp.usage?.completionTokens ?? 0,
      totalTokens: temp.usage?.totalTokens ?? 0,
    );

    // 如果是rag，保留引用数据
    List<CCQuote>? b = temp.choices?.first.quote;

    _sendMessage(tempText, role: "assistant", usage: a, quotes: b);
  }

  /// 2024-05-31 暂时不根据token的返回来说了，临时直接显示整个对话不超过8千字
  /// 限量的有放在对象里面
  bool isMessageTooLong() =>
      messages.fold(0, (sum, msg) => sum + msg.content.length) >
      ccmSpecList[selectedLlm]!.contextLength;

  /// 构建用于下拉的平台列表(根据上层传入的值)
  List<DropdownMenuItem<ApiPlatform?>> buildCloudPlatforms() {
    return ApiPlatform.values.toList().map((e) {
      return DropdownMenuItem<ApiPlatform?>(
        value: e,
        alignment: AlignmentDirectional.center,
        child: Text(
          paidCpNames[e]!,
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }).toList();
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(ApiPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedPlatform = value ?? ApiPlatform.lingyiwanwu;

      // 用于显示下拉的模型，也要根据入口来
      // 先找到符合平台的模型（？？？理论上一定不为空，为空了就是有问题的数据）
      var temp =
          CCM.values.where((e) => e.name == selectedPlatform.name).toList();

      setState(() {
        selectedLlm = temp.first;
        // 2024-06-15 切换平台或者模型应该清空当前对话，因为上下文丢失了。
        // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
        chatSession = null;
        messages.clear();
      });
    }
  }

  List<DropdownMenuItem<CCM>> buildPlatformLLMs() {
    // 这里是rag，模型仅是RAG结尾
    return CCM.values
        .where((m) => m.name.toLowerCase().endsWith("rag"))
        .toList()
        .map((e) => DropdownMenuItem<CCM>(
              value: e,
              alignment: AlignmentDirectional.center,
              child: Text(
                ccmSpecList[e]!.name,
                style: const TextStyle(color: Colors.blue),
              ),
            ))
        .toList();
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  /// 2024-06-20 限量的要计算token数量，所以不让重新生成(？？？但实际也没做累加的token的逻辑)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      _getLlmResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppbarArea(),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 构建可切换云平台和模型的行
            Container(
              color: Colors.grey[300],
              child: Padding(
                padding: EdgeInsets.only(left: 10.sp),
                child: buildPlatAndLlmRow(),
              ),
            ),

            /// 如果对话是空，显示预设的问题
            if (messages.isEmpty) ...buildDefaultQuestionArea(),

            /// 在顶部显示对话标题(避免在appbar显示，内容太挤)
            if (chatSession != null) buildChatTitleArea(),

            /// 标题和对话正文的分割线
            if (chatSession != null) Divider(height: 3.sp, thickness: 1.sp),

            /// 显示对话消息主体
            buildChatListArea(),

            /// 显示输入框和发送按钮
            const Divider(),
            // buildUserSendArea(),
            UserSendArea(
              controller: _userInputController,
              hintText: '可以向我提任何问题哦',
              isBotThinking: isBotThinking,
              userInput: userInput,
              onChanged: (text) {
                setState(() {
                  userInput = text.trim();
                });
              },
              onSendPressed: () {
                _sendMessage(userInput);
                setState(() {
                  userInput = "";
                });
              },
              isMessageTooLong: isMessageTooLong, // 修改这里
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            SizedBox(
              // 调整DrawerHeader的高度
              height: 100.sp,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.lightGreen),
                child: Center(
                  child: Text(
                    '最近对话',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            ...(chatHsitory.map((e) => buildGestureItems(e)).toList()),
          ],
        ),
      ),
    );
  }

  /// 构建appbar区域
  buildAppbarArea() {
    return AppBar(
      title: const Text('全网搜索'),
      actions: [
        /// 创建新对话
        IconButton(
          onPressed: () {
            // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)？？？
            setState(() {
              chatSession = null;
              messages.clear();
            });
          },
          icon: const Icon(Icons.add),
        ),
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.history),
              onPressed: () async {
                // 获取历史记录：默认查询到所有的历史对话，再根据条件过滤
                var list = await getHsitoryChats();
                // 显示最近的对话

                setState(() {
                  chatHsitory = list;
                });

                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Scaffold.of(context).openEndDrawer();
              },
            );
          },
        ),
      ],
    );
  }

  /// 构建在对话历史中的对话标题列表
  buildGestureItems(ChatSession e) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // 点击了知道历史对话，则替换当前对话
        setState(() {
          _getChatInfo(e.uuid);
        });
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
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat(constDatetimeFormat).format(e.gmtCreate),
                      style: TextStyle(fontSize: 12.sp),
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

  _buildDeleteBotton(ChatSession e) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("确认删除对话记录:"),
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
              await _dbHelper.deleteChatById(e.uuid);

              // 然后重新查询并更新
              var list = await getHsitoryChats();

              setState(() {
                chatHsitory = list;
              });

              // 2024-06-11 如果删除的历史对话，就是当前对话，那就要跳到新开对话页面
              if (chatSession?.uuid == e.uuid) {
                setState(() {
                  chatSession = null;
                  messages.clear();
                });
              }
            }
          });
        },
        icon: Icon(
          Icons.delete,
          color: Theme.of(context).primaryColor,
        ),
        padding: EdgeInsets.all(0.sp),
      ),
    );
  }

  _buildUpdateBotton(ChatSession e) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          setState(() {
            _selectedTitleController.text = e.title;
          });
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("修改对话记录标题:", style: TextStyle(fontSize: 18.sp)),
                content: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  controller: _selectedTitleController,
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
              temp.title = _selectedTitleController.text.trim();
              // 修改对话的标题
              _dbHelper.updateChatSession(temp);

              // 修改成功后重新查询更新
              var list = await getHsitoryChats();

              setState(() {
                chatHsitory = list;
              });
            }
          });
        },
        icon: Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// 修改当前正在对话的自动生成对话的标题
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
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

  /// 构建切换平台和模型的行
  buildPlatAndLlmRow() {
    Widget cpRow = Row(
      children: [
        const Text("平台:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<ApiPlatform?>(
            value: selectedPlatform,
            isDense: true,
            // icon: Icon(Icons.arrow_drop_down, size: 36.sp), // 自定义图标
            underline: Container(), // 取消默认的下划线
            // alignment: AlignmentDirectional.center,
            items: buildCloudPlatforms(),
            onChanged: onCloudPlatformChanged,
          ),
        ),
      ],
    );

    Widget modelRow = Row(
      children: [
        const Text("模型:"),
        SizedBox(width: 10.sp),
        Expanded(
          // 下拉框有个边框，需要放在容器中
          // child: Container(
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey, width: 1.0),
          //     borderRadius: BorderRadius.circular(4),
          //   ),
          child: DropdownButton<CCM?>(
            value: selectedLlm,
            isDense: true,
            underline: Container(),
            // alignment: AlignmentDirectional.center,
            menuMaxHeight: 300.sp,
            items: buildPlatformLLMs(),
            onChanged: (val) {
              setState(() {
                selectedLlm = val!;
                // 2024-06-15 切换模型应该新建对话，因为上下文丢失了。
                // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
                chatSession = null;
                messages.clear();
              });
            },
          ),
        ),
        // ),
        IconButton(
          onPressed: () {
            commonHintDialog(
              context,
              "模型说明",
              "${ccmSpecList[selectedLlm]!.feature ?? ""}\n\n${ccmSpecList[selectedLlm]!.useCase ?? ""}",
              msgFontSize: 15.sp,
            );
          },
          icon: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [cpRow, modelRow],
      ),
    );
  }

  /// 直接进入对话页面，展示预设问题的区域
  buildDefaultQuestionArea() {
    return [
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
      ),
      Expanded(
        flex: 2,
        child: ListView.builder(
          itemCount: defaultQuestions.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 2,
              child: ListTile(
                title: Text(
                  defaultQuestions[index],
                  style: const TextStyle(color: Colors.blue),
                ),
                trailing: const Icon(Icons.touch_app, color: Colors.blue),
                onTap: () {
                  _sendMessage(defaultQuestions[index]);
                },
              ),
            );
          },
        ),
      ),
    ];
  }

  /// 对话的标题区域
  buildChatTitleArea() {
    // 点击可修改标题
    return Padding(
      padding: EdgeInsets.all(1.sp),
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
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对话列表主体
  buildChatListArea() {
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
                if (messages[index].role == 'assistant')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 其中，是大模型最后一条回复，则可以重新生成
                      // 注意，还要排除占位消息
                      // 限量的没有重新生成，因为不好计算tokens总数
                      if ((index == messages.length - 1) &&
                          messages[index].isPlaceholder != true)
                        TextButton(
                          onPressed: () {
                            regenerateLatestQuestion();
                          },
                          child: const Text("重新生成"),
                        ),

                      // 如果不是等待响应才可以点击复制该条回复
                      if (messages[index].isPlaceholder != true)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: messages[index].content),
                            );

                            EasyLoading.showToast(
                              "已复制到剪贴板",
                              duration: const Duration(seconds: 3),
                              toastPosition: EasyLoadingToastPosition.center,
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),

                      SizedBox(width: 10.sp),

                      // 如果不是等待响应才显示token数量
                      if (messages[index].isPlaceholder != true)
                        Text(
                          "tokens 输入:${messages[index].inputTokens} 输出:${messages[index].outputTokens} 总计:${messages[index].totalTokens}",
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      SizedBox(width: 10.sp),
                    ],
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  /// 用户发送消息的区域
  buildUserSendArea() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _userInputController,

              decoration: const InputDecoration(
                hintText: '可以向我提任何问题哦',
                border: OutlineInputBorder(),
              ),
              // ？？？2024-07-14 如果屏幕太小，键盘弹出来之后挤占屏幕高度，这里可能会出现溢出问题
              maxLines: 2,
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
