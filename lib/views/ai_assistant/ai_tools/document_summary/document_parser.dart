// ignore_for_file: avoid_print

import 'dart:io';

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
