// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bill_item_list/index.dart';
import 'bill_report/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    BillItemIndex(),
    BillReportIndex(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvoked: (didPop) async {
        print("didPop-----------$didPop");
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("确认退出?"),
              content: const Text("确认退出app吗？"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("确认"),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          // 如果还有可以关闭的导航，则继续pop
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            // 如果已经到头来，则关闭应用程序
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        // 这外面有appbar，其实内部页面不应该是Scaffold？？？
        // appBar: AppBar(
        //   title: const Text("这里外面有appbar"),
        // ),
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        // backgroundColor: Colors.red,
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

        // 两种底部导航条
        bottomNavigationBar: BottomNavigationBar(
          // 当item数量小于等于3时会默认fixed模式下使用主题色，大于3时则会默认shifting模式下使用白色。
          // 为了使用主题色，这里手动设置为fixed
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: "账单",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: "图表",
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
        // 底部居中的悬浮按钮
        floatingActionButton: FloatingActionButton(
          //悬浮按钮
          child: const Icon(Icons.add),
          onPressed: () {},
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
