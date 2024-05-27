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
import '../bill_item_modify/index.dart';
import 'mock_data/index.dart';

/// 2024-05-25
/// 首页的账单列表显示暂时不按照微信那样可以滚动加载更多和滑动了。
/// 简单一点，就只支持按月查看，而不是将查询的结果分组了。
/// 上方点击月份可以弹窗选择其他月份，旁边两个按钮， 切换到上一个月下一个月
/// 【即当前listview中只显示当月的数据】
///     如果想看2023-12-14 ~ 2024-01-13的跨月数据在一个listview，不行。
///   ？？？因为目前的简单设计，没法在滚动处知道listview中已经存在的月份数据，
/// 所以无法实时更新当前的选中月份，导致每次拖动到顶或者底查询新的数据时，条件有误。
///
/// 比如先查2023-04的，往下拉一直更新到当前月为2023-08,此时已有 2023-04到-08的数据，当前月为2023-08
///   现在拉到底，查询上一个月的，此时被选中的月份是2023-08,再一次查询的是2023-07的数据，
///   但listview原本底部显示的是2023-04的数据。所以此时又查询了一次2023-07的数据，
///   用于显示的billItems列表数据就有重复了。
///     --- 这个问题可以再有一个变量存已经查询过的月份列表(或者两个date变量存已查询的最大最小日期)，
///         如果此时的当前月在这个范围内，就再更新被选中的月份为已经查询的最新+1或者最旧-1 月份
///         又因为手动切换月份本来就要清0重新查询，所有滚动时更新一个最大日期和最小日期即可
/// 此外，在已有的200023-04 ~ 08 之前滚动，无法定位当前的月份是哪一个月
///     --- ？？？暂时无解
///
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
  // 在页面滚动时已经查询过的月份
  // 如果滚动到底部或者顶部要触发新查询，如果此时的当前月在这个范围内，就再更新被选中的月份为已经查询的最新或者最旧月份
  List<String> queryedMonths = [];

  // 虽然是已查询的最大最小日期，但逻辑中只关注年月，所以日最好存1号，避免产生影响
  DateTime minQueryedDate = DateTime.now();
  DateTime maxQueryedDate = DateTime.now();

  // 滚动方向，往上拉是up，往下拉时down，默认为none
  String scollDirection = "none";

  @override
  void initState() {
    super.initState();

    // 2024-05-25 初始化查询时就更新已查询的最大日期和最小日期为当天所在月份的1号(后续用到的地方也只关心年月)
    maxQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
    minQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();

    print("初始化时的最大最小查询日期-------------$maxQueryedDate $minQueryedDate");

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
      // 如果有关键字了，是不是不应该限制起止了？？？
      itemKeyword: query,
      startDate: query != "" ? "" : "$selectedMonth-01",
      endDate: query != "" ? "" : "$selectedMonth-31",
      page: 1,
      pageSize: 0,
    );

    var newData = temp.data as List<BillItem>;

    setState(() {
      // 2024-05-24 暂时每个月切换后不保留之前查询的数据，只显示当月的
      // billItems.clear();
      // 2024-05-24 这里不能直接添加，还需要排序，不然上拉后下拉日期新的列表在日期旧的列表后面
      if (scollDirection == "down") {
        billItems.insertAll(0, newData);
      } else {
        billItems.addAll(newData);
      }
      billItemGroupByDayMap = groupBy(billItems, (item) => item.date);
      // 2024-05-25 已经查询过的月份数据放入列表，避免重复查询
      isLoading = false;
    });
  }

  // 查询月度统计
  // ？？？年度统计再看列表详情的话比较奇怪，和微信类似，多个年度统计tab，换个页面查询统计
  Future<List<BillPeriodCount>?> _loadBillCountData() async {
    try {
      return await _dbHelper.queryBillCountList(
        // 如果有关键字了，是不是不应该限制起止了？？？
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
  // 还有问题，已经加载了很多个月份的数据，在切换不同月份的列表时，当前选中的月份数据不会变化。？？？
  // 往上拉往下拉之后，重复几次，数据就重复了？？？
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

      // 如果要查询的下一个月在已查询的最大月份之前，则更新下一个月为已查询最大月
      // 比如一直往上拉，已有202304-202308的数据，因为往上拉，此时被选中的月份是2023-04。
      // 现在往下拉到顶，应该查询2022309的数据，因为选中的是2023-04,不做任何处理的话查询的实际是202305的值，这不对。
      // 所以直接使用已查询的最大日期去+1查最新数据，并更新选中月份
      DateTime nextMonthDate = DateTime(
        maxQueryedDate.year,
        maxQueryedDate.month + 1,
        maxQueryedDate.day,
      );

      String nextMonth = DateFormat(constMonthFormat).format(nextMonthDate);
      // 如果当前月份的下一月的1号已经账单中最大日期了，到顶了也不再加载
      if (nextMonthDate.isAfter(billPeriod.maxDate)) {
        print("滚动到顶部，但已经到了账单【最新】的月份了，没有更【新】的数据可查了");
        setState(() {
          selectedMonth = DateFormat(constMonthFormat).format(maxQueryedDate);
        });
        return;
      }

      //
      if (queryedMonths.contains(nextMonth)) {}

      print("到顶部了，当前选中的日期$selectedMonth 下个月$nextMonth  ");

      setState(() {
        // 查询了更新的数据，要更新当前选中值和最大查询日期
        selectedMonth = nextMonth;
        maxQueryedDate = nextMonthDate;
        scollDirection = "down";
        _loadBillItemData();
      });
    } else if (atEdge &&
        !outOfRange &&
        scrollController.offset >= maxScrollExtent) {
      // 滚动到底部，查询下一个月的
      // 参看往上拉的逻辑说明
      DateTime lastMonthDate = DateTime(
        minQueryedDate.year,
        minQueryedDate.month - 1,
        minQueryedDate.day,
      );
      String lastMonth = DateFormat(constMonthFormat).format(lastMonthDate);

      // 如果当前月份的1号已经账单中最大日期了，到顶了也不再加载
      // ???这里的比较其实有问题，2023-02-01 > 2023-02-12 时成立的
      if (lastMonthDate.isBefore(billPeriod.minDate)) {
        print("滚动到底部，但已经到了账单【最旧】的月份了，没有更【旧】的数据可查了");
        setState(() {
          selectedMonth = DateFormat(constMonthFormat).format(minQueryedDate);
        });
        return;
      }

      print("到底了，当前选中的日期$selectedMonth   上个月$lastMonth ");
      setState(() {
        selectedMonth = lastMonth;
        minQueryedDate = lastMonthDate;
        scollDirection = "up";
        _loadBillItemData();
      });
    }
  }

  void _handleSearch() {
    setState(() {
      billItems.clear();
      queryedMonths.clear();
      scollDirection == "none";
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
                scollDirection == "none";
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
            /// test 已查询的月度范围
            Container(
              height: 50.sp,
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.sp, 0, 4, 0),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Text("已经显示的数据范围"),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "${DateFormat(constMonthFormat).format(minQueryedDate)} ~ ${DateFormat(constMonthFormat).format(maxQueryedDate)}",
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                          maxQueryedDate =
                              DateTime.tryParse("$selectedMonth-01") ??
                                  DateTime.now();
                          minQueryedDate =
                              DateTime.tryParse("$selectedMonth-01") ??
                                  DateTime.now();
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
    // var totalExpend = itemsForDate.fold(0.0, (sum, item) {
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
    double totalExpend = 0.0;
    double totalIncome = 0.0;
    for (var item in itemsForDate) {
      if (item.itemType != 0) {
        totalExpend += item.value;
      } else {
        totalIncome += item.value;
      }
    }

    print("total expend--$totalExpend income $totalIncome");

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              date,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
            trailing: Text(
              '支出 ¥$totalExpend 收入 ¥$totalIncome',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 13.sp,
              ),
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
                return buildItemListTile(item);
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
                  "支出 ¥${list[0].expendTotalValue}  收入 ¥${list[0].incomeTotalValue}"),
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

// 账单列表子条目的list
  GestureDetector buildItemListTile(BillItem item) {
    return GestureDetector(
      // 暂定长按删除弹窗、双击跳到修改
      // ListTile 没有双击事件，所以包裹一个手势
      onDoubleTap: () {
        print('ListTile $item was double tapped!');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillEditPage(billItem: item),
          ),
        ).then((value) {
          // 不管是否新增成功，这里都重新加载；
          // 因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
          if (value != null) {
            setState(() {
              print("长按修改billitem的返回值---$value");
            });
          }
        });
      },

      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("删除提示"),
              content: Text(
                "确定删除选中的条目:\n ${item.itemType != 0 ? '支出' : '收入'}　${item.item} ${item.value}",
                style: TextStyle(fontSize: 15.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _dbHelper.deleteBillItemById(item.billItemId);
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("确定"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消"),
                ),
              ],
            );
          },
        ).then((value) {
          // 成功删除就重新查询
          if (value != null && value) {
            setState(() {
              _handleSearch();
            });
          }
        });
      },
      child: ListTile(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: item.item,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15.sp,
                ),
              ),
              if (item.category != null)
                TextSpan(
                  text: "\n${item.category}",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12.sp,
                  ),
                ),
            ],
          ),
        ),
        trailing: Text(
          '${item.itemType == 0 ? '+' : '-'}${item.value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: item.itemType != 0 ? Colors.black : Colors.green,
          ),
        ),
        // 2024-05-27 还是不要单个事件做多个操作了
        // 暂定长按删除弹窗、双击跳到修改
        // onLongPress: () {
        //   print("长按了条目---------$item");
        //   showDialog(
        //     context: context,
        //     builder: (context) {
        //       return AlertDialog(
        //         title: const Text("异动说明"),
        //         content: Column(
        //           mainAxisSize: MainAxisSize.min,
        //           crossAxisAlignment: CrossAxisAlignment.center,
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             Text(
        //               "请选择账单条目的处理方式:\n",
        //               style: TextStyle(fontSize: 15.sp),
        //             ),
        //             Row(
        //               mainAxisAlignment:
        //                   MainAxisAlignment.spaceBetween,
        //               children: [
        //                 TextButton(
        //                   onPressed: () {
        //                     Navigator.of(context).pop("delete");
        //                   },
        //                   child: const Text("删除"),
        //                 ),
        //                 TextButton(
        //                   onPressed: () {
        //                     Navigator.of(context).pop("modify");
        //                   },
        //                   child: const Text("修改"),
        //                 ),
        //                 ElevatedButton(
        //                   onPressed: () {
        //                     Navigator.of(context).pop("cancel");
        //                   },
        //                   child: const Text("取消"),
        //                 ),
        //               ],
        //             ),
        //           ],
        //         ),
        //         // actions: [
        //         //   TextButton(
        //         //     onPressed: () {
        //         //       Navigator.pop(context);
        //         //     },
        //         //     child: const Text("取消"),
        //         //   ),
        //         // ],
        //       );
        //     },
        //   ).then((value) {
        //     if (value == "modify") {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => BillEditPage(billItem: item),
        //         ),
        //       ).then((value) {
        //         // 不管是否新增成功，这里都重新加载；
        //         // 因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
        //         if (value != null) {
        //           setState(() {
        //             print("长按修改billitem的返回值---$value");
        //           });
        //         }
        //       });
        //     } else if (value == "delete") {
        //       print("点击了删除--------------");
        //     } else {
        //       print("点击了----其他--------------");
        //     }
        //   });
        // },
      ),
    );
  }
}
