// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';

import '../../apis/baidu_apis.dart';
import '../../common/constants.dart';
import '../../common/utils/db_helper.dart';
import '../../models/common_llm_info.dart';
import '../../models/llm_chat_state.dart';
import 'widgets/message_item.dart';

class BaiduImage2TextScreen extends StatefulWidget {
  const BaiduImage2TextScreen({super.key});

  @override
  State createState() => _BaiduImage2TextScreenState();
}

class _BaiduImage2TextScreenState extends State<BaiduImage2TextScreen> {
  File? _selectedImage; // 用于存储选中的图片文件

  final DBHelper _dbHelper = DBHelper();

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

  // 是否获得了存储权限(没获得就无法备份恢复)
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();

    _requestPermission();
  }

  _requestPermission() async {
    /// 2024-01-12 直接询问存储权限，不给就直接显示退出就好
    // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
    // Permission.photos, Permission.videos or Permission.audio等
    // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
    if (Platform.isAndroid) {
      // 获取设备sdk版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        PermissionStatus storageStatus = await Permission.storage.request();
        setState(() {
          if (storageStatus.isGranted) {
            isPermissionGranted = true;
          } else {
            isPermissionGranted = false;
          }
        });
      } else {
        PermissionStatus status = await Permission.photos.request();
        setState(() {
          if (status.isGranted) {
            isPermissionGranted = true;
          } else {
            isPermissionGranted = false;
          }
        });
      }
    }
  }

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

        getFuyuData(text);
      }
    });
  }

  _saveToDb() async {
    print("处理插入前message的长度${messages.length}");
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid

    if (messages.isNotEmpty && messages.length == 1) {
      // 如果没有对话记录(即上层没有传入，且当前时用户第一次输入文字还没有创建对话记录)，则新建对话记录
      chatSession ??= ChatSession(
        uuid: const Uuid().v4(),
        // 存完整的第一个问题，就不让修改了
        title: messages.first.text,
        gmtCreate: DateTime.now(),
        messages: messages,
        // 2026-06-06 这里记录的也是各平台原始的大模型名称
        llmName: i2tLlmModels[Image2TextLLM.baiduFuyu8B]!,
        cloudPlatformName: CloudPlatform.baidu.name,
        // 2026-06-06 对话历史默认带上类别
        chatType: "image2text",
        // 存base64显示时会一闪一闪，直接存缓存地址好了
        i2tImagePath: _selectedImage?.path,
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

    print("xxxxxxxxxxxxxxxxxxx");
  }

  getFuyuData(String text) async {
    var a = await getBaiduFuyu8BResp(
      text,
      base64Encode((await _selectedImage!.readAsBytes())),
    );

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    _sendMessage(a.result ?? "暂无回复", isFromUser: false);
  }

  // 选择图片的函数
  Future<void> _pickImage() async {
    if (!isPermissionGranted) {
      return EasyLoading.showError("未授权可访问图片，无法选择图片");
    }
    try {
      // 选择新图片，就是新开图像理解对话了
      setState(() {
        chatSession = null;
        messages.clear();
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, // 选择图片类型
      );

      if (result != null) {
        // 获取文件,创建File对象
        final file = File(result.files.single.path!);

        print("选中的文件的地址${file.path}");

        setState(() {
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
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                // icon: Text(
                //   '最近对话',
                //   style: TextStyle(
                //     fontSize: 12.sp,
                //     color: Theme.of(context).primaryColor,
                //   ),
                // ),
                icon: Icon(Icons.history, size: 24.sp),
                onPressed: () async {
                  // 获取历史记录
                  var a = await _dbHelper.queryChatList(cateType: "image2text");
                  setState(() {
                    chatHsitory = a;
                  });
                  print("历史记录$a");

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
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
                        child: buildImageView(_selectedImage, context),
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

  _getChatInfo(String chatId) async {
    print("调用了getChatInfo----------$chatId");
    var list = await _dbHelper.queryChatList(
      uuid: chatId,
      cateType: "image2text",
    );

    print("list------${list.length}");

    if (list.isNotEmpty && list.isNotEmpty) {
      setState(() {
        chatSession = list.first;

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;

        if (list.first.i2tImagePath != null) {
          _selectedImage = File(list.first.i2tImagePath!);
        }

        print("messages------${messages.length}");
      });
    }
  }

  buildGestureItems(ChatSession e) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // 点击了指定的历史对话，则替换当前对话
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
              width: 40.sp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                title: Text("确认删除图像理解记录:", style: TextStyle(fontSize: 18.sp)),
                content: Text("记录请求编号：\n${e.uuid}"),
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
              var a = await _dbHelper.deleteChatById(e.uuid);

              print("删除结果---------$a");

              // 然后重新查询并更新
              var b = await _dbHelper.queryChatList(cateType: "image2text");

              print("查询结果---------${b.length}");
              setState(() {
                chatHsitory = b;
              });

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
}

/// 构建生成的图片结果
/// 注意限定传入的图片类型，要在这些条件之中
Widget buildImageView(dynamic image, BuildContext context) {
  // 如果没有图片数据，直接返回文提示
  if (image == null) {
    return const Center(
      child: Text(
        '请选择图片',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  print("显示的图片类型---${image.runtimeType == File}-${image.runtimeType} -$image");

  ImageProvider imageProvider;
  // 只有base64的字符串或者文件格式
  if (image.runtimeType == String) {
    imageProvider = MemoryImage(base64Decode(image));
  } else {
    // 如果直接传文件，那就是文件
    imageProvider = FileImage(image);
  }

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
                imageProvider: imageProvider,
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
      child: RepaintBoundary(
        child: Center(
          child: Image(image: imageProvider, fit: BoxFit.scaleDown),
        ),
      ),
    ),
  );
}

// /// 构建生成的图片结果
// /// 注意限定传入的图片类型，要在这些条件之中
// Widget buildImageView(dynamic image, BuildContext context) {
//   // 如果没有图片数据，直接返回文提示
//   if (image == null) {
//     return const Center(
//       child: Text(
//         '请选择图片',
//         style: TextStyle(color: Colors.grey),
//       ),
//     );
//   }

//   print("显示的图片类型---${image.runtimeType == File}-${image.runtimeType} -$image");

//   ImageProvider imageProvider;
//   // 如果是String，且时http开头，就当作是网络图片
//   if (image.runtimeType == String && (image as String).startsWith("http")) {
//     imageProvider = NetworkImage(image);
//   } else if (image.runtimeType == String &&
//       (image as String).startsWith("/data/user/0/")) {
//     // 如果是String，且不是http开头但是设备内部存储，则直接取文件
//     imageProvider = FileImage(File(image));
//   } else if (image.runtimeType == File) {
//     // 如果直接传文件，那就是文件
//     imageProvider = FileImage(image);
//   } else {
//     //
//     // 其他就当作是图片base64的字符串
//     imageProvider = MemoryImage(base64Decode(image));
//   }

//   return GridTile(
//     child: GestureDetector(
//       // 单击预览
//       onTap: () {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return Dialog(
//               backgroundColor: Colors.transparent, // 设置背景透明
//               child: PhotoView(
//                 imageProvider: imageProvider,
//                 // 设置图片背景为透明
//                 backgroundDecoration: const BoxDecoration(
//                   color: Colors.transparent,
//                 ),
//                 // 可以旋转
//                 // enableRotation: true,
//                 // 缩放的最大最小限制
//                 minScale: PhotoViewComputedScale.contained * 0.8,
//                 maxScale: PhotoViewComputedScale.covered * 2,
//                 errorBuilder: (context, url, error) => const Icon(Icons.error),
//               ),
//             );
//           },
//         );
//       },
//       // 默认显示文件图片
//       child: RepaintBoundary(
//         child: Center(
//           child: Image(image: imageProvider, fit: BoxFit.scaleDown),
//         ),
//       ),
//     ),
//   );
// }
