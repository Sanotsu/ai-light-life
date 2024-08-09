// ignore_for_file: avoid_print

import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../../../models/llm_spec/cc_llm_spec_free.dart';
import '../../../../models/chat_completion/common_cc_state.dart';
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
  // 是否在解析文件中
  bool isLoadingDocument = false;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 用户输入的文本控制器
  final _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // 2024-07-26因为每次发送之后都会清空输入，所以重新生成时要传上一次保留的文档内容
  String docForRegen = "";

  String hintInfo = """1. 目前仅支持上传单个文档文件
2. 上传文档目前仅支持 pdf、txt、docx、doc 格式
3. 上传的文档和手动输入的文档总内容不超过8000字符
4. 输入的文档和总结可以上下滚动查看""";

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<CommonRespBody>? respStream;
  // 是否AI完成了响应(在请求中或者流式回复没有完全时，都为true)
  bool isBotThinking = false;

  /// 选择文件并解析
  Future<void> _pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'doc'],
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

      try {
        var text = "";
        switch (file.extension) {
          case 'txt':
            DecodingResult result = await CharsetDetector.autoDecode(
              File(file.path!).readAsBytesSync(),
            );
            text = result.string;
          // print(result.charset);
          // print(result.string);
          case 'pdf':
            text = await compute(extractTextFromPdf, file.path!);
          case 'docx':
            text = docxToText(File(file.path!).readAsBytesSync());
          case 'doc':
            text = await DocText().extractTextFromDoc(file.path!) ?? "";
          default:
            print("默认的,暂时啥都不做");
        }

        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _fileContent = text;
          isLoadingDocument = false;
          // l.i("=========文档内容长度==========${_fileContent.length}");
          // l.i('上传文档解析出来的内容：$_fileContent');
        });
      } catch (e) {
        // l.e("解析文档出错:${e.toString()}");

        EasyLoading.showError(e.toString());

        setState(() {
          _selectedFile = file;
          _fileContent = "";
          isLoadingDocument = false;
        });
        rethrow;
      }
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
  getSummaryResult({bool? isRegen}) async {
    // 2024-07-26 需要被总结的文档(解析的文档和用户输入的文档用md格式完整显示)
    var docToBeSummarized = "";

    // 如果是重新生成，则使用备份的上次的文档内容；否则就新的内容
    if (isRegen == true) {
      docToBeSummarized = docForRegen;
    } else {
      // 有选中文件
      if (_selectedFile != null) {
        docToBeSummarized += "**文档内容一**:\n\n$_fileContent\n\n";
      }

      // 有手动输入
      if (userInput.isNotEmpty) {
        docToBeSummarized +=
            "**文档内容${_selectedFile != null ? '二' : '一'}**:\n\n$userInput";
      }
    }

    var totolLength = docToBeSummarized.length;

    // ？？？2024-07-19 文本太长了暂时就算了
    if (totolLength > 8000) {
      print("总文档长度:======= $totolLength");
      EasyLoading.showInfo(
        "文档内容太长($totolLength字符)，暂不支持超过8000字符的阅读总结，请谅解。",
        duration: const Duration(seconds: 5),
      );

      return;
    }

    setState(() {
      // 把整理好的文档赋值给可能用于重新生成的变量
      docForRegen = docToBeSummarized;
      // 先清除占位的等待对话，再添加占位的等待信息
      messages.clear();

      // 先展示用户输入内容
      messages.add(ChatMessage(
        messageId: const Uuid().v4(),
        dateTime: DateTime.now(),
        role: "user",
        content: docToBeSummarized,
      ));

      // 在大模型响应时，显示占位的内容
      messages.add(ChatMessage(
        messageId: "placeholderMessage",
        dateTime: DateTime.now(),
        role: "assistant",
        content: "正在处理中，请稍候  ",
        isPlaceholder: true,
      ));

      isBotThinking = true;
    });

    // ？？？具体给大模型发送的指令，就不给用户展示了(文档解析可能不正确，内容也太多)
    List<CommonMessage> msgs = [
      CommonMessage(
        role: "user",
        content: "请阅读以下文档内容，并总结出文档的主要内容:\n$docToBeSummarized",
      ),
    ];

    // 发送完要清空记录用户输的入变量
    // 因为在判断是否可以点击发送按钮时，直接使用_userInputController.text是没有实时状态改变所以不准确的
    // 因此，专门多一个变量来处理重新生成函数
    setState(() {
      _userInputController.clear();
      userInput = "";
    });

    // 在请求前创建当前响应的消息和文本内容，当前请求完之后，就重置为空
    ChatMessage? currentStreamingMessage;
    final StringBuffer messageBuffer = StringBuffer();

    // 后续可手动终止响应时的写法
    StreamWithCancel<CommonRespBody> tempStream = await baiduCCRespWithCancel(
      msgs,
      model: Free_CC_LLM_SPEC_MAP[FreeCCLLM.baidu_Ernie_Speed_128K]!.model,
      stream: true,
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });
    // 上面赋值了，这里应该可以监听到新的流了
    respStream?.stream.listen(
      (crb) {
        // 得到回复后要删除表示加载中的占位消息
        if (!mounted) return;
        setState(() {
          messages.removeWhere((e) => e.isPlaceholder == true);
        });

        // 当前响应流处理完了，就不是AI响应中了
        if (crb.customReplyText == '[DONE]') {
          if (!mounted) return;
          setState(() {
            _userInputController.clear();
            currentStreamingMessage = null;
            isBotThinking = false;
          });
        } else {
          setState(() {
            isBotThinking = true;
            messageBuffer.write(crb.customReplyText);
            // 只有第一次响应时才创建消息体，后续接收的响应流数据只更新当前的
            if (currentStreamingMessage == null) {
              // 得到大模型响应后，先清除占位的等待对话，再添加大模型返回的内容
              // 理论上messages只会有两条:1 用户输入和 2大模型占位/大模型实际响应
              messages.removeWhere((element) => element.isPlaceholder == true);

              currentStreamingMessage = ChatMessage(
                messageId: const Uuid().v4(),
                role: "assistant",
                content: messageBuffer.toString(),
                contentVoicePath: "",
                dateTime: DateTime.now(),
                inputTokens:
                    crb.usage?.inputTokens ?? crb.usage?.promptTokens ?? 0,
                outputTokens:
                    crb.usage?.outputTokens ?? crb.usage?.completionTokens ?? 0,
                totalTokens: crb.usage?.totalTokens ?? 0,
              );

              messages.add(currentStreamingMessage!);
            } else {
              currentStreamingMessage!.content = messageBuffer.toString();
              // token的使用就是每条返回的就是当前使用的结果，所以最后一条就是最终结果，实时更新到最后一条
              currentStreamingMessage!.inputTokens =
                  (crb.usage?.inputTokens ?? crb.usage?.promptTokens ?? 0);
              currentStreamingMessage!.outputTokens =
                  (crb.usage?.outputTokens ?? crb.usage?.completionTokens ?? 0);
              currentStreamingMessage!.totalTokens =
                  (crb.usage?.totalTokens ?? 0);
            }
          });
        }
      },
      // 非流式的时候，只有一条数据，永远不会触发上面监听时的DONE的情况
      onDone: () {
        if (!mounted) return;
        setState(() {
          _userInputController.clear();
          currentStreamingMessage = null;
          isBotThinking = false;
        });
      },
    );

