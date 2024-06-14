// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';

import '../../apis/baidu_apis.dart';
import '../../models/llm_chat_state.dart';
import 'widgets/message_item.dart';

class BaiduImage2TextScreen extends StatefulWidget {
  const BaiduImage2TextScreen({super.key});

  @override
  State createState() => _BaiduImage2TextScreenState();
}

class _BaiduImage2TextScreenState extends State<BaiduImage2TextScreen> {
  File? _selectedImage; // 用于存储选中的图片文件
  String? _base64Image; // 用于存储Base64编码的图片字符串

  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  // String userInput = "What is the estimated age of the image in the picture?";
  String userInput =
      "What are the calculation results of the mathematical expressions in the figure?";

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  // 假设的对话数据
  List<ChatMessage> messages = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    text: "努力思考中(等待越久,回复内容越多)  ",
    isFromUser: false,
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  _sendMessage(String text, {bool isFromUser = true}) {
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();
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

        getFuyuData(text);
      }
    });
  }

  getFuyuData(String text) async {
    var a = await getBaiduFuyu8BResp(text, _base64Image!);

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    _sendMessage(a.result ?? "暂无回复", isFromUser: false);
  }

  // 选择图片的函数
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, // 选择图片类型
      );

      if (result != null) {
        // 获取文件
        final file = File(result.files.single.path!);
        // 读取文件内容
        final bytes = await file.readAsBytes();

        // 创建File对象
        setState(() {
          // 将字节转换为Base64字符串,并赋值给全局变量
          _base64Image = base64Encode(bytes);

          print("${_base64Image?.length}");

          // 将图片文件赋值给全局变量
          _selectedImage = file;
        });
      }
    } on PlatformException catch (e) {
      print("Unsupported operation$e");
    }
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  regenerateLatestQuestion() {
    var temp = messages.where((e) => !e.isFromUser).toList();

    if (temp.isNotEmpty) {
      setState(() {
        // 将最后一条消息删除，并添加占位消息，重新发送
        messages.removeLast();
        placeholderMessage.dateTime = DateTime.now();
        messages.add(placeholderMessage);

        getFuyuData(temp.last.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图像理解'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200.sp,
            child: Row(
              children: [
                SizedBox(width: 5.sp),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 图片预览
                      SizedBox(
                        height: 150.sp,
                        child: _selectedImage != null
                            ? _buildFileImageView(_selectedImage!, context)
                            : const Center(
                                child: Text(
                                  '请选择图片',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),

                      // 图片选择按钮
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('选择图片'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.sp),
                Expanded(
                  flex: 8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userInputController,
                          style: TextStyle(fontSize: 12.sp),
                          decoration: const InputDecoration(
                            hintText: '输入有关图片的任何问题\n使用英语AI理解效果更佳',
                            border: OutlineInputBorder(), // 添加边框
                          ),

                          // 外层有设定大小，可以设定膨胀为ture，且必须手动设定最大最小行为null
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          onChanged: (String? text) {
                            if (text != null) {
                              setState(() {
                                userInput = text.trim();
                              });
                            }
                          },
                        ),
                      ),
                      ElevatedButton(
                        // 如果没有选中图片，AI正在响应，或者输入框没有任何文字，不让点击发送
                        onPressed: isBotThinking ||
                                userInput.isEmpty ||
                                _selectedImage == null
                            ? null
                            : () {
                                // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                                FocusScope.of(context).unfocus();

                                // 用户发送消息
                                _sendMessage(userInput);

                                // 发送完要清空记录用户输的入变量
                                setState(() {
                                  userInput = "";
                                });
                              },
                        child: const Text(
                          "生成图像理解",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 5.sp),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
                                  "已复制到剪贴板",
                                  duration: const Duration(seconds: 3),
                                  toastPosition:
                                      EasyLoadingToastPosition.center,
                                );
                              },
                              icon: Icon(Icons.copy, size: 20.sp),
                            ),
                            // // 其他功能(占位)
                            IconButton(
                              onPressed: null,
                              icon: Icon(Icons.translate_outlined, size: 20.sp),
                            ),
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
          ),
        ],
      ),
    );
  }
}

/// 构建生成的图片结果
_buildFileImageView(File image, BuildContext context) {
  return GridTile(
    child: GestureDetector(
      // 单击预览
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: FileImage(image),
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                // enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                errorBuilder: (context, url, error) => const Icon(Icons.error),
              ),
            );
          },
        );
      },
      // 默认显示文件图片
      child: Center(child: Image.file(image, fit: BoxFit.scaleDown)),
    ),
  );
}
