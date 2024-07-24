// ignore_for_file: avoid_print,

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/common_chat_apis.dart';
import '../../../../apis/paid_cc_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../../../models/common_llm_info.dart';
import '../../../../models/llm_chat_state.dart';
import '../../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../../models/paid_llm/common_chat_model_spec.dart';
import '../../_chat_screen_parts/chat_default_question_area.dart';
import '../../_chat_screen_parts/chat_user_send_area.dart';
import 'message_list_widget.dart';
import 'multi_select_dialog.dart';

/// 2024-07-23
/// 这个初衷是：
///   1 用户选中几个大模型
///   2 用户问一个问题，然后被选中的大模型依次回答问题
///   3 用户继续询问，各个模型根据自己的上下文继续问答问题
///   4 用户可以【保存】对话，下次进入时，可以恢复对话（这个和之前的设计差别挺大，暂时不做）
///
class ChatBatGroup extends StatefulWidget {
  const ChatBatGroup({super.key});

  @override
  State createState() => _ChatBatGroupState();
}

class _ChatBatGroupState extends State<ChatBatGroup> {
  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 2024-07-23 对话现在需要考虑更多
  // 用户输入、AI响应、不同平台的消息要单独分开、等待错误重试等占位
  // map的key为模型名，value为该模型的消息列表
  Map<String, List<ChatMessage>> msgMap = {};

  // 2024-07-24 用于在一个列表中显示的消息对话
  List<ChatMessage> messages = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    dateTime: DateTime.now(),
    role: "assistant",
    content: "努力思考中，请耐心等待  ",
    isPlaceholder: true,
  );

  // 进入对话页面简单预设的一些问题
  List<String> defaultQuestions = chatQuestionSamples;

  ///==============
  // 2024-07-23 这里纯粹是为了方便，把enLable存平台的名称，用于区分需要调用的接口函数
  final List<CusLabel> _allItems = BATTLE_MODEL_LIST;

  List<CusLabel> _selectedItems = [];

  // 如果选中的对比模型是2个，且启用对战模式，才上下两个列表分别显示各自模型的对话
  // 否则就是一个用户输入，下面多个AI回复
  bool isBattleMode = false;

  @override
  void initState() {
    super.initState();

    _selectedItems = [_allItems[0], _allItems[2]];
  }

  // 先多选了几个模型，发送后，每个模型都要调用
  _userSendMessage(String text) {
    // 用户发送了消息，只需要加入一次
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: "user",
      content: text,
      dateTime: DateTime.now(),
    );
    setState(() {
      messages.add(temp);
    });

    // 每个模型处理各自的
    for (var e in _selectedItems) {
      separatelyHandleMessage(text, e, role: "user");
    }
  }

  // 用户发送消息、或者AI响应后的消息，都要添加到对话列表中共显示
  separatelyHandleMessage(
    String text,
    CusLabel e, {
    String? role = "user",
    CommonUsage? usage,
  }) {
    String model = "";
    if (e.value.runtimeType == ChatLLMSpec) {
      var spec = e.value as ChatLLMSpec;
      model = spec.model;
    } else {
      var spec = e.value as CCMSpec;
      model = spec.model;
    }

    print("separatelyHandleMessage---$model $role");

    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: role ?? "user",
      content: text,
      dateTime: DateTime.now(),
      inputTokens: usage?.inputTokens,
      outputTokens: usage?.outputTokens,
      totalTokens: usage?.totalTokens,
      modelLabel: model, // 区分各自模型的回复
    );

    if (!mounted) return;
    setState(() {
      // AI思考和用户输入是相反的(如果用户输入了，就是在等到机器回到了)
      // 这里应该是等待所有的响应都完成才不是机器思考中(???暂时就判定消息列表中只要有一个占位的，就是思考中)
      isBotThinking =
          (role == "user") && messages.any((m) => m.isPlaceholder == true);

      // 添加到对话列表中（只有这里有新增修改）
      if (msgMap.containsKey(model)) {
        // 如果键存在，向列表中添加值
        msgMap[model]?.add(temp);
      } else {
        // 如果键不存在，创建新的列表并将值添加进去
        msgMap[model] = [temp];
      }

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      if (role == "user") {
        // 清空用户输入
        _userInputController.clear();

        // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
        // 一定注意要记得AI响应后要删除此占位的消息

        // 2024-07-24 模型分组的map中知道各自模型的占位消息，
        // 但是用于构建listview的统一显示的消息列表无法区分各自模型回复后进行删除
        // 所以把占位消息的id设置为各自模型的名称，用于区分(占位的ID此页面目前没有它用)
        // placeholderMessage.dateTime = DateTime.now();
        // placeholderMessage.messageId = model;

        // // 模型分组的map中知道各自模型的占位消息，
        // msgMap[model]!.add(placeholderMessage);
        // // 但是用户输入的占位消息，还是分别添加

        // messages.add(placeholderMessage);

        ///
        /// 【注意】
        /// 像上面修改了类的实例属性，其他引用的变量也会跟着变化，
        /// 因为这个不同模型的占位需要各自不同的模型名称，所以需要新的实例
        /// (上面示例留作经验)
        ///
        var newHolder = ChatMessage(
          messageId: model,
          dateTime: DateTime.now(),
          role: "assistant",
          content: "努力思考中，请耐心等待  ",
          isPlaceholder: true,
          // 目前占位时id和这个属性都是一样的，实际后续可能会变化，在移除占位时还是使用id的字符串
          modelLabel: model,
        );

        // 模型分组的map中知道各自模型的占位消息，
        msgMap[model]!.add(newHolder);
        // 但是用户输入的占位消息，还是分别添加

        messages.add(newHolder);

        // 等待AI的响应
        getGroupData(e);
      }

      // 如果是大模型响应的消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      if (role == "assistant") {
        // 用户输入的消息，只最开始添加到消息列表一次就好；而大模型响应的消息，就需要逐条替换之前占位的消息
        // (因为如果是先移除在添加，占位时的顺序和最后显示的顺序可能不一样,看模型响应的快慢)
        // msgMap 分组的消息可能先移除在添加，因为没有别的抢占回复，顺序不会乱
        if (!mounted) return;
        setState(() {
          /// e.value 可能是 CCMSpec 也可能是 ChatLLMSpec ，但都有model属性
          if (e.value.runtimeType == ChatLLMSpec) {
            var spec = (e.value as ChatLLMSpec);
            // 各自模型有响应后，删除各自模型的分组占位消息，只有这里有删除的操作(如果不考虑重新生成的话)
            msgMap[spec.model]!.removeWhere((e) => e.isPlaceholder == true);

            // 也要删除构建对话列表中各自的占位消息
            // messages.removeWhere(
            //   (m) => m.isPlaceholder == true && m.messageId == spec.model,
            // );

            // 查找并替换
            int index = messages.indexWhere(
                (m) => m.isPlaceholder == true && m.messageId == spec.model);
            if (index != -1) {
              messages[index] = temp;
            }
          } else {
            var spec = (e.value as CCMSpec);
            msgMap[spec.model]!.removeWhere((e) => e.isPlaceholder == true);
            // messages.removeWhere(
            //   (m) => m.isPlaceholder == true && m.messageId == spec.model,
            // );
            // 查找并替换
            int index = messages.indexWhere(
                (m) => m.isPlaceholder == true && m.messageId == spec.model);
            if (index != -1) {
              messages[index] = temp;
            }
          }
        });
      }
    });
  }

