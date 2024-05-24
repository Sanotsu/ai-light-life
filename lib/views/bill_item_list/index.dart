// ignore_for_file: avoid_print
import 'dart:ui' as ui;

import 'package:bottom_picker/bottom_picker.dart';
import 'package:bottom_picker/resources/arrays.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../common/components/tool_widget.dart';
import '../../common/constants.dart';
import '../../common/utils/db_helper.dart';
import '../../models/brief_accounting_state.dart';
import 'mock_data/index.dart';

class BillItemIndex extends StatefulWidget {
  const BillItemIndex({super.key});

  @override
  State<BillItemIndex> createState() => _BillItemIndexState();
}

class _BillItemIndexState extends State<BillItemIndex> {
  final DBHelper _dbHelper = DBHelper();

  // 单纯的账单条目列表
  List<BillItem> billItems = [];
  // 按日分组后的账单条目对象(key是日期，value是条目列表)
  Map<String, List<BillItem>> billItemGroupByDayMap = {};

  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 账单可查询的范围，默认为当前，查询到结果之后更新
  SimplePeriodRange billPeriod = SimplePeriodRange(
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
  );
  // 被选中的月份(yyyy-MM格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedMonth = DateFormat(constMonthFormat).format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadBillItemData();

    _loadDateRange();

    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  _loadDateRange() async {
    var tempPeriod = await _dbHelper.queryDateRangeList();
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  /// 2024-05-23 这里的加载更多不应该和之前默认查询10条，加载完上滑时加载更多。
  /// 最简单的，获取系统当月的所有账单条目查询出来(这样每日、月度统计就是正确的)，
  /// 下滑显示完当月数据化，加载上一个月的所有数据出来
  /// 即默认情况下，一个月一个月地加载
  /// 【也正是基于统计的原因，是否保留关键字筛选？？？】
  Future<void> _loadBillItemData() async {
    print("进入了_loadBillItemData-------------");

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp = await _dbHelper.queryBillItemList(
      // 按月查询，自动补上起止日期？？？
      startDate: "$selectedMonth-01",
      endDate: "$selectedMonth-31",
      itemKeyword: query,
      page: 1,
      pageSize: 0,
    );

    var newData = temp.data as List<BillItem>;

    setState(() {
      billItems.addAll(newData);
      billItemGroupByDayMap = groupBy(billItems, (item) => item.date);

      isLoading = false;
    });
  }

  // 查询月度统计
  // ？？？年度统计再看列表详情的话比较奇怪，和微信类似，多个年度统计tab，换个页面查询统计
  Future<List<BillPeriodCount>?> _loadBillCountData() async {
    try {
      return await _dbHelper.queryBillCountList(
        startDate: "$selectedMonth-01",
        endDate: "$selectedMonth-31",
      );
    } catch (e) {
      print(e);
      return null;
    }
  }

  // 滑动到底部或者底部加载更多
  // ？？？还有个小问题，就是当前月份的记录没有堆满页面时，上拉或者下拉不会加载更多
  // 这里应该使用手势等其他方式来触发
  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;
    final atEdge = scrollController.position.atEdge;
    final outOfRange = scrollController.position.outOfRange;

    // 注意，滚动到底部和顶部时，需要获取上一个月或下一个月的账单条目；
    // 但是已经达到了账单记录的最大日期和最小日期月份，则不再加载了。
    if (atEdge && currentPosition == 0) {
      // 滚动到顶部
      print("到顶部了 ${DateTime(2023, 2, 31)} ${DateTime.tryParse("2023-2-31")}");

      DateTime date = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
      String nextMonth = DateFormat(constMonthFormat).format(
        DateTime(date.year, date.month + 1, date.day),
      );

      // 如果当前月份的下一月的1号已经账单中最大日期了，到顶了也不再加载
      if ((DateTime(date.year, date.month + 1, date.day))
          .isAfter(billPeriod.maxDate)) {
        print("滚动到顶部，但已经到了账单【最新】的月份了，没有更【新】的数据可查了");

        return;
      }

      print("到顶部了，当前选中的日期$selectedMonth 下个月$nextMonth  ");

      setState(() {
        selectedMonth = nextMonth;
        _loadBillItemData();
      });
    } else if (atEdge &&
        !outOfRange &&
        scrollController.offset >= maxScrollExtent) {
      // 滚动到底部，查询下一个月的

      // 当前月数据到底了，再滚动就取上一个月的数据了(选中的日期格式化为年月了，反格式化要补day,否则是null，就取now了)
      DateTime date =
          DateTime.tryParse("$selectedMonth-01 00:00:01") ?? DateTime.now();
      String lastMonth = DateFormat(constMonthFormat).format(
        DateTime(date.year, date.month - 1, date.day),
      );

      // 如果当前月份的1号已经账单中最大日期了，到顶了也不再加载
      // ???这里的比较其实有问题，2023-02-01 > 2023-02-12 时成立的
      if (date.isBefore(billPeriod.minDate)) {
        print("滚动到底部，但已经到了账单【最旧】的月份了，没有更【旧】的数据可查了");
        return;
      }

      print("到底了，当前选中的日期$selectedMonth $date 上个月$lastMonth ");
      setState(() {
        selectedMonth = lastMonth;
        _loadBillItemData();
      });
    }
  }

