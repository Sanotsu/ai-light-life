// ignore_for_file: avoid_print
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../common/constants.dart';
import '../../common/utils/db_helper.dart';
import '../../models/brief_accounting_state.dart';

class BillReportIndex extends StatefulWidget {
  const BillReportIndex({super.key});

  @override
  State<BillReportIndex> createState() => _BillReportIndexState();
}

class _BillReportIndexState extends State<BillReportIndex>
    with SingleTickerProviderStateMixin {
  late TooltipBehavior _tooltip;

  final DBHelper _dbHelper = DBHelper();
  // 定义TabController
  late TabController _tabController;

  // 账单可查询的范围，默认为当前，查询到结果之后更新
  SimplePeriodRange billPeriod = SimplePeriodRange(
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
  );

  ///
  /// 月度统计相关的变量
  ///
  // 被选中的月份(yyyy-MM格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedMonth = DateFormat(constMonthFormat).format(DateTime.now());
  late List<BillPeriodCount> monthCounts = [];
  late List<BillItem> monthBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isExpendClick = true;

  ///
  /// 年度统计相关的变量
  ///
  // 被选中的年份(yyyy格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  // 本来想复用选中的月份，但参考微信账单是各管各的，所以多个变量
  String selectedYear = DateFormat.y().format(DateTime.now());
  late List<BillPeriodCount> yearCounts = [];
  late List<BillItem> yearBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isYearExpendClick = true;

  @override
  void initState() {
    _tooltip = TooltipBehavior(enable: true);

    // 初始化TabController
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    // 监听Tab切换
    _tabController.addListener(_handleTabSelection);

    _loadDateRange();

    getMonthCount();
    getMonthBillItemList();

    getYearCount();
    getYearBillItemList();
    super.initState();
  }

  _loadDateRange() async {
    var tempPeriod = await _dbHelper.queryDateRangeList();
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 获取指定月的统计数据(参考微信是指定月前后一起半年数据，做柱状图)
  getMonthCount() async {
    // 选中2023-04
    // date 2023-04-01 00:00:01
    DateTime date =
        DateTime.tryParse("$selectedMonth-01 00:00:01") ?? DateTime.now();

    // DateTime date = DateTime.tryParse("2023-04-01 00:00:01") ?? DateTime.now();

    // start=2023-02-01 00:00:01
    var startDate = DateTime(date.year, date.month - 2, date.day);

    // end=2023-07-01 00:00:01
    var endDate = DateTime(date.year, date.month + 3, date.day);
    // 如果查询的终止范围超过最新的月份，则修正终止月份为当前月份
    if (endDate.isAfter(billPeriod.maxDate)) {
      endDate = billPeriod.maxDate;
      startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
    }

    String start = DateFormat(constMonthFormat).format(startDate);
    String end = DateFormat(constMonthFormat).format(endDate);

    print("-----------$start $end");

    var temp = await _dbHelper.queryBillCountList(
      countType: "month",
      startDate: "$start-01",
      endDate: "$end-31",
    );
    print("-----------$temp");
    setState(() {
      monthCounts = temp;
    });
  }

  // 获取指定年的统计数据(只查当年数据，不做图表)
  getYearCount() async {
    DateTime date = DateTime.tryParse("$selectedYear-01-01") ?? DateTime.now();
    var startDate = DateTime(date.year - 1, date.month, date.day);
    var endDate = DateTime(date.year + 1, date.month, date.day);
    // 如果查询的终止范围超过最新的月份，则修正终止月份为当前月份
    // 起值超过了有记录的年份，返回结果统计时不会有该年份，柱状图就知道有记录的起止
    if (endDate.isAfter(billPeriod.maxDate)) {
      endDate = billPeriod.maxDate;
      startDate = DateTime(endDate.year - 2, endDate.month, endDate.day);
    }

    String start = DateFormat.y().format(startDate);
    String end = DateFormat.y().format(endDate);

    var temp = await _dbHelper.queryBillCountList(
      countType: "year",
      startDate: "$start-01-01",
      endDate: "$end-12-31",
    );
    print("getYearCount-----------$temp");
    setState(() {
      yearCounts = temp;
    });
  }

  // 获取指定月的详细数据
  getMonthBillItemList() async {
    var temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedMonth-01",
      endDate: "$selectedMonth-31",
      page: 1,
      pageSize: 0,
    );
    var newData = temp.data as List<BillItem>;

    var a = monthCounts.firstWhere((e) => e.period == selectedMonth);

    print("newDatanewData-----------$a");
    setState(() {
      monthBillItems = newData;
    });
  }

  // 获取指定月的详细数据
  getYearBillItemList() async {
    var temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedYear-01-01",
      endDate: "$selectedYear-12-31",
      page: 1,
      pageSize: 0,
    );
    var newData = temp.data as List<BillItem>;

    setState(() {
      yearBillItems = newData;
    });
  }

  void _handleSelectedMonthChange() {
    setState(() {
      monthCounts.clear();
      monthBillItems.clear();
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();
    getMonthCount();
    getMonthBillItemList();
  }

  void _handleSelectedYearChange() {
    setState(() {
      yearCounts.clear();
      yearBillItems.clear();
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();
    getYearCount();
    getYearBillItemList();
  }

  ///
  /// 处理Tab切换
  ///
  _handleTabSelection() {
    // 如果是切换了月度统计和年度统计，都重置被选中月份为当前月份
    if (_tabController.index == 1) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          // title: const Text('TabBar Sample'),
          // AppBar的preferredSize默认是固定的（对于标准AppBar来说是kToolbarHeight,56）
          // 如果不显示title，可以适当减小
          toolbarHeight: kToolbarHeight - 36,
          title: null,
          bottom: TabBar(
            controller: _tabController,
            // 让tab按钮两边留空，更居中一点
            padding: EdgeInsets.symmetric(horizontal: 0.25.sw, vertical: 5.sp),
            tabs: const <Widget>[
              Tab(
                text: "月账单",
              ),
              Tab(
                text: "年账单",
                // icon: Icon(Icons.brightness_5_sharp),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            buildMonthCountTab(),
            buildYearCountTab(),
          ],
        ),
      ),
    );
  }

  ///
  ///
  /// 月度账单的相关组件
  ///
  buildMonthCountTab() {
    return Column(
      children: [
        buildMonthChangeRow(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildMonthCountRow(),
                buildBarChart(),
                buildRankingList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
  buildMonthChangeRow() {
    return Container(
      height: 36.sp,
      color: Colors.amber, // 显示占位用
      child: Row(
        children: [
          Expanded(
            flex: 2,
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
                          _handleSelectedMonthChange();
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
            child: ElevatedButton(
              onPressed: isExpendClick
                  ? null
                  : () {
                      setState(() {
                        isExpendClick = !isExpendClick;
                      });
                    },
              autofocus: true,
              child: const Text("支出"),
            ),
          ),
          SizedBox(width: 10.sp),
          Expanded(
            child: ElevatedButton(
              onPressed: !isExpendClick
                  ? null
                  : () {
                      setState(() {
                        isExpendClick = !isExpendClick;
                      });
                    },
              child: const Text("收入"),
            ),
          ),
        ],
      ),
    );
  }

  buildMonthCountRow() {
    var titleText = isExpendClick
        ? "共支出 ${monthBillItems.where((e) => e.itemType == 1).length} 笔，合计"
        : "共收入 ${monthBillItems.where((e) => e.itemType == 0).length} 笔，合计";

    var textCount = monthCounts.isEmpty
        ? ""
        : (isExpendClick
            ? "￥${monthCounts.firstWhere((e) => e.period == selectedMonth).expendTotalValue}"
            : "￥${monthCounts.firstWhere((e) => e.period == selectedMonth).incomeTotalValue}");

    return Container(
      color: Colors.grey,
      height: 50.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            dense: true,
            title: Text(titleText, style: TextStyle(fontSize: 15.sp)),
            trailing: Text(textCount, style: TextStyle(fontSize: 24.sp)),
          )
        ],
      ),
    );
  }

  buildBarChart() {
    return Container(
      color: Colors.green,
      height: 0.3.sh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              "${isExpendClick ? '支出' : '收入'}对比￥",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              // x轴的一些配置
              primaryXAxis: CategoryAxis(
                // labelRotation: -60,
                // 隐藏x轴网格线
                majorGridLines: MajorGridLines(width: 0.sp),
                // 格式化x轴的刻度标签
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  // 默认的标签样式继续用，简单修改字体大小即可
                  TextStyle newStyle = details.textStyle.copyWith(
                    fontSize: 9.sp,
                  );

                  /// 格式化x轴标签日期文字(中文年月太长了)
                  // 获取当前区域
                  Locale locale = Localizations.localeOf(context);
                  // 获取月份标签，转为日期格式，再转为符合区域格式的日期年月字符串
                  var newLabel = DateFormat.yM(locale.toString()).format(
                    DateTime.tryParse("${details.text}-01") ?? DateTime.now(),
                  );

                  return ChartAxisLabel(newLabel, newStyle);
                },
              ),
              // y轴的一些配置
              primaryYAxis: const NumericAxis(
                // 隐藏y轴网格线
                majorGridLines: MajorGridLines(width: 0),
                // 不显示y轴标签
                isVisible: false,
              ),
              // 点击柱子的提示行为
              tooltipBehavior: _tooltip,
              // 柱子图数据
              series: <CartesianSeries<BillPeriodCount, String>>[
                ColumnSeries<BillPeriodCount, String>(
                  dataSource: monthCounts,
                  xValueMapper: (BillPeriodCount data, _) => data.period,
                  yValueMapper: (BillPeriodCount data, _) => isExpendClick
                      ? data.expendTotalValue
                      : data.incomeTotalValue,
                  width: 0.6, // 柱的宽度
                  spacing: 0.4, // 柱之间的间隔
                  name: '支出',
                  color: const Color.fromRGBO(8, 142, 255, 1),
                  // 根据索引设置不同的颜色，高亮第三个柱子（索引为2，因为索引从0开始）
                  pointColorMapper: (BillPeriodCount value, int index) {
                    if (value.period == selectedMonth) {
                      return Colors.orange; // 高亮颜色
                    } else {
                      return Colors.grey[500]; // 其他柱子的颜色
                    }
                  },
                  // 数据标签的配置(默认不显示)
                  dataLabelSettings: DataLabelSettings(
                    // 显示数据标签
                    isVisible: true,
                    // 数据标签的位置
                    // labelAlignment: ChartDataLabelAlignment.bottom,
                    // 格式化标签组件（可以换成图标等其他部件）
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      var d = (data as BillPeriodCount);
                      return Text(
                        "${isExpendClick ? d.expendTotalValue : d.incomeTotalValue}",
                        style: TextStyle(fontSize: 10.sp),
                      );
                    },
                  ),
                  // 格式化标签文字字符串
                  // dataLabelMapper: (datum, index) {
                  //   return "￥${datum.expendTotalValue}";
                  // },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildRankingList() {
    // 按选择类型获取支出或收入的数据列表
    var orderedItems = monthBillItems
        .where((e) => isExpendClick ? e.itemType != 0 : e.itemType == 0)
        .toList();
    // 按照值降序排序
    orderedItems.sort((a, b) => b.value.compareTo(a.value));

    if (orderedItems.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50.sp),
          const Icon(Icons.file_present),
          const Text("暂无数据"),
        ],
      );
    }

    return Container(
      color: Colors.blueAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              "${isExpendClick ? '支出' : '收入'}排行￥",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true, // 允许ListView根据内容大小来包裹其内容
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(0),
            itemCount: orderedItems.length,
            itemBuilder: (BuildContext context, int index) {
              var i = orderedItems[index];

              return Card(
                child: Padding(
                  // 设置内边距
                  padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 5.sp),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1} ${i.item}",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${i.date}___created:${i.gmtModified ?? ''}",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontSize: 10.sp),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "￥${i.value}",
                          style: TextStyle(fontSize: 15.sp),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              /// ListTile dense为true默认高度48(否则为56),导致这个card高度56(64)，有些高了
              // return Card(
              //   // margin: EdgeInsets.all(5.sp), // 外边距
              //   elevation: 5,
              //   color: Colors.blueGrey,
              //   child: ListTile(
              //     dense: true,
              //     title: Text(
              //       "${index + 1} ${i.item}",
              //       softWrap: true,
              //       overflow: TextOverflow.ellipsis,
              //       maxLines: 1,
              //       style: TextStyle(fontSize: 15.sp),
              //     ),
              //     trailing: Text(
              //       "￥${i.value}",
              //       style: TextStyle(fontSize: 15.sp),
              //     ),
              //   ),
              // );
            },
          ),
        ],
      ),
    );
  }

  ///
  ///
  ///年度账单的相关组件
  ///
  buildYearCountTab() {
    return Column(
      children: [
        buildYearChangeRow(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildYearCountRow(),
                buildYearBarChart(),
                buildYearRankingTop10(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  buildYearChangeRow() {
    return Container(
      height: 36.sp,
      color: Colors.amber, // 显示占位用
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 100.sp,
              // 按钮带标签默认icon在前面，所以使用方向组件改变方向
              // 又因为ui和intl都有TextDirection类，所以显示什么ui的导入
              child: Directionality(
                textDirection: ui.TextDirection.rtl,
                child: TextButton.icon(
                  onPressed: () {
                    // openDatePicker(context);

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Select Year"),
                          content: SizedBox(
                            // Need to use container to add size constraint.
                            width: 300,
                            height: 300,
                            child: YearPicker(
                              firstDate: billPeriod.minDate,
                              lastDate: billPeriod.maxDate,
                              // save the selected date to _selectedDate DateTime variable.
                              // It's used to set the previous selected date when
                              // re-showing the dialog.
                              selectedDate:
                                  DateTime.tryParse("$selectedYear-01-01"),
                              onChanged: (DateTime dateTime) {
                                // close the dialog when year is selected.
                                Navigator.pop(context);

                                setState(() {
                                  print(dateTime);
                                  selectedYear = dateTime.year.toString();
                                  print(
                                      "xxxxxxxxxx$dateTime-------$selectedYear");
                                  _handleSelectedYearChange();
                                });
                                // Do something with the dateTime selected.
                                // Remember that you need to use dateTime.year to get the year
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.arrow_drop_down),
                  label: Text(
                    selectedYear,
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
            child: ElevatedButton(
              onPressed: isYearExpendClick
                  ? null
                  : () {
                      setState(() {
                        isYearExpendClick = !isYearExpendClick;
                      });
                    },
              autofocus: true,
              child: const Text("支出"),
            ),
          ),
          SizedBox(width: 10.sp),
          Expanded(
            child: ElevatedButton(
              onPressed: !isYearExpendClick
                  ? null
                  : () {
                      setState(() {
                        isYearExpendClick = !isYearExpendClick;
                      });
                    },
              child: const Text("收入"),
            ),
          ),
        ],
      ),
    );
  }

  buildYearCountRow() {
    var titleText = isYearExpendClick
        ? "共支出 ${yearBillItems.where((e) => e.itemType == 1).length} 笔，合计"
        : "共收入 ${yearBillItems.where((e) => e.itemType == 0).length} 笔，合计";

    var textCount = yearCounts.isEmpty
        ? ""
        : (isYearExpendClick
            ? "￥${yearCounts.firstWhere((e) => e.period == selectedYear).expendTotalValue}"
            : "￥${yearCounts.firstWhere((e) => e.period == selectedYear).incomeTotalValue}");

    return Container(
      color: Colors.grey,
      height: 50.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            dense: true,
            title: Text(titleText, style: TextStyle(fontSize: 15.sp)),
            trailing: Text(textCount, style: TextStyle(fontSize: 24.sp)),
          )
        ],
      ),
    );
  }

  buildYearBarChart() {
    return Container(
      color: Colors.green,
      height: 0.3.sh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              "${isYearExpendClick ? '支出' : '收入'}对比￥",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              // x轴的一些配置
              primaryXAxis: CategoryAxis(
                // labelRotation: -60,
                // 隐藏x轴网格线
                majorGridLines: MajorGridLines(width: 0.sp),
                // 格式化x轴的刻度标签
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  // 默认的标签样式继续用，简单修改字体大小即可
                  TextStyle newStyle = details.textStyle.copyWith(
                    fontSize: 12.sp,
                  );

                  /// 格式化x轴标签日期文字(中文年月太长了)
                  // 获取当前区域
                  Locale locale = Localizations.localeOf(context);
                  // 获取月份标签，转为日期格式，再转为符合区域格式的日期年月字符串
                  var newLabel = DateFormat.y(locale.toString()).format(
                    DateTime.tryParse("${details.text}-01-01") ??
                        DateTime.now(),
                  );

                  return ChartAxisLabel(newLabel, newStyle);
                },
              ),
              // y轴的一些配置
              primaryYAxis: const NumericAxis(
                // 隐藏y轴网格线
                majorGridLines: MajorGridLines(width: 0),
                // 不显示y轴标签
                isVisible: false,
              ),
              // 点击柱子的提示行为
              tooltipBehavior: _tooltip,
              // 柱子图数据
              series: <CartesianSeries<BillPeriodCount, String>>[
                ColumnSeries<BillPeriodCount, String>(
                  dataSource: yearCounts,
                  xValueMapper: (BillPeriodCount data, _) => data.period,
                  yValueMapper: (BillPeriodCount data, _) => isYearExpendClick
                      ? data.expendTotalValue
                      : data.incomeTotalValue,
                  width: 0.6, // 柱的宽度
                  spacing: 0.4, // 柱之间的间隔
                  name: '支出',
                  color: const Color.fromRGBO(8, 142, 255, 1),
                  // 根据索引设置不同的颜色，高亮第三个柱子（索引为2，因为索引从0开始）
                  pointColorMapper: (BillPeriodCount value, int index) {
                    if (value.period == selectedYear) {
                      return Colors.orange; // 高亮颜色
                    } else {
                      return Colors.grey[500]; // 其他柱子的颜色
                    }
                  },
                  // 数据标签的配置(默认不显示)
                  dataLabelSettings: DataLabelSettings(
                    // 显示数据标签
                    isVisible: true,
                    // 数据标签的位置
                    // labelAlignment: ChartDataLabelAlignment.bottom,
                    // 格式化标签组件（可以换成图标等其他部件）
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      var d = (data as BillPeriodCount);
                      return Text(
                        "${isYearExpendClick ? d.expendTotalValue : d.incomeTotalValue}",
                        style: TextStyle(fontSize: 10.sp),
                      );
                    },
                  ),
                  // 格式化标签文字字符串
                  // dataLabelMapper: (datum, index) {
                  //   return "￥${datum.expendTotalValue}";
                  // },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 这里应该是按照category大类分类统计，然后点击查看该分类的账单列表。暂时先这样
  buildYearRankingTop10() {
    // 按选择类型获取支出或收入的数据列表
    var orderedItems = yearBillItems
        .where((e) => isYearExpendClick ? e.itemType != 0 : e.itemType == 0)
        .toList();
    // 按照值降序排序
    orderedItems.sort((a, b) => b.value.compareTo(a.value));

    orderedItems = orderedItems.length > 10
        ? orderedItems.getRange(0, 10).toList()
        : orderedItems;

    if (orderedItems.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50.sp),
          const Icon(Icons.file_present),
          const Text("暂无数据"),
        ],
      );
    }

    return Container(
      color: Colors.blueAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              "${isExpendClick ? '支出' : '收入'}排行前十￥",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true, // 允许ListView根据内容大小来包裹其内容
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(0),
            itemCount: orderedItems.length,
            itemBuilder: (BuildContext context, int index) {
              var i = orderedItems[index];

              return Card(
                child: Padding(
                  // 设置内边距
                  padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 5.sp),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1} ${i.item}",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${i.date}___created:${i.gmtModified ?? ''}",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontSize: 10.sp),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "￥${i.value}",
                          style: TextStyle(fontSize: 15.sp),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              /// ListTile dense为true默认高度48(否则为56),导致这个card高度56(64)，有些高了
              // return Card(
              //   // margin: EdgeInsets.all(5.sp), // 外边距
              //   elevation: 5,
              //   color: Colors.blueGrey,
              //   child: ListTile(
              //     dense: true,
              //     title: Text(
              //       "${index + 1} ${i.item}",
              //       softWrap: true,
              //       overflow: TextOverflow.ellipsis,
              //       maxLines: 1,
              //       style: TextStyle(fontSize: 15.sp),
              //     ),
              //     trailing: Text(
              //       "￥${i.value}",
              //       style: TextStyle(fontSize: 15.sp),
              //     ),
              //   ),
              // );
            },
          ),
        ],
      ),
    );
  }
}
