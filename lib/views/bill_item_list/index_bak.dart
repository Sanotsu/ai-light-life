// // // ignore_for_file: avoid_print

// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';

// // import 'package:collection/collection.dart';

// // import '../../common/components/tool_widget.dart';
// // import '../../common/utils/db_helper.dart';
// // import '../../models/brief_accounting_state.dart';
// // import 'mock_data/index.dart';

// // class BillItemIndex extends StatefulWidget {
// //   const BillItemIndex({super.key});

// //   @override
// //   State<BillItemIndex> createState() => _BillItemIndexState();
// // }

// // class _BillItemIndexState extends State<BillItemIndex> {
// //   final DBHelper _dbHelper = DBHelper();

// //   List<BillItem> billItems = [];
// //   int itemsCount = 0;
// //   int currentPage = 1; // 数据库查询的时候会从0开始offset
// //   int pageSize = 10;
// //   bool isLoading = false;
// //   ScrollController scrollController = ScrollController();
// //   TextEditingController searchController = TextEditingController();
// //   String query = '';

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadBillItemData();

// //     scrollController.addListener(_scrollListener);
// //   }

// //   @override
// //   void dispose() {
// //     scrollController.removeListener(_scrollListener);
// //     scrollController.dispose();
// //     searchController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _loadBillItemData() async {
// //     if (isLoading) return;

// //     setState(() {
// //       isLoading = true;
// //     });

// //     CusDataResult temp = await _dbHelper.queryBillItemList(
// //       itemKeyword: query,
// //       page: currentPage,
// //       pageSize: pageSize,
// //     );

// //     var newData = temp.data as List<BillItem>;

// //     setState(() {
// //       billItems.addAll(newData);
// //       itemsCount = temp.total;
// //       currentPage++;
// //       isLoading = false;
// //     });
// //   }

// //   void _scrollListener() {
// //     if (isLoading) return;

// //     final maxScrollExtent = scrollController.position.maxScrollExtent;
// //     final currentPosition = scrollController.position.pixels;
// //     final delta = 50.0.sp;

// //     if (maxScrollExtent - currentPosition <= delta) {
// //       _loadBillItemData();
// //     }
// //   }

// //   void _handleSearch() {
// //     setState(() {
// //       billItems.clear();
// //       currentPage = 1;
// //       query = searchController.text;
// //     });
// //     // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
// //     FocusScope.of(context).unfocus();

// //     _loadBillItemData();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
// //       resizeToAvoidBottomInset: false,
// //       appBar: AppBar(
// //         title: const Text("账单列表"),
// //         actions: [
// //           TextButton(
// //             onPressed: () async {
// //               setState(() {
// //                 billItems.clear();
// //                 isLoading = true;
// //               });

// //               await loadUserFromAssets();

// //               setState(() {
// //                 isLoading = false;
// //               });
// //               _loadBillItemData();
// //             },
// //             child: const Text("Mock"),
// //           ),
// //         ],
// //       ),

// //       body: Column(
// //         children: [
// //           Padding(
// //             padding: EdgeInsets.all(8.sp),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: searchController,
// //                     decoration: const InputDecoration(
// //                       hintText: "输入条目关键字",
// //                       // 设置透明底色
// //                       filled: true,
// //                       fillColor: Colors.transparent,
// //                     ),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: _handleSearch,
// //                   child: const Text("搜索"),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: SizedBox(
// //               height: 100.sp,
// //               child: ListView.builder(
// //                 itemCount:
// //                     groupBy(billItems, (item) => item.date.substring(0, 7))
// //                         .length,
// //                 itemBuilder: (context, index) {
// //                   if (index ==
// //                       groupBy(billItems, (item) => item.date.substring(0, 7))
// //                           .length) {
// //                     return buildLoader(isLoading);
// //                   } else {
// //                     // 获取当前分组的日期和账单项列表
// //                     MapEntry<String, List<BillItem>> entry =
// //                         groupBy(billItems, (item) => item.date.substring(0, 7))
// //                             .entries
// //                             .elementAt(index);
// //                     String date = entry.key;
// //                     List<BillItem> itemsForDate = entry.value;

