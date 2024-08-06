// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../common/constants.dart';

enum SendContentType {
  voice,
  text,
}

enum SoundsMessageStatus {
  /// 默认状态 未交互/交互完成
  none,

  /// 录制
  recording,

  /// 取消录制
  canceling,

  /// 语音转文字
  textProcessing,

  /// 语音转文字 - 管理操作
  textProcessed;

  String get title {
    switch (this) {
      case none:
        return '按住 说话';
      case recording:
        return '松开 发送';
      case canceling:
        return '松开 取消';
      case textProcessing:
      case textProcessed:
        return '转文字';
    }
  }
}

/// 录音类
class SoundsRecorderController {
  SoundsRecorderController();

  /// 修改语音转文字的内容
  final TextEditingController textProcessedController = TextEditingController();

  /// 是否完成了语音转文字的操作
  bool isTranslated = false;

  /// 音频地址
  final path = ValueNotifier<String?>('');

  /// 录音操作的状态
  final status = ValueNotifier(SoundsMessageStatus.none);

  /// 当前区间间隔的音频振幅
  // final amplitude = ValueNotifier<Amplitude>(Amplitude(current: 0, max: 1));

  /// 录音操作时间内的音频振幅集合，最新值在前
  /// [0.0 ~ 1.0]
  final amplitudeList = ValueNotifier<List<double>>([]);

  RecorderController? recorderController;
  // StreamSubscription<RecordState>? _recordSub;
  // StreamSubscription<Amplitude>? _amplitudeSub;

  final duration = ValueNotifier<Duration>(Duration.zero);
  Timer? _timer;

  /// 开始录制前就已经结束
  /// 用于录音还未开始，用户就已经松开手指结束录制的特殊情况
  //  bool beforeEnd = false;
  /// 用途同上
  Function(String? path, Duration duration)? _onAllCompleted;

  /// 录制
  beginRec({
    /// 录制状态
    ValueChanged<RecorderState>? onStateChanged,

    /// 音频振幅
    ValueChanged<List<double>>? onAmplitudeChanged,

    /// 录制时间
    ValueChanged<Duration>? onDurationChanged,

    /// 结束录制
    /// 录制时长超过60s时，自动断开的处理
    required Function(String? path, Duration duration) onCompleted,
  }) async {
    try {
      reset();

      _onAllCompleted = onCompleted;

      // recorderController = RecorderController()
      //   ..androidEncoder = AndroidEncoder.aac
      //   ..androidOutputFormat = AndroidOutputFormat.mpeg4
      //   ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      //   ..sampleRate = 44100;

      /// 2024-08-03 配合讯飞语音听写的格式（好像无法直接支持，只能转码）
      /// https://www.xfyun.cn/doc/asr/voicedictation/API.html
      recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 16000;

      updateStatus(SoundsMessageStatus.recording);

      // 录制状态
      recorderController?.onRecorderStateChanged.listen((state) {
        onStateChanged?.call(state);
      });

      // 时间间隔
      recorderController?.onCurrentDuration.listen((value) {
        duration.value = value;

        if (value.inSeconds >= 60) {
          endRec();
        }

        onDurationChanged?.call(value);

        amplitudeList.value = recorderController!.waveData.reversed.toList();
        print(duration);
      });

      // 外部存储权限的获取在按下说话按钮前就判断了，能到这里来一定是有权限了
      // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
      if (!await CHAT_AUDIO_DIR.exists()) {
        await CHAT_AUDIO_DIR.create(recursive: true);
      }
      final file = File(
        '${CHAT_AUDIO_DIR.path}/${DateTime.now().microsecondsSinceEpoch}.m4a',
      );

      // 录制
      await recorderController!.record(path: file.path); // Path is optional
    } catch (e) {
      debugPrint(e.toString());
    } finally {}
  }

  /// 停止录音
  Future endRec() async {
    // 2024-08-03 首次按住说话可以会弹出请求录音许可，此时还没有录音控制器，所以要先判断录音控制器是否存在
    if (recorderController != null && recorderController!.isRecording) {
      path.value = await recorderController!.stop();

      // 需要转为pcm让讯飞能够识别（但播放时，pcm就无法播放了）
      var time = path.value?.split("/").last.split(".").first;
      final pcmPath = '${CHAT_AUDIO_DIR.path}/$time.pcm';

      print("转换后的地址--$pcmPath");

      if (path.value?.isNotEmpty == true) {
        debugPrint(path.value);
        debugPrint("Recorded file size: ${File(path.value!).lengthSync()}");

        // 停止录制后，音频转个码，讯飞才能识别
        await convertToPcm(
          inputPath: path.value!,
          outputPath: pcmPath,
          sampleRate: 16000,
        );
      }

      _onAllCompleted?.call(path.value, duration.value);
      // 返回的是转码后的文件路径
      // _onAllCompleted?.call(pcmPath, duration.value);
    } else {
      _onAllCompleted?.call(null, Duration.zero);
    }
    reset();
  }

  /// 重置
  // reset() {
  //   _timer?.cancel();
  //   duration.value = Duration.zero;
  //   recorderController?.dispose();
  // }

  /// 重置
  /// 2024-08-03 原作者的写法会在后续录制时出现错误：A ValueNotifier<int> was used after being disposed.
  /// 看起来就是重置时控制器被释放了，后续再使用时就不是同一个
  /// 在SoundsMessageButton有使用到释放控制器，所以拆成2个方法
  reset() {
    _timer?.cancel();
    duration.value = Duration.zero;
  }

  dispose() {
    recorderController?.dispose();
  }

  /// 权限
  Future<bool> hasPermission() async {
    final state = await Permission.microphone.request();

    return state == PermissionStatus.granted;
  }

  /// 更新状态
  updateStatus(SoundsMessageStatus value) {
    status.value = value;
  }

  /// 语音转文字
  void updateTextProcessed(String text) {
    isTranslated = true;
    textProcessedController.text = text;
  }
}

// 讯飞识别时需要pcm
Future<void> convertToPcm({
  required String inputPath,
  required String outputPath,
  required int sampleRate,
}) async {
  final command = '-i $inputPath -ac 1 -ar $sampleRate -f s16le $outputPath';
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    throw Exception('FFmpeg conversion failed');
  }
}

// 播放时，转换后的pcn audio_waveforms 无法播放，又得转回去
Future<void> convertToM4a({
  required String inputPath,
  required String outputPath,
}) async {
  final command = '-f s16le -ar 16000 -ac 1 -i $inputPath $outputPath';
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    throw Exception('FFmpeg conversion failed');
  }
}
