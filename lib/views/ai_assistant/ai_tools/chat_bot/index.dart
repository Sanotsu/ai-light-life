// ignore_for_file: avoid_print,

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/common_chat_apis.dart';
import '../../../../common/constants.dart';
import '../../../../common/db_tools/db_helper.dart';
import '../../../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../../../models/common_llm_info.dart';
import '../../../../models/llm_chat_state.dart';
import '../../_chat_screen_parts/chat_appbar_area.dart';
import '../../_chat_screen_parts/chat_history_drawer.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_plat_and_llm_area.dart';
import '../../_chat_screen_parts/chat_title_area.dart';
import '../../_chat_screen_parts/chat_default_question_area.dart';
import '../../_chat_screen_parts/chat_user_send_area.dart';

/// 2024-07-16
/// 这个应该会复用，后续抽出chatbatindex出来
/// 2024-07-23
/// 页面中各个布局的部件已经抽出来了，放在lib/views/ai_assistant/_chat_screen_parts
///   目前已经重构的页面：
///     lib/views/ai_assistant/ai_tools/chat_bot/index.dart
///     lib/views/ai_assistant/ai_tools/aggregate_search/index.dart
///
///
class ChatBat extends StatefulWidget {
  // 默认只展示FREE结尾的免费模型，且不用用户配置

  const ChatBat({super.key});

  @override
  State createState() => _ChatBatState();
}

class _ChatBatState extends State<ChatBat> {
  final DBHelper _dbHelper = DBHelper();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  /// 级联选择效果：云平台-模型名
  /// 2024-06-15 这里限量的，暂时都是阿里云平台的，但单独取名limited？？？
  /// 也没有其他可修改的地方
  CloudPlatform selectedPlatform = CloudPlatform.limited;
  PlatformLLM selectedLlm = PlatformLLM.limitedYiLarge;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  /// 2024-06-11 默认使用流式请求，更快;但是同样的问题，流式使用的token会比非流式更多
  /// 2024-06-15 限时限量的可能都是收费的，本来就慢，所以默认就流式，不用切换
  /// 2024-06-20 流式使用的token太多了，还是默认更省的
  bool isStream = false;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 2024-06-01 当前的对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  ChatSession? chatSession;