// //                     // 计算每天的总花费
// //                     var totalExpand = itemsForDate.fold(0.0, (sum, item) {
// //                       if (item.itemType != 0) {
// //                         // 如果是支出，则累加支出
// //                         return sum + item.value;
// //                       } else {
// //                         // 没有支出则不累加
// //                         return sum;
// //                       }
// //                     });

// //                     var totalIncome = itemsForDate.fold(0.0, (sum, item) {
// //                       // 如果当日有收入，累积收入
// //                       if (item.itemType == 0) {
// //                         return sum + item.value;
// //                       } else {
// //                         // 没有收入则不累加
// //                         return sum;
// //                       }
// //                     });
// //                     return Card(
// //                       child: Column(
// //                         children: [
// //                           ListTile(
// //                             title: Text('Date: $date'),
// //                             trailing: Text(
// //                               '支出 ¥$totalExpand 收入 ¥$totalIncome',
// //                             ),
// //                             // 可以添加副标题或尾随图标等
// //                           ),
// //                           const Divider(), // 可选的分隔线
// //                         ],
// //                       ),
// //                     );
// //                   }
// //                 },
// //                 controller: scrollController,
// //               ),
// //             ),
// //           ),
// //           // Expanded(
// //           //   child: ListView.builder(
// //           //     itemCount: billItems.length + 1,
// //           //     itemBuilder: (context, index) {
// //           //       if (index == billItems.length) {
// //           //         return buildLoader(isLoading);
// //           //       } else {
// //           //         print(billItems);
// //           //         return _buildSimpleFoodTile(billItems[index], index);
// //           //       }
// //           //     },
// //           //     controller: scrollController,
// //           //   ),
// //           // ),
// //           Expanded(
// //             child: ListView.builder(
// //               itemCount: groupBy(billItems, (item) => item.date).length,
// //               itemBuilder: (context, index) {
// //                 if (index == groupBy(billItems, (item) => item.date).length) {
// //                   return buildLoader(isLoading);
// //                 } else {
// //                   // 获取当前分组的日期和账单项列表
// //                   MapEntry<String, List<BillItem>> entry =
// //                       groupBy(billItems, (item) => item.date)
// //                           .entries
// //                           .elementAt(index);
// //                   String date = entry.key;
// //                   List<BillItem> itemsForDate = entry.value;

// //                   // 计算每天的总花费
// //                   var totalExpand = itemsForDate.fold(0.0, (sum, item) {
// //                     if (item.itemType != 0) {
// //                       // 如果是支出，则累加支出
// //                       return sum + item.value;
// //                     } else {
// //                       // 没有支出则不累加
// //                       return sum;
// //                     }
// //                   });

// //                   var totalIncome = itemsForDate.fold(0.0, (sum, item) {
// //                     // 如果当日有收入，累积收入
// //                     if (item.itemType == 0) {
// //                       return sum + item.value;
// //                     } else {
// //                       // 没有收入则不累加
// //                       return sum;
// //                     }
// //                   });

// //                   print("total --$totalExpand");

// //                   return Card(
// //                     child: Column(
// //                       children: [
// //                         ListTile(
// //                           title: Text('Date: $date'),
// //                           trailing: Text(
// //                             '支出 ¥$totalExpand 收入 ¥$totalIncome',
// //                           ),
// //                           // 可以添加副标题或尾随图标等
// //                         ),
// //                         const Divider(), // 可选的分隔线
// //                         // 为每个BillItem创建一个Tile
// //                         Column(
// //                           children: ListTile.divideTiles(
// //                             context: context,
// //                             tiles: itemsForDate.map((item) {
// //                               return ListTile(
// //                                 title: Text(item.item),
// //                                 trailing: Text(
// //                                   '${item.itemType == 0 ? '+' : '-'}${item.value.toStringAsFixed(2)}',
// //                                   style: TextStyle(
// //                                     fontSize: 14.sp,
// //                                     fontWeight: FontWeight.bold,
// //                                     color: item.itemType != 0
// //                                         ? Colors.black
// //                                         : Colors.green,
// //                                   ),
// //                                 ),
// //                                 // 可以添加其他信息，如时间戳等
// //                               );
// //                             }).toList(),
// //                           ).toList(),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 }
// //               },
// //               controller: scrollController,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   _buildSimpleFoodTile(BillItem bi, int index) {
// //     return Card(
// //       elevation: 5,
// //       child: ListTile(
// //         title: Text(
// //           "$index ${bi.date}",
// //           maxLines: 2,
// //           softWrap: true,
// //           overflow: TextOverflow.ellipsis,
// //           style: TextStyle(
// //             fontSize: 14,
// //             color: Theme.of(context).primaryColor,
// //           ),
// //         ),
// //         // 单份食物营养素
// //         subtitle: Text(
// //           "${bi.item} ${bi.value}",
// //           style: const TextStyle(fontSize: 12),
// //           maxLines: 2,
// //           softWrap: true,
// //           overflow: TextOverflow.ellipsis,
// //         ),
// //         // 点击看详情，长按修改？？？
// //         onTap: () {},
// //         onLongPress: () {},
// //       ),
// //     );
// //   }
// // }

