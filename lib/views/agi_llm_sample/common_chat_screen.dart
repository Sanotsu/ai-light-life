// ignore_for_file: avoid_print,

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:uuid/uuid.dart';

import '../../apis/aliyun_apis.dart';
import '../../apis/baidu_apis.dart';
import '../../apis/tencent_apis.dart';
import '../../common/components/tool_widget.dart';
import '../../common/constants.dart';
import '../../models/common_llm_info.dart';
import '../../common/utils/db_helper.dart';
import '../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../models/llm_chat_state.dart';

import 'widgets/message_item.dart';

class CommonChatScreen extends StatefulWidget {
  const CommonChatScreen({super.key});

  @override
  State createState() => _CommonChatScreenState();
}

class _CommonChatScreenState extends State<CommonChatScreen> {
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
  CloudPlatform selectedCloudPlatform = CloudPlatform.baidu;
  PlatformLLM selectedLlm = PlatformLLM.baiduErnieSpeed8K;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 2024-06-11 默认使用流式请求，更快;但是同样的问题，流式使用的token会比非流式更多
  bool isStream = true;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 2024-06-01 当前的对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  ChatSession? chatSession;

  // 最近对话需要的记录历史对话的变量
  List<ChatSession> chatHsitory = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    text: "努力思考中(等待越久,回复内容越多)  ",
    isFromUser: false,
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  // 进入对话页面简单预设的一些问题
  List defaultQuestions = [
    "老板经常以未达到工作考核来克扣工资，经常让我无偿加班，是否已经违法？",
    "你好，介绍一下你自己。",
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

  /// 获取指定对话列表
  _getChatInfo(String chatId) async {
    print("调用了getChatInfo----------");
    var list = await _dbHelper.queryChatList(uuid: chatId, cateType: "aigc");

    if (list.isNotEmpty && list.isNotEmpty) {
      setState(() {
        chatSession = list.first;

        // 如果有存是哪个模型，也默认选中该模型
        // ？？？2024-06-11 虽然同一个对话现在可以切换平台和模型了，但这里只是保留第一次对话取的值
        // 后面对话过程中切换平台和模型，只会在该次对话过程中有效
        var tempLlms = llmModels.entries
            .where((e) => e.value == list.first.llmName)
            .toList();

        var tempCps = CloudPlatform.values
            .where((e) => e.name.contains(list.first.cloudPlatformName ?? ""))
            .toList();

        // 避免麻烦，两个都不为空才显示；否则还是预设的
        if (tempLlms.isNotEmpty && tempCps.isNotEmpty) {
          selectedLlm = tempLlms.first.key;
          selectedCloudPlatform = tempCps.first;
        }

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;
      });
    }
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
  _sendMessage(String text, {bool isFromUser = true}) {
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
      _saveToDb();

      _userInputController.clear();
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
        placeholderMessage.dateTime = DateTime.now();
        messages.add(placeholderMessage);

        // 不是腾讯，就是百度
        _getLlmResponse();
      }
    });
  }

  // 保存对话到数据库
  _saveToDb() async {
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
        // 2026-06-06 这里记录的也是各平台原始的大模型名称
        llmName: llmModels[selectedLlm]!,
        cloudPlatformName: selectedCloudPlatform.name,
        // 2026-06-06 对话历史默认带上类别
        chatType: "aigc",
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

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getLlmResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<CommonMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CommonMessage(
              content: e.text,
              role: e.isFromUser ? "user" : "assistant",
            ))
        .toList();

    // 等待请求响应
    List<CommonRespBody> temp;
    var llmName = llmModels[selectedLlm]!;

    print("llmNames[selectedLlm]!----$llmName");
    // 2024-06-06 ??? 这里一定要确保存在模型名称，因为要作为http请求参数
    // 2024-06-11 如果是用户切换了“更快”或“更多”，则使用不同的请求
    if (isStream) {
      if (selectedCloudPlatform == CloudPlatform.baidu) {
        temp = await getBaiduAigcStreamCommonResp(msgs, model: llmName);
      } else if (selectedCloudPlatform == CloudPlatform.tencent) {
        temp = await getTencentAigcStreamCommonResp(msgs, model: llmName);
      } else if (selectedCloudPlatform == CloudPlatform.aliyun) {
        temp = await getAliyunAigcStreamCommonResp(msgs, model: llmName);
      } else {
        temp = await getTencentAigcStreamCommonResp(msgs);
      }
    } else {
      if (selectedCloudPlatform == CloudPlatform.baidu) {
        temp = [await getBaiduAigcCommonResp(msgs, model: llmName)];
      } else if (selectedCloudPlatform == CloudPlatform.tencent) {
        temp = [await getTencentAigcCommonResp(msgs, model: llmName)];
      } else if (selectedCloudPlatform == CloudPlatform.aliyun) {
        // 2024-06-11 注意，测试阿里云非流式响应结果是空字符串，原因不明，所以非流也暂时使用流式请求
        // temp = [await getAliyunAigcCommonResp(msgs, model: llmName)];
        temp = await getAliyunAigcStreamCommonResp(msgs, model: llmName);
      } else {
        temp = [await getTencentAigcCommonResp(msgs)];
      }
    }

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    var tempText = temp.map((e) => e.customReplyText).join();
    if (temp.isNotEmpty && temp.first.errorCode != null) {
      tempText =
          "API接口报错: {${temp.first.errorCode}: ${temp.first.errorMsg}}，请切换其他模型试试。";
    }

    _sendMessage(tempText, isFromUser: false);
  }

  /// 2024-05-31 暂时不根据token的返回来说了，临时直接显示整个对话不超过8千字
  bool isMessageTooLong() =>
      messages.fold(0, (sum, msg) => sum + msg.text.length) > 8000;

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(CloudPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedCloudPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedCloudPlatform = value ?? CloudPlatform.baidu;

      // 找到符合平台的模型（？？？理论上一定不为空，为空了就是有问题的数据）
      var temp = PlatformLLM.values
          .where((e) => e.name.startsWith(selectedCloudPlatform.name))
          .toList();

      setState(() {
        selectedLlm = temp.first;
      });
    }
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
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

            // 标题和对话正文的分割线
            const Divider(),

            /// 显示对话消息主体
            buildChatListArea(),

            /// 显示输入框和发送按钮
            const Divider(),
            buildUserSendArea(),
          ],
        ),
      ),
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

  /// 构建appbar区域
  buildAppbarArea() {
    return AppBar(
      title: Text(
        '智能对话',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      actions: [
        /// 选择“更快”就使用流式请求，否则就一般的非流式
        ToggleSwitch(
          minHeight: 24.sp,
          minWidth: 42.sp,
          fontSize: 10.sp,
          cornerRadius: 5.sp,
          dividerMargin: 0.sp,
          // isVertical: true,
          // // 激活时按钮的前景背景色
          // activeFgColor: Colors.black,
          // activeBgColor: [Colors.green],
          // // 未激活时的前景背景色
          // inactiveBgColor: Colors.grey,
          // inactiveFgColor: Colors.white,
          initialLabelIndex: isStream ? 0 : 1,
          totalSwitches: 2,
          labels: const ['更快', '更多'],
          // radiusStyle: true,
          onToggle: (index) {
            setState(() {
              isStream = index == 0 ? true : false;
            });
          },
        ),
        SizedBox(width: 20.sp),

        /// 创建新对话
        IconButton(
          onPressed: () {
            // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)？？？
            setState(() {
              chatSession = null;
              messages.clear();
            });
          },
          icon: Icon(Icons.add, size: 24.sp),
        ),
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.history, size: 24.sp),
              onPressed: () async {
                // 获取历史记录
                var a = await _dbHelper.queryChatList(cateType: "aigc");
                setState(() {
                  chatHsitory = a;
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
                      style: TextStyle(fontSize: 12.sp),
                      maxLines: 2,
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
              await _dbHelper.deleteChatById(e.uuid);

              // 然后重新查询并更新
              var b = await _dbHelper.queryChatList(cateType: 'aigc');
              setState(() {
                chatHsitory = b;
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
          size: 16.sp,
          color: Theme.of(context).primaryColor,
        ),
        iconSize: 18.sp,
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
              var b = await _dbHelper.queryChatList(cateType: "aigc");
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("平台:"),
        SizedBox(width: 10.sp),
        SizedBox(
          width: 52.sp,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<CloudPlatform?>(
              value: selectedCloudPlatform,
              isDense: true,
              alignment: AlignmentDirectional.center,
              items: CloudPlatform.values.map((e) {
                return DropdownMenuItem<CloudPlatform?>(
                  value: e,
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    cpNames[e]!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                  ),
                );
              }).toList(),
              onChanged: onCloudPlatformChanged,
            ),
          ),
        ),

        const Text("模型:"),
        SizedBox(width: 10.sp),
        Expanded(
          // 下拉框有个边框，需要放在容器中
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<PlatformLLM?>(
              value: selectedLlm,
              isDense: true,
              alignment: AlignmentDirectional.centerEnd,
              items: PlatformLLM.values
                  .where((m) => m.name.startsWith(selectedCloudPlatform.name))
                  .map((e) => DropdownMenuItem<PlatformLLM>(
                        value: e,
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          llmNames[e]!,
                          style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedLlm = val!;
                });
              },
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            commonHintDialog(
              context,
              "模型说明",
              llmDescriptions[selectedLlm] ?? "",
            );
          },
          icon: Icon(Icons.help, size: 18.sp),
          iconSize: 20.sp,
        ),
        //
      ],
    );
  }

  /// 直接进入对话页面，展示预设问题的区域
  buildDefaultQuestionArea() {
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
  buildChatTitleArea() {
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
                // 如果是最后一个回复的文本，使用打字机特效
                // if (index == messages.length - 1)
                //   TypewriterText(text: messages[index].text),
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
                            "已复制到剪贴板",
                            duration: const Duration(seconds: 3),
                            toastPosition: EasyLoadingToastPosition.center,
                          );
                        },
                        icon: Icon(Icons.copy, size: 20.sp),
                      ),
                      // // 其他功能(占位)
                      // IconButton(
                      //   onPressed: null,
                      //   icon: Icon(Icons.thumb_up_alt_outlined, size: 20.sp),
                      // ),
                      // IconButton(
                      //   onPressed: null,
                      //   icon: Icon(Icons.thumb_down_outlined, size: 20.sp),
                      // ),
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