//     List<CommonRespBody> temp = await getBaiduAigcResp(
//       msgs,
//       model: Free_CC_LLM_SPEC_MAP[FreeCCLLM.baidu_Ernie_Speed_128K]!.model,
//       stream: false,
//       isUserConfig: false,
//       // 百度API的系统设置，是外部的参数，不是消息列表里面
//       system: "你是一个文档总结分析助手，请根据提供的文档内容回答问题，如果无法回答，请回答“无法回答”，不要回答其他内容。",
//     );

//     // 得到AI回复之后，添加到列表中，也注明不是用户提问
//     var tempText = temp.map((e) => e.customReplyText).join();
//     if (temp.isNotEmpty && temp.first.errorCode != null) {
//       tempText = """接口报错:
// \ncode:${temp.first.errorCode}
// \nmsg:${temp.first.errorMsg}
// \n请检查AppId和AppKey是否正确，或切换其他模型试试。
// """;
//     }

//     // 每次对话的结果流式返回，所以是个列表，就需要累加起来
//     int inputTokens = 0;
//     int outputTokens = 0;
//     int totalTokens = 0;
//     for (var e in temp) {
//       inputTokens += e.usage?.inputTokens ?? e.usage?.promptTokens ?? 0;
//       outputTokens += e.usage?.outputTokens ?? e.usage?.completionTokens ?? 0;
//       totalTokens += e.usage?.totalTokens ?? 0;
//     }

