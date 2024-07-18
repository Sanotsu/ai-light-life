import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

import '../../../common/constants.dart';
import '../../../common/utils/tools.dart';

class MarkdownToTextConverter extends StatefulWidget {
  // 需要传入markdown文本字符串
  final String mdString;

  const MarkdownToTextConverter(this.mdString, {super.key});

  @override
  State createState() => _MarkdownToTextConverterState();
}

class _MarkdownToTextConverterState extends State<MarkdownToTextConverter> {
  Future<void> _saveAsText() async {
    // 首先获取设备外部存储管理权限
    if (!(await requestStoragePermission())) {
      return EasyLoading.showError("未授权访问设备外部存储，无法保存文档");
    }

    // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
    if (!await SAVE_TRANSLATION_DIR.exists()) {
      await SAVE_TRANSLATION_DIR.create(recursive: true);
    }

    try {
      // 将字符串直接保存为指定路径文件
      final file = File(
        '${SAVE_TRANSLATION_DIR.path}/保存拍照翻译文档-${DateTime.now().microsecondsSinceEpoch}.txt',
      );
      await file.writeAsString(widget.mdString.trim());
      if (!mounted) return;

      // 保存成功/失败弹窗提示
      EasyLoading.showSuccess(
        '文件已保存到 ${file.path}',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      return EasyLoading.showError(
        "保存文档失败: ${e.toString()}",
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("预览翻译结果(TXT)"),
        actions: [
          ElevatedButton(
            onPressed: _saveAsText,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 5,
              margin: EdgeInsets.all(10.sp),
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: SingleChildScrollView(
                  child: Text(widget.mdString.trim()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
