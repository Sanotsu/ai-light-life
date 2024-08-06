// ignore_for_file: avoid_print

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;

import '../../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../../common/utils/tools.dart';
import '../utils/data.dart';
import '../utils/recorder.dart';
import 'wave.dart';

part 'recording_status_mask.dart';
part 'canvas.dart';

class SoundsMessageButton extends StatefulWidget {
  const SoundsMessageButton({
    super.key,
    this.maskData = const RecordingMaskOverlayData(),
    this.builder,
    this.onChanged,
    this.onSendSounds,
  });

  /// 自定义发送按钮视图
  final Function(
    BuildContext context,
    SoundsMessageStatus status,
  )? builder;

  /// 状态监听， 回调到外部自定义处理
  final Function(SoundsMessageStatus status)? onChanged;

  /// 发送音频 / 发送音频文字
  final Function(SendContentType type, String content)? onSendSounds;

  /// 语音输入时遮罩配置
  final RecordingMaskOverlayData maskData;

  @override
  State<SoundsMessageButton> createState() => _SoundsMessageButtonState();
}

class _SoundsMessageButtonState extends State<SoundsMessageButton> {
  /// 录音状态
  // final _status = ValueNotifier(SoundsMessageStatus.none);

  /// 屏幕大小
  final scSize = Size(ScreenUtil().screenWidth, ScreenUtil().screenHeight);

  /// 遮罩图层
  OverlayEntry? _entry;

  /// 录音
  final _soundsRecorder = SoundsRecorderController();

  @override
  void initState() {
    super.initState();
    // print(scSize);
    _soundsRecorder.status.addListener(() {
      widget.onChanged?.call(_soundsRecorder.status.value);
    });
  }

  @override
  void dispose() {
    _soundsRecorder.reset();
    _soundsRecorder.dispose();
    super.dispose();
  }

  _removeMask() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
      _soundsRecorder.updateStatus(SoundsMessageStatus.none);
    }
  }

  _showRecordingMask() {
    _entry = OverlayEntry(
      builder: (context) {
        return RepaintBoundary(
          child: RecordingStatusMaskView(
            PolymerData(_soundsRecorder, widget.maskData),
            onCancelSend: () {
              _removeMask();
            },
            onVoiceSend: () {
              widget.onSendSounds?.call(
                  SendContentType.voice, _soundsRecorder.path.value ?? '');
              _removeMask();
            },
            onTextSend: () {
              widget.onSendSounds?.call(
                SendContentType.text,
                _soundsRecorder.textProcessedController.text,
              );
              _removeMask();

              // 发送之后就清除了
              _soundsRecorder.textProcessedController.text = "";
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        // 额外添加首次授权时，不能开启录音
        if (!await _soundsRecorder.hasPermission()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('未获取录音权限'),
              ),
            );
          }
          return;
        }

        // 首先获取设备外部存储管理权限，如果没有存储权限，就不可录音，直接返回
        // 2024-08-03 ？？？有问题，授权之后，因为已经松开长按了，所以就不会触发取消长按时的发送操作了
        if (!(await requestStoragePermission())) {
          EasyLoading.showError("未授权访问设备外部存储，无法录音");

          return;
        }

        print("没存储权限应该不能打印-----------");

        // 显示语音输入UI
        _showRecordingMask();

        // 录制
        _soundsRecorder.beginRec(
          onStateChanged: (state) {
            debugPrint('________  onStateChanged: $state ');
          },
          onAmplitudeChanged: (amplitude) {
            // debugPrint(
            //     '________  onAmplitudeChanged: ${amplitude.current} , ${amplitude.max} ');
          },
          onDurationChanged: (duration) {
            debugPrint('________  onDurationChanged: $duration ');
          },
          onCompleted: (path, duration) {
            // _removeMask();

            debugPrint('________  onCompleted: $path , $duration ');

            if (duration.inSeconds < 1) {
              _removeMask();
              showDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: const Text('录制时间过短'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('确定'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
              return;
            }

            // 录制状态松开/超过时长 直接发送语音内容
            if (_soundsRecorder.status.value == SoundsMessageStatus.recording) {
              widget.onSendSounds?.call(SendContentType.voice, path!);
              _removeMask();
            }
            // 取消发送
            else if (_soundsRecorder.status.value ==
                SoundsMessageStatus.canceling) {
              _removeMask();
            }
            // 转文字时完成语音输入，则包含额外的选择操作
            else if (_soundsRecorder.status.value ==
                SoundsMessageStatus.textProcessing) {
              _soundsRecorder.updateStatus(SoundsMessageStatus.textProcessed);
              // _removeMask();
            }

            // 语音转文字结束状态，通过按钮触发具体的发送内容
            // else if (_soundsRecorder.status.value ==
            //     SoundsMessageStatus.textProcessed) {
            //   // widget.onSendSounds?.call(path!);
            // }
          },
        );
      },
      onLongPressMoveUpdate: (details) {
        // 录音状态下的手势移动处理
        if (_soundsRecorder.status.value == SoundsMessageStatus.none) {
          return;
        }
        final offset = details.globalPosition;
        if ((scSize.height - offset.dy.abs()) >
            widget.maskData.sendAreaHeight) {
          final cancelOffset = offset.dx < scSize.width / 2;
          if (cancelOffset) {
            _soundsRecorder.updateStatus(SoundsMessageStatus.canceling);
          } else {
            _soundsRecorder.updateStatus(SoundsMessageStatus.textProcessing);
          }
        } else {
          _soundsRecorder.updateStatus(SoundsMessageStatus.recording);
        }
      },
      onLongPressEnd: (details) async {
        // 手势结束音频
        _soundsRecorder.endRec();
      },
      child: ValueListenableBuilder(
        valueListenable: _soundsRecorder.status,
        builder: (context, value, child) {
          if (widget.builder != null) {
            return widget.builder?.call(context, value);
          }

          return Container(
            // margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            // height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 1.0),
              boxShadow: const [
                BoxShadow(color: Color(0xffeeeeee), blurRadius: 2)
              ],
            ),
            child: Text(
              value.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