// // /**
// // 在flutter中我有一个数据列表类似如下：
// // [
// // BillItem{
// //    billItemId: 39, itemType: 1, date: 2021-03-12, category: null, 
// //    item: 买肉, value: 26.5, gmtModified: 2024-05-23 10:47:19
// //  }
// // BillItem{
// //    billItemId: 52, itemType: 1, date: 2021-03-12, category: null, 
// //    item: 买肉菜, value: 35.8, gmtModified: 2024-05-23 10:47:19
// //  },
// // BillItem{
// //   billItemId: 170, itemType: 1, date: 2021-10-23, category: null, 
// //   item: 肉夹馍, value: 10.0, gmtModified: 2024-05-23 10:47:19
// // }
// // ……
// // ]

// // 现在我需要将date是一样的数据放在一起显示，一个日期用一个card，下面多个支出Tile
// //  */

// // ========================================== 日期改为弹窗

// // ignore_for_file: avoid_print

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'package:collection/collection.dart';
// import 'package:intl/intl.dart';

// import '../../common/components/tool_widget.dart';
// import '../../common/constants.dart';
// import '../../common/utils/db_helper.dart';
// import '../../models/brief_accounting_state.dart';
// import 'mock_data/index.dart';

// class BillItemIndex extends StatefulWidget {
//   const BillItemIndex({super.key});

//   @override
//   State<BillItemIndex> createState() => _BillItemIndexState();
// }

// class _BillItemIndexState extends State<BillItemIndex> {
//   final DBHelper _dbHelper = DBHelper();

//   List<BillItem> billItems = [];
//   int itemsCount = 0;
//   int currentPage = 1; // 数据库查询的时候会从0开始offset
//   int pageSize = 10;
//   bool isLoading = false;
//   ScrollController scrollController = ScrollController();
//   TextEditingController searchController = TextEditingController();
//   String query = '';
//   String queryMonth = DateFormat(constMonthFormat).format(DateTime.now());
//   List monthList = [DateFormat(constMonthFormat).format(DateTime.now())];

//   @override
//   void initState() {
//     super.initState();
//     _loadBillItemData();

//     _loadMonths();

//     scrollController.addListener(_scrollListener);
//   }

//   @override
//   void dispose() {
//     scrollController.removeListener(_scrollListener);
//     scrollController.dispose();
//     searchController.dispose();
//     super.dispose();
//   }

//   _loadMonths() async {
//     List<Map<String, Object?>> list = await _dbHelper.queryMonthList();
//     setState(() {
//       monthList = list.map((e) => e['month']).toList();
//     });
//   }

//   _buildYearMonthItems() {
//     List<DropdownMenuItem<String>> items = [];
//     for (var e in monthList) {
//       items.add(
//         DropdownMenuItem(
//           value: e,
//           alignment: AlignmentDirectional.center,
//           child: Text(e),
//         ),
//       );
//     }
//     return items;
//   }

//   /// 2024-05-23 这里的加载更多不应该和之前默认查询10条，加载完上滑时加载更多。
//   /// 最简单的，获取系统当月的所有账单条目查询出来(这样每日、月度统计就是正确的)，
//   /// 下滑显示完当月数据化，加载上一个月的所有数据出来
//   /// 即默认情况下，一个月一个月地加载
//   /// 【也正是基于统计的原因，是否保留关键字筛选？？？】
//   Future<void> _loadBillItemData() async {
//     print("进入了_loadBillItemData-------------");