  // 最近对话需要的记录历史对话的变量
  List<ChatSession> chatHistory = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    dateTime: DateTime.now(),
    role: "assistant",
    content: "努力思考中，请耐心等待  ",
    isPlaceholder: true,
  );

  // 进入对话页面简单预设的一些问题
  List<String> defaultQuestions = defaultChatQuestions;

  @override
  void initState() {
    super.initState();

    initCusConfig();
  }

  // 进入自行配置的对话页面，看看用户配置有没有生效
  initCusConfig() {
    // 2024-07-14 每次进来都随机选一个(注意：不能有limited的那个，因为那个没有FREE结尾的)
    List<CloudPlatform> values = CloudPlatform.values
        .where((platform) => platform != CloudPlatform.limited)
        .toList();
    selectedPlatform = values[Random().nextInt(values.length)];

    setState(() {
      // 2024-07-14 同样的，选中的平台后也随机选择一个模型
      List<PlatformLLM> models = PlatformLLM.values
          .where((m) =>
              m.name.startsWith(selectedPlatform.name) &&
              m.name.endsWith("FREE"))
          .toList();

      selectedLlm = models[Random().nextInt(models.length)];
    });

    // print("配置选中后的平台和模型");
    // print("$selectedPlatform $selectedLlm");
  }

  //获取指定分类的历史对话
  Future<List<ChatSession>> getHistoryChats() async {
    // 获取历史记录：默认查询到所有的历史对话，再根据条件过滤
    var list = await _dbHelper.queryChatList(cateType: "aigc");

    // 默认就是免费的了，平台非limited，模型仅是FREE结尾
    list = list
        .where((e) =>
            e.cloudPlatformName != CloudPlatform.limited.name &&
            e.llmName.endsWith("FREE"))
        .toList();

    return list;
  }

  /// 获取指定对话列表
  _getChatInfo(String chatId) async {
    // 默认查询到所有的历史对话(这里有uuid了，应该就只有1条存在才对)
    var list = await _dbHelper.queryChatList(uuid: chatId, cateType: "aigc");

    // 默认就是免费的了，平台非limited，模型仅是FREE结尾
    list = list
        .where((e) =>
            e.cloudPlatformName != CloudPlatform.limited.name &&
            e.llmName.endsWith("FREE"))
        .toList();

    if (list.isNotEmpty && list.isNotEmpty) {
      // 2024-07-23 注意！！！这里要处理该条历史记录中的消息列表，具体看_sendMessage中的说明
      List<ChatMessage> resultList =
          filterAlternatingRoles(list.first.messages);

      // 注意，如果遍历结束，但只剩下一条role为user的消息列表，则补一个占位消息
      if (resultList.length == 1 && resultList.first.role == "user") {
        resultList.add(ChatMessage(
          messageId: "retry",
          dateTime: DateTime.now(),
          role: "assistant",
          content: "问题回答已遗失，请重新提问",
          isPlaceholder: false,
        ));
      }

      setState(() {
        chatSession = list.first;
        chatSession?.messages = resultList;

        // 如果有存是哪个模型，也默认选中该模型
        // ？？？2024-06-11 虽然同一个对话现在可以切换平台和模型了，但这里只是保留第一次对话取的值
        // 后面对话过程中切换平台和模型，只会在该次对话过程中有效
        var tempLlms = newLLMSpecs.entries
            // 数据库存的模型名就是自定义的模型名
            .where((e) => e.key.name == list.first.llmName)
            .toList();

        // 被选中的平台也就是记录中存放的平台
        var tempCps = CloudPlatform.values
            .where((e) => e.name.contains(list.first.cloudPlatformName ?? ""))
            .toList();

        // 避免麻烦，两个都不为空才显示；否则还是预设的
        if (tempLlms.isNotEmpty && tempCps.isNotEmpty) {
          selectedLlm = tempLlms.first.key;
          selectedPlatform = tempCps.first;
        }

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;
      });
    }
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
  _sendMessage(String text, {String? role = "user", CommonUsage? usage}) {
    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: role ?? "user",
      content: text,
      dateTime: DateTime.now(),
      inputTokens: usage?.inputTokens,
      outputTokens: usage?.outputTokens,
      totalTokens: usage?.totalTokens,
    );

    if (!mounted) return;
    setState(() {
      // AI思考和用户输入是相反的(如果用户输入了，就是在等到机器回到了)
      isBotThinking = (role == "user");

      messages.add(temp);

      // 2024-06-01 注意，在每次添加了对话之后，都把整个对话列表存入对话历史中去
      // 当然，要在占位消息之前
      // 2024-07-23 有个问题：用户发送了消息，等待AI响应时，退出页面。
      // 此时历史记录中就存在了等待中的数据，而响应返回的不会处理、占位的数据就无法清除
      // 不过继续询问后占位的还是会被清除。
      // ！！！但如果像百度接口role必须user、assistant 交替的奇数消息列表，就会报错。
      //    因为这里是user、(assistant没放到列表)、user，两个连续的user偶数列表
      //    也就是说，该历史对话，无法继续对话了
      // 对策：点击指定历史记录，如果最后一条不是assistant，就删除，直到是assistant
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

        // 不是腾讯，就是百度
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
        chatType: "aigc",
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
    List<CommonMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CommonMessage(
              content: e.content,
              role: e.role,
            ))
        .toList();

    // 等待请求响应
    List<CommonRespBody> temp;
    // 2024-06-06 ??? 这里一定要确保存在模型名称，因为要作为http请求参数
    var model = newLLMSpecs[selectedLlm]!.model;

    // 2024-07-12 标题要大，不显示流式切换了，只有非流式的
    if (selectedPlatform == CloudPlatform.baidu) {
      temp = await getBaiduAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    } else if (selectedPlatform == CloudPlatform.tencent) {
      temp = await getTencentAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    } else if (selectedPlatform == CloudPlatform.aliyun) {
      temp = await getAliyunAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    } else if (selectedPlatform == CloudPlatform.limited) {
      // 目前限时限量的，其实也只是阿里云平台的
      temp = await getAliyunAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    } else if (selectedPlatform == CloudPlatform.siliconCloud) {
      // 2024-07-04 新加硅动科技siliconFlow中免费的
      temp = await getSiliconFlowAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    } else {
      // 理论上不会存在其他的了
      temp = await getBaiduAigcResp(msgs,
          model: model, stream: isStream, isUserConfig: false);
    }

    // 得到回复后要删除表示加载中的占位消息
    if (!mounted) return;
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    var tempText = temp.map((e) => e.customReplyText).join();
    if (temp.isNotEmpty && temp.first.errorCode != null) {
      tempText = """接口报错:
\ncode:${temp.first.errorCode} 
\nmsg:${temp.first.errorMsg}
\n请检查AppId和AppKey是否正确，或切换其他模型试试。
""";
    }

    // 每次对话的结果流式返回，所以是个列表，就需要累加起来
    int inputTokens = 0;
    int outputTokens = 0;
    int totalTokens = 0;
    for (var e in temp) {
      inputTokens += e.usage?.inputTokens ?? e.usage?.promptTokens ?? 0;
      outputTokens += e.usage?.outputTokens ?? e.usage?.completionTokens ?? 0;
      totalTokens += e.usage?.totalTokens ?? 0;
    }
    // 里面的promptTokens和completionTokens是百度这个特立独行的，在上面拼到一起了
    var a = CommonUsage(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
    );

    _sendMessage(tempText, role: "assistant", usage: a);
  }

  /// 2024-05-31 暂时不根据token的返回来说了，临时直接显示整个对话不超过8千字
  /// 限量的有放在对象里面
  bool isMessageTooLong() =>
      messages.fold(0, (sum, msg) => sum + msg.content.length) >
      newLLMSpecs[selectedLlm]!.contextLength;

  /// 构建用于下拉的平台列表(根据上层传入的值)
  List<DropdownMenuItem<CloudPlatform?>> buildCloudPlatforms() {
    return CloudPlatform.values
        .where((e) => e != CloudPlatform.limited)
        .toList()
        .map((e) {
      return DropdownMenuItem<CloudPlatform?>(
        value: e,
        alignment: AlignmentDirectional.center,
        child: Text(
          cpNames[e]!,
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }).toList();
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(CloudPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedPlatform = value ?? CloudPlatform.baidu;

      // 用于显示下拉的模型，也要根据入口来
      // 先找到符合平台的模型（？？？理论上一定不为空，为空了就是有问题的数据）
      var temp = PlatformLLM.values
          .where((e) => e.name.startsWith(selectedPlatform.name))
          .toList();

      // 默认就是免费的了，模型仅是FREE结尾
      temp = temp.where((e) => e.name.endsWith("FREE")).toList();

      setState(() {
        selectedLlm = temp.first;
        // 2024-06-15 切换平台或者模型应该清空当前对话，因为上下文丢失了。
        // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
        chatSession = null;
        messages.clear();
      });
    }
  }

  List<DropdownMenuItem<PlatformLLM>> buildPlatformLLMs() {
    // 用于下拉的模型首先是需要以平台前缀命名的
    var llms = PlatformLLM.values
        .where((m) => m.name.startsWith(selectedPlatform.name));

    text(ChatLLMSpec e) => e.name;

    // 默认就是免费的了，模型仅是指定平台前缀+以FREE结尾
    llms = llms.where((m) => m.name.endsWith("FREE")).toList();

    return llms
        .map((e) => DropdownMenuItem<PlatformLLM>(
              value: e,
              alignment: AlignmentDirectional.center,
              child: Text(
                text(newLLMSpecs[e]!),
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
      appBar: ChatAppBarArea(
        title: '你问我答',
        onNewChatPressed: () {
          setState(() {
            chatSession = null;
            messages.clear();
          });
        },
        onHistoryPressed: (BuildContext context) async {
          var list = await getHistoryChats();
          setState(() {
            chatHistory = list;
          });
          if (!context.mounted) return;
          Scaffold.of(context).openEndDrawer();
        },
      ),
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
                child: PlatAndLlmRow<CloudPlatform, PlatformLLM>(
                  selectedPlatform: selectedPlatform,
                  onCloudPlatformChanged: onCloudPlatformChanged,
                  selectedLlm: selectedLlm,
                  onLlmChanged: (val) {
                    setState(() {
                      selectedLlm = val!;
                      // 2024-06-15 切换模型应该新建对话，因为上下文丢失了。
                      // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
                      chatSession = null;
                      messages.clear();
                    });
                  },
                  buildCloudPlatforms: buildCloudPlatforms,
                  buildPlatformLLMs: buildPlatformLLMs,
                  specList: newLLMSpecs,
                  showToggleSwitch: true,
                  isStream: isStream,
                  onToggle: (index) {
                    setState(() {
                      isStream = index == 0 ? true : false;
                    });
                  },
                ),
              ),
            ),

            /// 如果对话是空，显示预设的问题
            // 预设的问题标题
            if (messages.isEmpty)
              Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
              ),
            // 预设的问题列表
            if (messages.isEmpty)
              ChatDefaultQuestionArea(
                defaultQuestions: defaultQuestions,
                onQuestionTap: _sendMessage,
              ),

            /// 对话的标题区域
            /// 在顶部显示对话标题(避免在appbar显示，内容太挤)
            if (chatSession != null)
              ChatTitleArea(
                chatSession: chatSession,
                onUpdate: (ChatSession e) async {
                  // 修改对话的标题
                  await _dbHelper.updateChatSession(e);

                  // 修改后更新标题
                  setState(() {
                    chatSession = e;
                  });
                },
              ),

            /// 标题和对话正文的分割线
            if (chatSession != null) Divider(height: 3.sp, thickness: 1.sp),

            /// 显示对话消息主体
            ChatListArea(
              messages: messages,
              scrollController: _scrollController,
              regenerateLatestQuestion: regenerateLatestQuestion,
            ),

            /// 显示输入框和发送按钮
            const Divider(),

            /// 用户发送区域
            ChatUserSendArea(
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
              isMessageTooLong: isMessageTooLong,
            ),
          ],
        ),
      ),

      /// 构建在对话历史中的对话标题列表
      endDrawer: ChatHistoryDrawer(
        chatHistory: chatHistory,
        onTap: (ChatSession e) {
          Navigator.of(context).pop();
          // 点击了知道历史对话，则替换当前对话
          setState(() {
            _getChatInfo(e.uuid);
          });
        },
        onUpdate: (ChatSession e) async {
          // 修改对话的标题
          await _dbHelper.updateChatSession(e);
          // 修改成功后重新查询更新
          var list = await getHistoryChats();
          setState(() {
            chatHistory = list;
          });
        },
        onDelete: (ChatSession e) async {
          // 先删除
          await _dbHelper.deleteChatById(e.uuid);
          // 然后重新查询并更新
          var list = await getHistoryChats();
          setState(() {
            chatHistory = list;
          });
          // 如果删除的历史对话是当前对话，跳到新开对话页面
          if (chatSession?.uuid == e.uuid) {
            setState(() {
              chatSession = null;
              messages.clear();
            });
          }
        },
      ),
    );
  }
}
