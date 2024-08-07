// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/tools.dart';
import '../ai_tools/_sounds_message_button/button_widget/sounds_message_button.dart';
import '../ai_tools/_sounds_message_button/utils/sounds_recorder_controller.dart';

///
/// 用户发送区域
/// aggregate_search 和 chat_bot 都可以用
///
class ChatUserVoiceSendArea extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isBotThinking;
  final String userInput;
  final Function(String) onChanged;
  final VoidCallback onSendPressed;
  final bool Function()? isMessageTooLong;
  // 2024-06-04 添加语音输入的支持，但不一定非要传入(但只要传入了，此时上方的 onSendPressed其实也没用了)
  final Function(SendContentType, String)? onSendSounds;

  const ChatUserVoiceSendArea({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isBotThinking,
    required this.userInput,
    required this.onChanged,
    required this.onSendPressed,
    this.isMessageTooLong,
    this.onSendSounds,
  });

  @override
  State<ChatUserVoiceSendArea> createState() => _ChatUserVoiceSendAreaState();
}

class _ChatUserVoiceSendAreaState extends State<ChatUserVoiceSendArea> {
  bool isVoice = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          // 在语音输入和文字输入间切换，显示不同图标
          SizedBox(
            width: 50.sp,
            child: IconButton(
              icon: Icon(isVoice ? Icons.keyboard : Icons.keyboard_voice),
              onPressed: () async {
                // 默认是文字输入，如果要切换成语音，得先获取语音权限和存储权限
                if (!(await requestMicrophonePermission())) {
                  return EasyLoading.showError("未授权语音录制权限，无法语音输入");
                }

                // 首先获取设备外部存储管理权限
                if (!(await requestStoragePermission())) {
                  return EasyLoading.showError("未授权访问设备外部存储，无法进行语音识别");
                }

                setState(() {
                  isVoice = !isVoice;
                });
              },
            ),
          ),
          if (isVoice && widget.onSendSounds != null)
            Expanded(
              child: SizedBox(
                // 高度56是和下面TextField一样高
                height: 56.sp,
                child: SoundsMessageButton(
                  // key: _key,
                  onChanged: (status) {
                    print("onChanged-在组件里面--------$status");

                    // // 120 是遮罩层的视图高度
                    // _padding.value = EdgeInsets.symmetric(
                    //   vertical: status == SoundsMessageStatus.none
                    //       ? 0
                    //       : (120 + 60 - (30 + 44) / 2) / 2 + 15,
                    // );
                  },
                  onSendSounds: widget.onSendSounds,
                  // onSendSounds: (type, content) {
                  //   print("点击了语音发送之后-在组件里面--------");
                  // },
                ),
              ),
            ),
          if (!isVoice)
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: widget.onChanged,
              ),
            ),
          (!isVoice)
              ? IconButton(
                  onPressed: widget.isBotThinking || widget.userInput.isEmpty
                      ? null
                      : () {
                          // 有传长度限制函数、且限制的结果为true，才显示弹窗
                          if (widget.isMessageTooLong != null &&
                              widget.isMessageTooLong!()) {
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
                          } else {
                            FocusScope.of(context).unfocus();
                            widget.onSendPressed();
                          }
                        },
                  icon: const Icon(Icons.send),
                )
              : SizedBox(width: 48.sp), // 图标按钮默认大小48*48
        ],
      ),
    );
  }
}