//     if (isLoading) return;

//     setState(() {
//       isLoading = true;
//     });

//     CusDataResult temp = await _dbHelper.queryBillItemList(
//       // 按月查询，自动补上起止日期？？？
//       startDate: "${queryMonth.substring(0, 7)}-01",
//       endDate: "${queryMonth.substring(0, 7)}-31",
//       itemKeyword: query,
//       page: currentPage,
//       pageSize: 0,
//     );

//     var newData = temp.data as List<BillItem>;

//     setState(() {
//       billItems.addAll(newData);
//       itemsCount = temp.total;
//       currentPage++;
//       isLoading = false;
//     });
//   }

//   // 查询月度统计
//   // ？？？年度统计再看列表详情的话比较奇怪，和微信类似，多个年度统计tab，换个页面查询统计
//   Future<List<BillPeriodCount>?> _loadBillCountData() async {
//     try {
//       return await _dbHelper.queryBillCountList(
//         startDate: "${queryMonth.substring(0, 7)}-01",
//         endDate: "${queryMonth.substring(0, 7)}-31",
//       );
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }

//   void _scrollListener() {
//     if (isLoading) return;

//     final maxScrollExtent = scrollController.position.maxScrollExtent;
//     final currentPosition = scrollController.position.pixels;
//     final delta = 50.0.sp;

//     if (maxScrollExtent - currentPosition <= delta) {
//       _loadBillItemData();
//     }
//   }

//   void _handleSearch() {
//     setState(() {
//       billItems.clear();
//       currentPage = 1;
//       query = searchController.text;
//     });
//     // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
//     FocusScope.of(context).unfocus();

//     _loadBillItemData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         title: const Text("账单列表"),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               setState(() {
//                 billItems.clear();
//                 isLoading = true;
//               });

//               await loadUserFromAssets();

//               setState(() {
//                 isLoading = false;
//               });
//               _loadBillItemData();
//             },
//             child: const Text("Mock"),
//           ),
//         ],
//       ),

//       body: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 flex: 1,
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 20.sp),
//                   child: DropdownButton<String>(
//                     // 弹出的下拉框的最大高度
//                     menuMaxHeight: 300.sp,
//                     alignment: AlignmentDirectional.center,
//                     underline: Container(
//                       height: 2,
//                       color: Colors.deepPurpleAccent,
//                     ),
//                     style: const TextStyle(color: Colors.deepPurple),
//                     isDense: true,
//                     // isExpanded: true,
//                     value: queryMonth,
//                     items: _buildYearMonthItems(),
//                     onChanged: (String? newValue) {
//                       // 切换了月份，重新查询
//                       setState(() {
//                         queryMonth = newValue!;
//                         _handleSearch();
//                       });
//                     },
//                     hint: const Text('选择年月'),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: buildBillCountTile(),
//               ),
//             ],
//           ),

//           Padding(
//             padding: EdgeInsets.all(8.sp),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: searchController,
//                     decoration: const InputDecoration(
//                       hintText: "输入条目关键字",
//                       // 设置透明底色
//                       filled: true,
//                       fillColor: Colors.transparent,
//                     ),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: _handleSearch,
//                   child: const Text("搜索"),
//                 ),
//               ],
//             ),
//           ),

//           // Expanded(
//           //   child: ListView.builder(
//           //     itemCount: billItems.length + 1,
//           //     itemBuilder: (context, index) {
//           //       if (index == billItems.length) {
//           //         return buildLoader(isLoading);
//           //       } else {
//           //         print(billItems);
//           //         return _buildSimpleFoodTile(billItems[index], index);
//           //       }
//           //     },
//           //     controller: scrollController,
//           //   ),
//           // ),
//           /// 注意：其实这里每日的分组统计也是有瑕疵的。
//           /// 比如因为一次性查询10条，某一天的消费有11条，或者从第9条开始到第13条结束，
//           /// 那么在没有继续滚动到完全加载，每日累积值是错误的。
//           /// 也是基于此，不从billitemlist中分组统计月度、年度数据
//           Expanded(
//             child: ListView.builder(
//               itemCount: groupBy(billItems, (item) => item.date).length,
//               itemBuilder: (context, index) {
//                 if (index == groupBy(billItems, (item) => item.date).length) {
//                   return buildLoader(isLoading);
//                 } else {
//                   // 获取当前分组的日期和账单项列表
//                   MapEntry<String, List<BillItem>> entry =
//                       groupBy(billItems, (item) => item.date)
//                           .entries
//                           .elementAt(index);
//                   String date = entry.key;
//                   List<BillItem> itemsForDate = entry.value;

