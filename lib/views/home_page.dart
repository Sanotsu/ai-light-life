// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accounting/index.dart';
import 'agi_llm_sample/index.dart';
import 'user_and_settings/backup_and_restore/index.dart';
import 'random_dish/dish_wheel_index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AgiLlmSample(),
    BillItemIndex(),
    DishWheelIndex(),
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
        // final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("退出确认"),
              content: const Text("确认退出AI聊天和记账吗？"),
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
          // if (navigator.canPop()) {
          //   navigator.pop();
          // } else {
          //   // 如果已经到头来，则关闭应用程序
          //   SystemNavigator.pop();
          // }

          // 2024-05-29 已经到首页了，直接退出
          SystemNavigator.pop();
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
              icon: Icon(Icons.bolt),
              label: "智能助手",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: "极简记账",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: "随机菜品",
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
        drawer: Drawer(
          // 将ListView添加到抽屉中。这确保了如果没有足够的垂直空间容纳所有东西，用户可以滚动抽屉中的选项。
          child: ListView(
            // 从ListView中删除任何内边距填充。
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('个人中心(占位)'),
              ),
              ListTile(
                title: const Text('智能对话'),
                selected: _selectedIndex == 0,
                onTap: () {
                  // 更新选中页面
                  _onItemTapped(0);
                  // 关闭抽屉
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('极简记账'),
                selected: _selectedIndex == 1,
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('备份恢复'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupAndRestore(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
