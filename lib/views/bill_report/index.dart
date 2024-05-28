// ignore_for_file: avoid_print
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../common/components/tool_widget.dart';
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
  // 月度统计列表数据
  late List<BillPeriodCount> monthCounts = [];
  // 月度项次列表数据
  late List<BillItem> monthBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isMonthExpendClick = true;
  // 是否在加载月度统计数据
  bool isMonthLoading = false;

  ///
  /// 年度统计相关的变量(使用两套主要为了在月度做了一些操作之后切到年度，再切到月度时保留之前的操作后结果)
  ///
  // 被选中的年份(yyyy格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedYear = DateFormat.y().format(DateTime.now());
  late List<BillPeriodCount> yearCounts = [];
  late List<BillItem> yearBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isYearExpendClick = true;
  // 是否在加载年度统计数据
  bool isYearLoading = false;

  @override
  void initState() {
    _tooltip = TooltipBehavior(enable: true);

    // 初始化TabController
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    // 监听Tab切换
    _tabController.addListener(_handleTabSelection);

    getBillPeriod();

    // 初始化时就加载两个月的数据，虽然默认是展示月度，但切换都年度时不用重新初始化。
    // 后续再切换年度月度，都有可见的数据，在没改变选中的年月时不用重新查询。
    handleSelectedMonthChange();
    handleSelectedYearChange();

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 获取数据库中账单记录的日期起迄范围
  getBillPeriod() async {
    var tempPeriod = await _dbHelper.queryDateRangeList();
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  /// 获取指定月的统计数据(参考微信是指定月前后一起半年数据，做柱状图)
  _getMonthCount() async {
    // 选中2023-04
    // date 2023-04-01 00:00:01
    DateTime date =
        DateTime.tryParse("$selectedMonth-01 00:00:01") ?? DateTime.now();

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

    var temp = await _dbHelper.queryBillCountList(
      countType: "month",
      startDate: "$start-01",
      endDate: "$end-31",
    );

    setState(() {
      monthCounts = temp;
    });
  }

  /// 获取指定年的统计数据(同上，只查询3年的数据)
  _getYearCount() async {
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

    setState(() {
      yearCounts = temp;
    });
  }

  // 获取指定月份的详细数据
  _getMonthBillItemList() async {
    var temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedMonth-01",
      endDate: "$selectedMonth-31",
      page: 1,
      pageSize: 0,
    );
    var newData = temp.data as List<BillItem>;

    setState(() {
      monthBillItems = newData;
    });
  }

  // 获取指定年份的详细数据
  _getYearBillItemList() async {
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

  /// 切换了选中月份的查询函数
  void handleSelectedMonthChange() async {
    if (isMonthLoading) {
      return;
    }

    setState(() {
      isMonthLoading = true;
      monthCounts.clear();
      monthBillItems.clear();
    });

    await _getMonthCount();
    await _getMonthBillItemList();

    setState(() {
      isMonthLoading = false;
    });
  }

  /// 切换了选中年份的查询函数
  void handleSelectedYearChange() async {
    if (isYearLoading) {
      return;
    }

    setState(() {
      isYearLoading = true;
      yearCounts.clear();
      yearBillItems.clear();
    });
    // // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    // 如果在init之类的地方使用，这个context会报错的
    // FocusScope.of(context).unfocus();
    await _getYearCount();
    await _getYearBillItemList();

    setState(() {
      isYearLoading = false;
    });
  }

  ///
  /// 处理Tab切换(目前无实际作用)
  ///
  /// 不做任何处理时，默认点击tab标签切换tab，这里会重复触发？？？
  /// 这是预期行为，参看：https://github.com/flutter/flutter/issues/13848
  ///
  _handleTabSelection() {
    // tab is animating. from active (getting the index) to inactive(getting the index)
    if (_tabController.indexIsChanging) {
      print("点击切换了tab--${_tabController.index}");
      // if (_tabController.index == 1) {
      //   // 如果是切换了月度统计和年度统计，重新查询
      //   print("isYearLoading--------$isYearLoading");
      //   _handleSelectedMonthChange();
      // } else {
      //   print("isMonthLoading--------$isMonthLoading");
      //   _handleSelectedYearChange();
      // }
    } else {
      // tab is finished animating you get the current index
      // here you can get your index or run some method once.
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
          backgroundColor: Colors.lightGreen,
          // title: const Text('TabBar Sample'),
          // AppBar的preferredSize默认是固定的（对于标准AppBar来说是kToolbarHeight,56）
          // 如果不显示title，可以适当减小
          toolbarHeight: kToolbarHeight - 36,
          title: null,
          bottom: TabBar(
            // overlayColor: WidgetStateProperty.all(Colors.lightGreen),
            controller: _tabController,
            // onTap: (int i) {
            //   print("当前index${_tabController.index}-------点击的index$i");
            //   // 这里没法获取到前一个index是哪一个，
            //   if (i == 1) {
            //     _handleSelectedYearChange();
            //   } else {
            //     _handleSelectedMonthChange();
            //   }
            // },
            // 让tab按钮两边留空，更居中一点
            padding: EdgeInsets.symmetric(horizontal: 0.25.sw, vertical: 5.sp),
            tabs: const <Widget>[
              Tab(text: "月账单"),
              Tab(text: "年账单"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            // 月度账单页
            buildTabBarView('month'),
            // 年度账单页
            buildTabBarView('year'),
          ],
        ),
      ),
    );
  }

  ///
  /// 年度月度公共的方法
  ///
  /// 构建年度月度账单Tab页面
  buildTabBarView(String billType) {
    bool loadingFlag = ((billType == "month") ? isMonthLoading : isYearLoading);
    return Column(
      children: [
        buildChangeRow(billType),
        loadingFlag
            ? buildLoader(loadingFlag)
            : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildCountRow(billType),
                      buildBarChart(billType),
                      buildRankingTop(billType),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  /// 年度月度日期选择行
  /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
  buildChangeRow(String billType) {
    bool isMonth = billType == "month";
    return Container(
      height: 36.sp,
      color: Colors.lightGreen, // 显示占位用
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
                    isMonth
                        ? showMonthPicker(
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
                                handleSelectedMonthChange();
                              });
                            }
                          })
                        : showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("选择年份"),
                                content: SizedBox(
                                  // 需要显示弹窗正文的大小(直接设宽度没什么用，但高度有效)
                                  height: 300.sp,
                                  child: YearPicker(
                                    firstDate: billPeriod.minDate,
                                    lastDate: billPeriod.maxDate,
                                    selectedDate: DateTime.tryParse(
                                        "$selectedYear-01-01"),
                                    onChanged: (DateTime dateTime) {
                                      // 选中年份之后关闭弹窗，并开始查询年度数据
                                      Navigator.pop(context);
                                      setState(() {
                                        selectedYear = dateTime.year.toString();
                                        handleSelectedYearChange();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  label: Text(
                    isMonth ? selectedMonth : selectedYear,
                    style: TextStyle(fontSize: 15.sp, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80.sp,
            height: 24.sp,
            child: ElevatedButton(
              onPressed: isMonth
                  ? (isMonthExpendClick
                      ? null
                      : () {
                          setState(() {
                            isMonthExpendClick = !isMonthExpendClick;
                          });
                        })
                  : (isYearExpendClick
                      ? null
                      : () {
                          setState(() {
                            isYearExpendClick = !isYearExpendClick;
                          });
                        }),
              autofocus: true,
              child: const Text("支出"),
            ),
          ),
          SizedBox(width: 10.sp),
          SizedBox(
            width: 80.sp,
            height: 24.sp,
            child: ElevatedButton(
              onPressed: isMonth
                  ? (!isMonthExpendClick
                      ? null
                      : () {
                          setState(() {
                            isMonthExpendClick = !isMonthExpendClick;
                          });
                        })
                  : (!isYearExpendClick
                      ? null
                      : () {
                          setState(() {
                            isYearExpendClick = !isYearExpendClick;
                          });
                        }),
              child: const Text("收入"),
            ),
          ),
          SizedBox(width: 10.sp),
        ],
      ),
    );
  }

  /// 年度或月度统计行
  buildCountRow(String billType) {
    bool isMonth = billType == "month";

    // 获取支出/收入项次数量字符串
    getCounts(List<BillItem> items, bool isExpend) {
      var counts = items.where((e) => e.itemType == (isExpend ? 1 : 0)).length;
      return "共${isExpend ? '支出' : '收入'} $counts 笔，合计";
    }

    // 获取支出/收入金额总量字符串
    getTotal(List<BillPeriodCount> counts, String date, bool isExpend) {
      if (counts.isEmpty) return "";
      var temp = counts.firstWhere((e) => e.period == date);
      return "￥${isExpend ? temp.expendTotalValue : temp.incomeTotalValue}";
    }

    var titleText = isMonth
        ? getCounts(monthBillItems, isMonthExpendClick)
        : getCounts(yearBillItems, isYearExpendClick);

    var textCount = isMonth
        ? getTotal(monthCounts, selectedMonth, isMonthExpendClick)
        : getTotal(yearCounts, selectedYear, isYearExpendClick);

    return Container(
      color: Colors.lightGreen,
      height: 50.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            dense: true,
            title: Text(
              titleText,
              style: TextStyle(fontSize: 15.sp, color: Colors.white),
            ),
            trailing: Text(
              textCount,
              style: TextStyle(fontSize: 24.sp, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  /// 绘制收入支出柱状图(指定年度或月度字符串:yaer|month)
  buildBarChart(String billType) {
    // 不是月度，就是年度
    bool isMonth = billType == "month";

    return SizedBox(
      height: 200.sp, // 图表还是绝对高度吧，如果使用相对高度不同设备显示差异挺大
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              isMonth
                  ? "${isMonthExpendClick ? '支出' : '收入'}对比￥"
                  : "${isYearExpendClick ? '支出' : '收入'}对比￥",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
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
                    fontSize: isMonth ? 9.sp : 12.sp,
                  );

                  /// 格式化x轴标签日期文字(中文年月太长了)
                  // 获取当前区域
                  Locale locale = Localizations.localeOf(context);
                  // 获取月份标签，转为日期格式，再转为符合区域格式的日期年月字符串
                  var newLabel = DateFormat.yM(locale.toString()).format(
                    DateTime.tryParse(isMonth
                            ? "${details.text}-01"
                            : "${details.text}-01-01") ??
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
                  dataSource: isMonth ? monthCounts : yearCounts,
                  xValueMapper: (BillPeriodCount data, _) => data.period,
                  yValueMapper: (BillPeriodCount data, _) =>
                      (isMonth ? isMonthExpendClick : isYearExpendClick)
                          ? data.expendTotalValue
                          : data.incomeTotalValue,
                  width: 0.6, // 柱的宽度
                  spacing: 0.4, // 柱之间的间隔
                  name: '支出',
                  color: const Color.fromRGBO(8, 142, 255, 1),
                  // 根据索引设置不同的颜色，高亮第三个柱子（索引为2，因为索引从0开始）
                  pointColorMapper: (BillPeriodCount value, int index) {
                    if (value.period ==
                        (isMonth ? selectedMonth : selectedYear)) {
                      return Colors.green; // 高亮颜色
                    } else {
                      return Colors.black12; // 其他柱子的颜色
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
                        isMonth
                            ? "${isMonthExpendClick ? d.expendTotalValue : d.incomeTotalValue}"
                            : "${isYearExpendClick ? d.expendTotalValue : d.incomeTotalValue}",
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

  /// 按照数值大小倒序查看账单项次
  /// 这里应该是按照category大类分类统计，然后点击查看该分类的账单列表。暂时先这样
  buildRankingTop(String billType) {
    bool isMonth = billType == "month";

    // 按选择类型获取支出或收入的数据列表
    var orderedItems = isMonth
        ? (monthBillItems
            .where(
                (e) => isMonthExpendClick ? e.itemType != 0 : e.itemType == 0)
            .toList())
        : (yearBillItems
            .where((e) => isYearExpendClick ? e.itemType != 0 : e.itemType == 0)
            .toList());
    // 按照值降序排序
    orderedItems.sort((a, b) => b.value.compareTo(a.value));

    // 年度统计的，只要top10
    if (!isMonth) {
      orderedItems =
          orderedItems.length > 10 ? orderedItems.sublist(0, 10) : orderedItems;
    }

    // 如果没有账单列表数据，显示空提示
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

    /// 有账单条目列表则创建并显示
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.sp, top: 5.sp, bottom: 10.sp),
          child: Text(
            billType == "month"
                ? "${isMonthExpendClick ? '支出' : '收入'}排行"
                : "${isYearExpendClick ? '支出' : '收入'}排行前十",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
        ),
        ListView.builder(
          shrinkWrap: true, // 允许ListView根据内容大小来包裹其内容
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(0),
          itemCount: orderedItems.length,
          itemBuilder: (BuildContext context, int index) {
            BillItem i = orderedItems[index];

            return Padding(
              // 设置内边距
              padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 15.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 5.sp),
                  SizedBox(
                    width: 25.sp,
                    child: Text("${index + 1}"),
                  ),
                  SizedBox(width: 5.sp),
                  // 后续模拟支出收入分类的图标
                  Icon(Icons.shopping_cart, color: Colors.orange[300]!),
                  SizedBox(width: 5.sp),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.item,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        Text(
                          "消费日期:${i.date}__${i.gmtModified ?? ''}",
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
    );
  }
}