//                   // 计算每天的总花费
//                   var totalExpand = itemsForDate.fold(0.0, (sum, item) {
//                     if (item.itemType != 0) {
//                       // 如果是支出，则累加支出
//                       return sum + item.value;
//                     } else {
//                       // 没有支出则不累加
//                       return sum;
//                     }
//                   });

//                   var totalIncome = itemsForDate.fold(0.0, (sum, item) {
//                     // 如果当日有收入，累积收入
//                     if (item.itemType == 0) {
//                       return sum + item.value;
//                     } else {
//                       // 没有收入则不累加
//                       return sum;
//                     }
//                   });

//                   print("total --$totalExpand");

//                   return Card(
//                     child: Column(
//                       children: [
//                         ListTile(
//                           title: Text('日期: $date'),
//                           trailing: Text(
//                             '支出 ¥$totalExpand 收入 ¥$totalIncome',
//                           ),
//                           tileColor: Colors.lightGreen,
//                           dense: true,
//                           // 可以添加副标题或尾随图标等
//                         ),
//                         const Divider(), // 可选的分隔线
//                         // 为每个BillItem创建一个Tile
//                         Column(
//                           children: ListTile.divideTiles(
//                             context: context,
//                             tiles: itemsForDate.map((item) {
//                               return ListTile(
//                                 title: Text(item.item),
//                                 trailing: Text(
//                                   '${item.itemType == 0 ? '+' : '-'}${item.value.toStringAsFixed(2)}',
//                                   style: TextStyle(
//                                     fontSize: 10.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: item.itemType != 0
//                                         ? Colors.black
//                                         : Colors.green,
//                                   ),
//                                 ),
//                                 // 可以添加其他信息，如时间戳等
//                               );
//                             }).toList(),
//                           ).toList(),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//               },
//               controller: scrollController,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 这里是月度账单下拉后查询的总计结果，理论上只存在1条，不会为空。
//   buildBillCountTile() {
//     return FutureBuilder<List<BillPeriodCount>?>(
//       future: _loadBillCountData(),
//       builder: (BuildContext context,
//           AsyncSnapshot<List<BillPeriodCount>?> snapshot) {
//         List<Widget> children;
//         if (snapshot.hasData) {
//           var list = snapshot.data!;
//           // 有数据
//           children = <Widget>[
//             Text(
//                 "支出 ¥${list[0].expandTotalValue}  收入 ¥${list[0].incomeTotalValue}"),
//           ];
//         } else if (snapshot.hasError) {
//           // 有错误
//           children = <Widget>[
//             const Icon(Icons.error_outline, color: Colors.red, size: 30),
//           ];
//         } else {
//           // 加载中
//           children = const <Widget>[
//             SizedBox(width: 30, height: 30, child: CircularProgressIndicator()),
//             Padding(padding: EdgeInsets.only(top: 16), child: Text('加载中...')),
//           ];
//         }
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: children,
//           ),
//         );
//       },
//     );
//   }
// }

// /**
// 在flutter中我有一个数据列表类似如下：
// [
// BillItem{
//    billItemId: 39, itemType: 1, date: 2021-03-12, category: null, 
//    item: 买肉, value: 26.5, gmtModified: 2024-05-23 10:47:19
//  }
// BillItem{
//    billItemId: 52, itemType: 1, date: 2021-03-12, category: null, 
//    item: 买肉菜, value: 35.8, gmtModified: 2024-05-23 10:47:19
//  },
// BillItem{
//   billItemId: 170, itemType: 1, date: 2021-10-23, category: null, 
//   item: 肉夹馍, value: 10.0, gmtModified: 2024-05-23 10:47:19
// }
// ……
// ]

// 现在我需要将date是一样的数据放在一起显示，一个日期用一个card，下面多个支出Tile
//  */
