// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';

///
/// 将md文本转为pdf并下载
/// 1 首先，预览的pdf和转换后的pdf可能格式会有一些出入
///   因为pdf是解析md文件，然后一条一条重新绘制的
/// 2 其次，解析md得到的node，不一定和原版md文件就能一一对应上
///
class MarkdownToPdfConverter extends StatefulWidget {
  // 需要传入markdown文本字符串
  final String mdString;
  final File imageFile;

  const MarkdownToPdfConverter(
    this.mdString, {
    super.key,
    required this.imageFile,
  });

  @override
  State createState() => _MarkdownToPdfConverterState();
}

class _MarkdownToPdfConverterState extends State<MarkdownToPdfConverter> {
  // String _markdownData = '';

  // @override
  // void initState() {
  //   super.initState();
  //   _loadMarkdownData();
  // }

  // Future<void> _loadMarkdownData() async {
  //   String data = await rootBundle.loadString('assets/bak_md_doc.md');
  //   setState(() {
  //     _markdownData = data;
  //   });
  // }

  Future<void> _saveAsPdf() async {
    print("传入pdf的markdown文本 --${widget.mdString}");

    final pdfDoc = pdf.Document(
      pageMode: PdfPageMode.fullscreen,
      theme: pdf.ThemeData.withFont(
        // 谷歌字体不一定能够访问,但肯定是联网下载，且存在内存中，下一次导出会需要重新下载
        // https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
        // base: await PdfGoogleFonts.notoSerifHKRegular(),
        // bold: await PdfGoogleFonts.notoSerifHKBold(),
        // 但是使用知道的本地字体，会增加app体积
        base: pdf.Font.ttf(await rootBundle.load("assets/MiSans-Regular.ttf")),
        fontFallback: [
          pdf.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf'))
        ],
      ),
    );

    print("widget.imageBytes--${widget.imageFile}");

    // ??? 2024-07-18 实测这里没法正确处理多级列表，会把下一级的合到第一级去
    final List<md.Node> nodes = md.Document().parse(widget.mdString);
    final List<pdf.Widget> widgets = nodes.map((node) {
      print("node--$node  --${(node as md.Element).tag} --${node.textContent}");
      return _buildPdfWidget(node);
    }).toList();

    pdfDoc.addPage(
      pdf.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pdf.Context context) {
          return pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Center(
                // 上方显示图片
                child: pdf.Image(
                  pdf.MemoryImage(
                    widget.imageFile.readAsBytesSync(),
                  ),
                ),
              ),
              pdf.SizedBox(height: 20),
              // 下面显示翻译后的文本
              ...widgets,
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfDoc.save(),
      // 设置默认文件名
      name: '保存拍照翻译文档-${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
  }

  pdf.Widget _buildPdfWidget(md.Node node, [int indent = 0]) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'p':
          return pdf.Padding(
            padding: const pdf.EdgeInsets.only(bottom: 10),
            child: pdf.Text(node.textContent,
                style: const pdf.TextStyle(fontSize: 12)),
          );
        case 'h1':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 24, fontWeight: pdf.FontWeight.bold),
          );
        case 'h2':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 22, fontWeight: pdf.FontWeight.bold),
          );
        case 'h3':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 20, fontWeight: pdf.FontWeight.bold),
          );
        case 'h4':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 18, fontWeight: pdf.FontWeight.bold),
          );
        case 'h5':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 16, fontWeight: pdf.FontWeight.bold),
          );
        case 'h6':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 14, fontWeight: pdf.FontWeight.bold),
          );
        case 'ul':
        case 'ol':
          return pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: node.children!
                .map((child) => _buildPdfWidget(child, indent + 1))
                .toList(),
          );
        case 'li':
          return pdf.Row(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text('· ' * indent, style: const pdf.TextStyle(fontSize: 12)),
              pdf.Expanded(
                child: pdf.Text(
                  node.textContent,
                  style: const pdf.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        case 'pre':
          return pdf.Container(
            width: double.infinity,
            padding: const pdf.EdgeInsets.all(10),
            color: PdfColors.grey100,
            child: pdf.Text(
              // 代码中有html转义符，需要先转回来
              HtmlUnescape().convert(node.textContent),
              style: pdf.TextStyle(fontSize: 12, font: pdf.Font.courier()),
            ),
          );
        case 'code':
          return pdf.Text(
            node.textContent,
            style: pdf.TextStyle(fontSize: 12, font: pdf.Font.courier()),
          );
        default:
          return pdf.Text(
            node.textContent,
            style: const pdf.TextStyle(fontSize: 12),
          );
      }
    } else if (node is md.Text) {
      return pdf.Text(node.text, style: const pdf.TextStyle(fontSize: 12));
    }
    return pdf.SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("预览翻译结果(PDF)"),
        actions: [
          ElevatedButton(
            onPressed: _saveAsPdf,
            child: const Text('保存'),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(child: Text("部分语言(如繁体中文)保存PDF时暂不支持")),
          Expanded(
            child: Card(
              elevation: 5,
              margin: EdgeInsets.all(10.sp),
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: Markdown(
                  data: widget.mdString,
                  // data: _markdownData,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