  void _handleSearch() {
    setState(() {
      billItems.clear();
      query = searchController.text;
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    _loadBillItemData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      // 这里也可以不用appbar？？？
      appBar: AppBar(
        title: const Text("账单列表"),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() {
                billItems.clear();
                isLoading = true;
              });

              await loadUserFromAssets();

              setState(() {
                isLoading = false;
              });
              _loadBillItemData();
            },
            child: const Text("Mock"),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
            /// 本页面不要appbar的话，这范围要给点富裕的高度
            buildMonthCountRow(),

            /// 条目关键字搜索行
            buildSearchRow(),

            /// 构建收支条目列表
            buildBillItemList(),
          ],
        ),
      ),
    );
  }

  /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
  buildMonthCountRow() {
    return Container(
      height: 50.sp,
      color: Colors.amber, // 显示占位用
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              width: 100.sp,
              // 按钮带标签默认icon在前面，所以使用方向组件改变方向
              // 又因为ui和intl都有TextDirection类，所以显示什么ui的导入
              child: Directionality(
                textDirection: ui.TextDirection.rtl,
                child: TextButton.icon(
                  onPressed: () {
                    // openDatePicker(context);

                    showMonthPicker(
                      context: context,
                      firstDate: billPeriod.minDate,
                      lastDate: billPeriod.maxDate,
                      initialDate: DateTime.tryParse("$selectedMonth-01"),
                      // 一定要先选择年
                      yearFirst: true,
                      // customWidth: 1.sw,
                      // 不缩放默认title会溢出
                      textScaleFactor: 0.9, // 但这个比例不同设备怎么控制？？？
                      // 不显示标头，只能滚动选择
                      // hideHeaderRow: true,
                    ).then((date) {
                      if (date != null) {
                        setState(() {
                          print(date);
                          selectedMonth =
                              DateFormat(constMonthFormat).format(date);
                          _handleSearch();
                        });
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_drop_down),
                  label: Text(
                    selectedMonth,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildBillCountTile(),
          ),
        ],
      ),
    );
  }

  /// 条目关键字搜索行
  buildSearchRow() {
    return Container(
      height: 50.sp,
      color: Colors.amberAccent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(4.sp, 0, 4, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "输入关键字进行查询",
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  // border: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(10.0),
                  // ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: _handleSearch,
                child: const Text("搜索"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 构建收支条目列表
  /// 注意：其实这里每日的分组统计也是有瑕疵的。
  /// 比如因为一次性查询10条，某一天的消费有11条，或者从第9条开始到第13条结束，
  /// 那么在没有继续滚动到完全加载，每日累积值是错误的。
  /// 也是基于此，不从billitemlist中分组统计月度、年度数据
  buildBillItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: billItemGroupByDayMap.entries.length,
        itemBuilder: (context, index) {
          if (index == billItemGroupByDayMap.entries.length) {
            return buildLoader(isLoading);
          } else {
            return _buildBillItemCard(index);
          }
        },
        controller: scrollController,
      ),
    );
  }

  _buildBillItemCard(int index) {
    // 获取当前分组的日期和账单项列表
    var entry = billItemGroupByDayMap.entries.elementAt(index);
    String date = entry.key;
    List<BillItem> itemsForDate = entry.value;

    // // 计算每天的总花费
    // var totalExpand = itemsForDate.fold(0.0, (sum, item) {
    //   if (item.itemType != 0) {
    //     // 如果是支出，则累加支出
    //     return sum + item.value;
    //   } else {
    //     // 没有支出则不累加
    //     return sum;
    //   }
    // });

    // var totalIncome = itemsForDate.fold(0.0, (sum, item) {
    //   // 如果当日有收入，累积收入
    //   if (item.itemType == 0) {
    //     return sum + item.value;
    //   } else {
    //     // 没有收入则不累加
    //     return sum;
    //   }
    // });

    // 上面的其实更简单的一次遍历即可
    double totalExpand = 0.0;
    double totalIncome = 0.0;
    for (var item in itemsForDate) {
      if (item.itemType != 0) {
        totalExpand += item.value;
      } else {
        totalIncome += item.value;
      }
    }

    print("total expand--$totalExpand income $totalIncome");

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('日期: $date'),
            trailing: Text(
              '支出 ¥$totalExpand 收入 ¥$totalIncome',
            ),
            tileColor: Colors.lightGreen,
            dense: true,
            // 可以添加副标题或尾随图标等
          ),
          const Divider(), // 可选的分隔线
          // 为每个BillItem创建一个Tile
          Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: itemsForDate.map((item) {
                return ListTile(
                  title: Text(item.item),
                  trailing: Text(
                    '${item.itemType == 0 ? '+' : '-'}${item.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: item.itemType != 0 ? Colors.black : Colors.green,
                    ),
                  ),
                  // 可以添加其他信息，如时间戳等
                );
              }).toList(),
            ).toList(),
          ),
        ],
      ),
    );
  }

  // 这个下方滚动选择日期比较好，但是不能仅年月
  openDatePicker(BuildContext context) {
    BottomPicker.date(
      pickerTitle: const Text(
        '',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.blue,
        ),
      ),
      dateOrder: DatePickerDateOrder.ymd,
      initialDateTime: DateTime.now(),
      maxDateTime: DateTime(1998),
      minDateTime: DateTime(1980),
      pickerTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      onChange: (index) {
        print(index);
      },
      onSubmit: (index) {
        print(index);
      },
      bottomPickerTheme: BottomPickerTheme.plumPlate,
    ).show(context);
  }

  // 这里是月度账单下拉后查询的总计结果，理论上只存在1条，不会为空。
  _buildBillCountTile() {
    return FutureBuilder<List<BillPeriodCount>?>(
      future: _loadBillCountData(),
      builder: (BuildContext context,
          AsyncSnapshot<List<BillPeriodCount>?> snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          var list = snapshot.data!;
          if (list.isNotEmpty) {
            children = <Widget>[
              Text(
                  "支出 ¥${list[0].expandTotalValue}  收入 ¥${list[0].incomeTotalValue}"),
            ];
          } else {
            children = <Widget>[
              const Text("该月份无账单"),
            ];
          }
          // 有数据
        } else if (snapshot.hasError) {
          // 有错误
          children = <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 30),
          ];
        } else {
          // 加载中
          children = const <Widget>[
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator()),
          ];
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}
