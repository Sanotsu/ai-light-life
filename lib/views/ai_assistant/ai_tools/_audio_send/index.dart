// ignore_for_file: avoid_print

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;

import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/utils/tools.dart';
import 'sounds_button/sounds_button.dart';
// import 'sounds_button_single/sounds_button.dart';
import 'utils/recorder.dart';

class AudioSendScreen extends StatefulWidget {
  const AudioSendScreen({super.key});

  @override
  State<AudioSendScreen> createState() => _AudioSendScreenState();
}

class _AudioSendScreenState extends State<AudioSendScreen> {
  final List<String> _items = List.generate(15, (index) => '文字内容 $index');
  final ScrollController _controller = ScrollController();

  @override
  initState() {
    super.initState();

    requestP();
  }

  requestP() async {
    // 首先获取设备外部存储管理权限
    if (!(await requestStoragePermission())) {
      return EasyLoading.showError("未授权访问设备外部存储，无法保存文档");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f2f2),
      resizeToAvoidBottomInset: false,
      body: VoiceChatView(
        scrollController: _controller,
        onSendSounds: (type, content) {
          // 建议局部刷新
          setState(() {
            _items.insert(0, content);
          });
        },
        child: ListView.builder(
          reverse: true,
          controller: _controller,
          itemBuilder: (context, index) {
            final isLeft = index % 2 == 0;
            final color = isLeft ? Colors.yellow[200] : Colors.red[300];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                textDirection:
                    index % 2 == 0 ? TextDirection.ltr : TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: ScreenUtil().screenWidth / 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        print("点击了--${_items[index]}");

                        /// 同一份语言有两个部分，一个是原始录制的m4a的格式，一个是转码厚的pcm格式
                        /// 前者用于语音识别，后者用于播放
                        String fullPathWithoutExtension = path.join(
                            path.dirname(_items[index]),
                            path.basenameWithoutExtension(_items[index]));

                        final transcription = await sendAudioToServer(
                            "$fullPathWithoutExtension.pcm");

                        print("识别厚的结果====--$transcription");

                        if (!_items[index].startsWith("/storage")) {
                          return;
                        }
                        PlayerController controller =
                            PlayerController(); // Initialise

                        // Or directly extract from preparePlayer and initialise audio player
                        await controller.preparePlayer(
                          path: _items[index],
                          shouldExtractWaveform: true,
                          noOfSamples: 100,
                          volume: 1.0,
                        );
                        // Start audio player
                        await controller.startPlayer(
                            finishMode: FinishMode.stop);
                      },
                      child: Text(_items[index]),
                    ),
                  ),
                ],
              ),
            );
          },
          itemCount: _items.length,
        ),
      ),
    );
  }
}

class VoiceChatView extends StatefulWidget {
  const VoiceChatView({
    super.key,
    this.scrollController,
    required this.child,
    required this.onSendSounds,
  });

  final Widget child;

  final ScrollController? scrollController;

  final Function(SendContentType, String) onSendSounds;

  @override
  State<VoiceChatView> createState() => _VoiceChatViewState();
}

class _VoiceChatViewState extends State<VoiceChatView> {
  final _padding = ValueNotifier(EdgeInsets.zero);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Expanded(child: widget.child),
          ValueListenableBuilder(
            valueListenable: _padding,
            builder: (context, value, child) => AnimatedPadding(
              padding: value,
              duration: const Duration(milliseconds: 200),
            ),
          ),
          SoundsMessageButton(
            // key: _key,
            onChanged: (status) {
              debugPrint(status.toString());
              // 120 是遮罩层的视图高度
              _padding.value = EdgeInsets.symmetric(
                vertical: status == SoundsMessageStatus.none
                    ? 0
                    : (120 + 60 - (30 + 44) / 2) / 2 + 15,
              );
              widget.scrollController?.animateTo(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            },
            onSendSounds: widget.onSendSounds,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