//     setState(() {
//       // 得到大模型响应后，先清除占位的等待对话，再添加大模型返回的内容
//       // 理论上messages只会有两条:1 用户输入和 2大模型占位/大模型实际响应
//       messages.removeWhere((element) => element.isPlaceholder == true);

//       messages.add(ChatMessage(
//         messageId: const Uuid().v4(),
//         role: "assistant",
//         content: tempText,
//         dateTime: DateTime.now(),
//         inputTokens: inputTokens,
//         outputTokens: outputTokens,
//         totalTokens: totalTokens,
//       ));
//     });
  }

  // 重新生成总结内容
  regenerateLatestQuestion() {
    print(messages.length);
    setState(() {
      // 将最后一条消息删除，重新发送
      messages.removeLast();
    });

    // 因为在调用总结函数时有清空用户输入，所以这里点击重新生成，就取不到直接的用户输入了
    // 所以在函数内部专门加了个变量，来处理重新生成的逻辑
    getSummaryResult(isRegen: true);
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
                hintInfo,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.help),
          ),
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
              : messages.isEmpty
                  ? const Expanded(child: Center(child: Text("请上传文件文件或输入文档内容")))
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
                              RichText(
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                text: TextSpan(
                                  children: [
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
                    getSummaryResult();
                  },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  /// 构建对话列表主体
  buildReadSummaryChatArea() {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        // kBottomNavigationBarHeight;
        110.sp; // 底部发送按钮区域的高度

    return Expanded(
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // 构建MessageItem
          return Padding(
            padding: EdgeInsets.all(5.sp),
            // 因为只有单纯的用户输入文档和AI总结文档两部分，所以希望各占一半，各自可以滚动
            child: SizedBox(
              height: screenBodyHeight / 2,
              child: _buildMessageArea(
                messages,
                index,
                isBotThinking,
                () => regenerateLatestQuestion(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 构建单个消息的内容
_buildMessageArea(
  List<ChatMessage> messages,
  int index,
  isBotThinking,
  void Function()? onRegenPressed,
) {
  // 如果是用户输入，仅展示即可；否则可能会有其他功能按钮
  return (messages[index].role == 'user')
      ? SingleChildScrollView(
          child: MessageItem(
            message: messages[index],
            isAvatarTop: true,
          ),
        )
      : SingleChildScrollView(
          child: Column(
            children: [
              MessageItem(
                message: messages[index],
                isAvatarTop: true,
              ),
              // 如果是最后一条，且不是占位对话，可能重新生成
              if ((index == messages.length - 1) &&
                  messages[index].isPlaceholder != true &&
                  !isBotThinking)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onRegenPressed,
                      child: const Text("重新生成"),
                    ),
                    TextButton(
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
                      child: const Text("复制"),
                    ),
                    SizedBox(width: 10.sp),
                    Text(
                      "token 总计: ${messages[index].totalTokens}\n输入: ${messages[index].inputTokens} 输出: ${messages[index].outputTokens}",
                      style: TextStyle(fontSize: 10.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(width: 10.sp),
                  ],
                ),
              SizedBox(height: 10.sp),
            ],
          ),
        );
}