// 获取AI的响应
  void getGroupData(CusLabel e) async {
    // 这个是免费的平台的规格信息
    if (e.value.runtimeType == ChatLLMSpec) {
      var spec = e.value as ChatLLMSpec;

      // 发送给大模型的消息列表
      List<CommonMessage> msgs = msgMap[spec.model]!
          .where((e) => e.isPlaceholder != true)
          .map((e) => CommonMessage(content: e.content, role: e.role))
          .toList();

      // 不同的平台接口不一样
      final platformHandlers = {
        CloudPlatform.baidu.name: (msgs) =>
            getBaiduAigcResp(msgs, model: spec.model, isUserConfig: false),
        CloudPlatform.tencent.name: (msgs) =>
            getTencentAigcResp(msgs, model: spec.model, isUserConfig: false),
        CloudPlatform.aliyun.name: (msgs) =>
            getAliyunAigcResp(msgs, model: spec.model, isUserConfig: false),
        CloudPlatform.siliconCloud.name: (msgs) => getSiliconFlowAigcResp(msgs,
            model: spec.model, isUserConfig: false),
      };

      // 处理接口返回
      await handlePlatformResponse(e, msgs, platformHandlers);
    }

    // 这个是付费的平台的规格信息
    if (e.value.runtimeType == CCMSpec) {
      var spec = e.value as CCMSpec;

      List<CCMessage> msgs = msgMap[spec.model]!
          .where((e) => e.isPlaceholder != true)
          .map((e) => CCMessage(content: e.content, role: e.role))
          .toList();

      final platformHandlers = {
        ApiPlatform.lingyiwanwu.name: (msgs) =>
            getChatResp(ApiPlatform.lingyiwanwu, msgs, model: spec.model),
      };

      await handlePlatformResponse(e, msgs, platformHandlers);
    }
  }

  /// 针对不同平台接口返回的处理抽成通用的
  Future<void> handlePlatformResponse(
    CusLabel e,
    List msgs,
    Map<String, Future<dynamic> Function(List)> platformHandlers,
  ) async {
    if (e.enLabel == null) return;

    for (var entry in platformHandlers.entries) {
      // 找到对应使用的接口，处理后就可以跳出循环了
      if (e.enLabel!.startsWith(entry.key)) {
        var temp = await entry.value(msgs);

        var tempText = '';
        var cu = CommonUsage();
        if (temp is List<CommonRespBody>) {
          tempText = temp.map((e) => e.customReplyText).join();
          if (temp.isNotEmpty && temp.first.errorCode != null) {
            tempText = """接口报错:\n
                code:${temp.first.errorCode}\n
                msg:${temp.first.errorMsg}\n
                请检查AppId和AppKey是否正确，或切换其他模型试试。""";
          }

          // 每次对话的结果流式返回，所以是个列表，就需要累加起来
          int inputTokens = 0;
          int outputTokens = 0;
          int totalTokens = 0;
          for (var e in temp) {
            inputTokens += e.usage?.inputTokens ?? e.usage?.promptTokens ?? 0;
            outputTokens +=
                e.usage?.outputTokens ?? e.usage?.completionTokens ?? 0;
            totalTokens += e.usage?.totalTokens ?? 0;
          }
          // 里面的promptTokens和completionTokens是百度这个特立独行的，在上面拼到一起了
          cu = CommonUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            totalTokens: totalTokens,
          );
        } else if (temp is CCRespBody) {
          tempText = temp.customReplyText;
          if (temp.error?.code != null) {
            tempText = """AI大模型接口错误:\n
                code: ${temp.error?.code}\n
                type: ${temp.error?.type}\n
                message: ${temp.error?.message}""";
          }
          // 构建token使用数据
          cu = CommonUsage(
            inputTokens: temp.usage?.promptTokens ?? 0,
            outputTokens: temp.usage?.completionTokens ?? 0,
            totalTokens: temp.usage?.totalTokens ?? 0,
          );
        }

        await separatelyHandleMessage(
          tempText,
          e,
          role: "assistant",
          usage: cu,
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能群聊'),
        actions: [
          // 只有选中的模型仅2个时才支持对战模式
          if (_selectedItems.length == 2)
            IconButton(
              onPressed: () {
                setState(() {
                  isBattleMode = !isBattleMode;
                });
              },
              icon: Icon(
                Icons.compare,
                // 如果已经是对战模式，则为蓝色；如果不是对战模式，用默认颜色，表示可以开启对战模式
                color: isBattleMode ? Colors.blue : null,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CusMultiSelectDialog(
                    items: _allItems,
                    selectedItems: _selectedItems,
                  );
                },
              ).then((selectedItems) {
                // 多选框点击了确认就要重新开始(点击取消则不会)
                if (selectedItems != null) {
                  setState(() {
                    _selectedItems = selectedItems;
                    // 重新选择了模型列表，则重新开始对话
                    messages.clear();
                    msgMap.clear();
                  });
                  print('Selected items: $selectedItems');
                }
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 选中的平台模型
            Container(
              height: 50.sp,
              width: double.infinity,
              color: Colors.grey[300],
              child: Padding(
                padding: EdgeInsets.only(left: 10.sp, right: 10.sp),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("选中的模型\n可横向滚动"),
                        SizedBox(width: 10.sp),
                        Wrap(
                          direction: Axis.horizontal,
                          spacing: 5,
                          alignment: WrapAlignment.spaceAround,
                          children: List.generate(
                            _selectedItems.length,
                            (index) => buildSmallButtonTag(
                              _selectedItems[index].cnLabel,
                              bgColor: Colors.lightBlue,
                              labelTextSize: 12,
                            ),
                          ).toList(),
                        ),
                      ],
                    )),

                // Wrap(
                //   children: List.generate(
                //     _selectedItems.length,
                //     (index) => Text(' ${_selectedItems[index].cnLabel}'),
                //   ).toList(),
                //   // [
                //   //   const Text("这里显示被选中的多个模型名称"),
                //   //   const Text("这里显示被选中的多个模型名称"),
                //   // ],
                // ),
              ),
            ),

            /// 如果对话是空，显示预设的问题
            if (msgMap.values.isEmpty)
              // 预设的问题标题
              Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
              ),

            // 预设的问题列表
            if (msgMap.values.isEmpty)
              ChatDefaultQuestionArea(
                defaultQuestions: defaultQuestions,
                onQuestionTap: _userSendMessage,
              ),

            /// 对话的标题区域(因为暂时没有保存，所以就显示用户第一次输入的前20个字符就好了)
            if (msgMap.values.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(1.sp),
                child: Row(
                  children: [
                    const Icon(Icons.title),
                    SizedBox(width: 10.sp),
                    Expanded(
                      child: Text(
                        msgMap.values.first.first.content,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /// 显示对话消息主体
            /// (所有对话内容放到一个列表中)
            if (msgMap.values.isNotEmpty && !isBattleMode)
              MessageChatList(messages: messages),

            /// 显示对话消息主体
            /// （不同的模型放在不同的列表中，当只有2个进行对比时，各自滚动比较好看）
            /// (模型多了，切得太小了就不好看了)
            if (msgMap.values.isNotEmpty && isBattleMode)
              ...List.generate(msgMap.values.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 5.sp), // 头像宽度
                          Text(
                            msgMap.keys.toList()[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                      MessageChatList(
                        messages: msgMap.values.toList()[index],
                        isShowLable: false,
                      ),
                    ],
                  ),
                );
              }).toList(),

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
                _userSendMessage(userInput);
                setState(() {
                  userInput = "";
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
