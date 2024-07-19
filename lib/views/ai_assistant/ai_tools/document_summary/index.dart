// ignore_for_file: avoid_print

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/common_chat_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../../../models/common_llm_info.dart';
import '../../../../models/llm_chat_state.dart';
import '../../_components/message_item.dart';
import 'document_parser.dart';

///
/// 文档提要
/// 用户可以直接复制一大段内容来分析，或者上传文件来分析
///
class DocumentSummary extends StatefulWidget {
  const DocumentSummary({super.key});

  @override
  State createState() => _DocumentSummaryState();
}

class _DocumentSummaryState extends State<DocumentSummary> {
  // 上传的文件(方便显示文件相关信息)
  PlatformFile? _selectedFile;
  // 文档解析出来的内容
  String _fileContent = '';

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 是否在解析文件中
  bool isLoadingDocument = false;

  // 用户输入的文本控制器
  final _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";
  String userInputForRegen = "";

  ///
  /// ===================
  ///

  Future<void> _pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        // 是否在解析文件中
        isLoadingDocument = true;
        // 新选中了文档，需要在解析前就清空旧的文档信息和旧的分析数据
        _fileContent = '';
        _selectedFile = null;
        messages.clear();
      });
      PlatformFile file = result.files.first;

      // 如果 parsePdf 方法改为异步方法后，加载圈仍然卡住，可能是因为解析 PDF 的操作仍然在 UI 线程中执行。
      // 为了确保加载圈能够正常旋转，需要确保解析 PDF 的操作在后台线程中执行。
      // 可以使用 compute 函数来在后台线程中执行耗时操作。
      // var text = await parsePdf(file.path!);
      var text = await compute(parsePdfLinesSync, file.path!);

      if (!mounted) return;
      setState(() {
        _selectedFile = file;
        // 无法解析的和解析结果为空的，都统一为空字符串
        _fileContent = text ?? "";

        print("=========文档内容长度==========${_fileContent.length}--$_fileContent");
        isLoadingDocument = false;
      });
    }
  }

  ///
  /// 问答都是一次性的，不用想着多次发送的情况了
  /// 对于是否展示用户输入的内容，分为以下三种情况：
  ///   1 只上传了文档：用户输入的内容只有文档名称即可
  ///   2 只复制了文档内容：显示所有用户输入的内容
  ///   3 都有：显示文档名称和用户输入的内容
  ///
  /// 这个按钮只有用户点击，每次点击效果是一样的
  ///
  qusets({bool? isRegen}) async {
    // 点击分析前，显示占位的

    var userContent = "";

    if (_selectedFile != null) {
      userContent += "需要分析的文档文件:\n\n${_selectedFile!.name}\n\n";
    }

    // 如果是重新生成，那用户输入的内容其实已经清空了，要使用刻意备份的字符串
    if (isRegen == true) {
      userContent += "手动输入的文档内容:\n\n$userInputForRegen\n\n";
    } else {
      // 理论上重新生成和用户输入为空不会都为true，但为了避免意外，强行2选1
      if (userInput.isNotEmpty) {
        userContent += "手动输入的文档内容:\n\n$userInput\n\n";
      }
    }

    // ？？？2024-07-19 文本太长了暂时就算了
    if ((_fileContent.length + userInput.length) > 8000) {
      print("总文档长度:======= ${(_fileContent.length + userInput.length)}");
      EasyLoading.showInfo(
        "文档内容太长(${(_fileContent.length + userInput.length)}字符)，暂不支持超过8000字符的阅读总结，请谅解。",
        duration: const Duration(seconds: 5),
      );

      return;
    }

    setState(() {
      // 先清除占位的等待对话，再添加占位的等待信息
      messages.clear();

      // 先展示用户输入内容
      messages.add(ChatMessage(
        messageId: const Uuid().v4(),
        dateTime: DateTime.now(),
        role: "user",
        content: userContent,
      ));

      // 在大模型响应时，显示占位的内容
      messages.add(ChatMessage(
        messageId: "placeholderMessage",
        dateTime: DateTime.now(),
        role: "assistant",
        content: "努力思考中，请耐心等待  ",
        isPlaceholder: true,
      ));
    });

    // ？？？具体给大模型发送的指令，就不给用户展示了(文档解析可能不正确，内容也太多)
    List<CommonMessage> msgs = [
      CommonMessage(
        role: "user",
        content: "请阅读以下文档内容，并总结出文档的主要内容:\n$_fileContent",
      ),
    ];

    // 发送完要清空记录用户输的入变量
    // 2024-07-19 注意这里只清空控制器的文本，而不是记录用户输入的变量
    //  因为如果这里都清空了，那么重新生成函数中就取不到用户输入的文档内容了
    // 又因为在判断是否可以点击发送按钮时，直接使用_userInputController.text是没有实时状态改变所以不准确的
    // 因此，专门多一个变量来处理重新生成函数
    setState(() {
      userInputForRegen = userInput;
      _userInputController.clear();
      userInput = "";
    });

    List<CommonRespBody> temp = await getBaiduAigcResp(
      msgs,
      model: newLLMSpecs[PlatformLLM.baiduErnieSpeed128KFREE]!.model,
      stream: false,
      isUserConfig: false,
      // 百度API的系统设置，是外部的参数，不是消息列表里面
      system: "你是一个文档总结分析助手，请根据提供的文档内容回答问题，如果无法回答，请回答“无法回答”，不要回答其他内容。",
    );

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

    setState(() {
      // 得到大模型响应后，先清除占位的等待对话，再添加大模型返回的内容
      // 理论上messages只会有两条:1 用户输入和 2大模型占位/大模型实际响应
      messages.removeWhere((element) => element.isPlaceholder == true);

      messages.add(ChatMessage(
        messageId: const Uuid().v4(),
        role: "assistant",
        content: tempText,
        dateTime: DateTime.now(),
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
      ));
    });
  }

  // 重新生成总结内容
  regenerateLatestQuestion() {
    print(messages.length);
    setState(() {
      // 将最后一条消息删除，重新发送
      messages.removeLast();
    });
    print(messages.length);
    print("xxxxxxxxxxxxxxxxxxx");

    // 因为在调用总结函数时有清空用户输入，所以这里点击重新生成，就取不到直接的用户输入了
    // 所以在函数内部专门加了个变量，来处理重新生成的逻辑
    qusets(isRegen: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文档提要'),
        actions: [
          IconButton(
            onPressed: () {
              commonHintDialog(
                context,
                '温馨提示',
                '1 文档目前仅支持pdf、word、txt格式;\n 2 目前仅支持单个文档的分析总结提要;\n 3 文档总内容不超过8000字符.',
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.help),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          isLoadingDocument
              ? const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text("正在解析文档..."),
                    ],
                  ),
                )
              : buildReadSummaryChatArea(),
          buildUserSendArea(),
        ],
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                // 添加边框线
                border: Border.all(color: Colors.grey, width: 1.sp),
                // 添加圆角
                borderRadius: BorderRadius.circular(10.sp),
              ),
              child: Column(
                children: [
                  if (_selectedFile != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(width: 20.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile?.name ?? "",
                                maxLines: 2,
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              // Text(
                              //   _selectedFile?.size != null
                              //       ? "${formatFileSize(_selectedFile!.size)} 文档已解析完成, 共有 ${_fileContent.length} 字符"
                              //       : '',
                              //   style: TextStyle(fontSize: 10.sp),
                              // ),
                              RichText(
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                text: TextSpan(
                                  children: [
                                    // 为了分类占的宽度一致才用的，只是显示的话可不必
                                    TextSpan(
                                      text: formatFileSize(_selectedFile!.size),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "  文档已解析完成,",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " 共有 ${_fileContent.length} 字符",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 48.sp,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _fileContent = "";
                                _selectedFile = null;
                                messages.clear();
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                      ],
                    ),
                  if (_selectedFile != null) Divider(height: 1.sp),
                  Row(
                    children: [
                      IconButton(
                        onPressed: isLoadingDocument ? null : _pickAndReadFile,
                        icon: const Icon(Icons.file_upload),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _userInputController,

                          decoration: const InputDecoration(
                            hintText: '上传文档文件或者输入文档内容',
                            // 全边框线
                            // border: OutlineInputBorder(),
                            // 取消边框线
                            border: InputBorder.none,
                          ),
                          // ？？？2024-07-14 如果屏幕太小，键盘弹出来之后挤占屏幕高度，这里可能会出现溢出问题
                          maxLines: 5,
                          minLines: 1,
                          onChanged: (String? text) {
                            if (text != null) {
                              setState(() {
                                userInput = text.trim();
                                // 如果用户既上传了文件，又输入了内容，则将内容添加到文件内容中
                                if (_fileContent.isNotEmpty) {
                                  _fileContent += userInput;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          IconButton(
            // 只要上传文档解析有内容，或者用户有输入内容，就可以点击发送按钮了
            onPressed: userInput.isEmpty && _fileContent.isEmpty
                ? null
                : () {
                    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                    FocusScope.of(context).unfocus();

                    // 调用文档分析总结函数
                    qusets();
                  },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  /// 构建对话列表主体
  buildReadSummaryChatArea() {
    return Expanded(
      child: ListView.builder(
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

                      if ((index == messages.length - 1) &&
                          messages[index].isPlaceholder != true)
                        TextButton(
                          onPressed: () {
                            regenerateLatestQuestion();
                          },
                          child: const Text("重新生成"),
                        ),

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
}
