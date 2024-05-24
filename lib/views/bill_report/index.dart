import 'package:flutter/material.dart';

class BillReportIndex extends StatefulWidget {
  const BillReportIndex({super.key});

  @override
  State<BillReportIndex> createState() => _BillReportIndexState();
}

class _BillReportIndexState extends State<BillReportIndex> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("账单报表"),
      ),
      body: const Center(
        child: Text("账单报表--"),
      ),
    );
  }
}
