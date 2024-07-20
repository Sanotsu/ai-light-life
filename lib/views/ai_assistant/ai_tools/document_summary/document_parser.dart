// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

var l = Logger();

Future<String?> parsePdf(String path) async {
  try {
    // 加载整个pdf文件.
    final pdfDocument = PdfDocument(inputBytes: await File(path).readAsBytes());
    // 获取pdf中所有的文本
    String text = PdfTextExtractor(pdfDocument).extractText();
    // 处理完之后释放文档
    pdfDocument.dispose();

    print("text----${text.length}");

    return text;
  } catch (e) {
    print("error----${e.toString()}");
    rethrow;
  }
}

// 实测直接获取文档全部内容，可能会挤在一起，单词都无法区分开了
String? parsePdfSync(String path) {
  try {
    final pdfDocument = PdfDocument(inputBytes: File(path).readAsBytesSync());
    String text = PdfTextExtractor(pdfDocument).extractText();
    pdfDocument.dispose();
    print("parsePdfSync text----${text.length}");
    return text;
  } catch (e) {
    print("parsePdfSync error----${e.toString()}");
    rethrow;
  }
}

String? parsePdfLinesSync(String path) {
  try {
    final pdfDocument = PdfDocument(inputBytes: File(path).readAsBytesSync());

    // 从文档中提取文本行集合
    final textLines = PdfTextExtractor(pdfDocument).extractTextLines();

    var text = "";
    for (var line in textLines) {
      text += line.text;
    }

    pdfDocument.dispose();
    print("parsePdfLinesSync text----${text.length}");
    return text;
  } catch (e) {
    print("parsePdfLinesSync error----${e.toString()}");
    rethrow;
  }
}

Future<String?> readFileContent(PlatformFile file) async {
  try {
    switch (file.extension) {
      case 'txt':
        // return File(file.path!).readAsString();

        // 目前只看utf8的
        var bytes = File(file.path!).readAsBytesSync();
        var aa = utf8.decode(bytes, allowMalformed: true);
        l.i(aa);
        return aa;

      case 'pdf':
        final pdfDocument =
            PdfDocument(inputBytes: File(file.path!).readAsBytesSync());

        // 从文档中提取文本行集合
        final textLines = PdfTextExtractor(pdfDocument).extractTextLines();

        var text = "";
        for (var line in textLines) {
          text += line.text;
        }

        pdfDocument.dispose();
        return text;
      case 'docx':
        final bytes = await File(file.path!).readAsBytes();
        final text = docxToText(bytes);

        l.i('DOCX 解析出来的内容：$text');

        return text;
      // 2024-07-20 如果上层使用了compute来后台处理，这个插件就会报错：
      // Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until
      // BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
      // 为了能正常显示loading圈，就暂时不支持这个doc文档的解析了
      // case 'doc':
      //   String? extractedText =
      //       await DocText().extractTextFromDoc(file.path!);

      //   if (extractedText != null) {
      //     l.i('DOC解析出来的内容：$extractedText');

      //     return extractedText;
      //   } else {
      //     l.e('Failed to extract text from document.');
      //     return null;
      //   }

      default:
        return null;
    }
  } catch (e) {
    l.e("解析文档出错:${e.toString()}");
    rethrow;
  }
}
