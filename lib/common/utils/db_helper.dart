// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/brief_accounting_state.dart';
import '../../models/llm_chat_state.dart';
import '../../models/llm_text2image_state.dart';
import 'ddl_brief_accounting.dart';

// 导出表文件临时存放的文件夹
const DB_EXPORT_DIR = "db_export";
// 导出的表前缀
const DB_EXPORT_TABLE_PREFIX = "ba_";

class DBHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBHelper _dbHelper = DBHelper._createInstance();
  // 构造函数，返回单例
  factory DBHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${DietaryDdl.databaseName}";

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${BriefAccountingDdl.databaseName}";

    print("初始化 DB sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var dietaryDb = await openDatabase(path, version: 1, onCreate: _createDb);
    dbFilePath = path;
    return dietaryDb;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    await db.transaction((txn) async {
      // txn.execute(BriefAccountingDdl.ddlForExpend);
      // txn.execute(BriefAccountingDdl.ddlForIncome);
      txn.execute(BriefAccountingDdl.ddlForBillItem);
      txn.execute(BriefAccountingDdl.ddlForChatHistory);
      txn.execute(BriefAccountingDdl.ddlForText2ImageHistory);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("db.isOpen ${db.isOpen}");
    await db.close();
    print("db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite db文件，db文件地址：$dbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dbFilePath);

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;
  }

  // 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    ))
        .map((row) => row['name'] as String)
        .toList(growable: false);

    print("DB中拥有的表名:------------");
    print(tableNames);
  }

  // 导出所有数据
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(
      p.join(appDocDir.path, DB_EXPORT_DIR),
    ).create();

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // 遍历所有表
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'];
      // 不是自建的表，不导出
      if (!tableName.startsWith(DB_EXPORT_TABLE_PREFIX)) {
        continue;
      }

      String tempFilePath = p.join(tempDir.path, '$tableName.json');

      // 查询表中所有数据
      List<Map<String, dynamic>> result = await db.query(tableName);

      // 将结果转换为JSON字符串
      String jsonStr = jsonEncode(result);

      // 创建临时导出文件
      File tempFile = File(tempFilePath);

      // 将JSON字符串写入临时文件
      await tempFile.writeAsString(jsonStr);

      // print('表 $tableName 已成功导出到：$tempFilePath');
    }
  }

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// BillItem 的相关操作
  ///

  // 新增(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertBillItemList(List<BillItem> billItems) async {
    var batch = (await database).batch();
    for (var item in billItems) {
      batch.insert(BriefAccountingDdl.tableNameOfBillItem, item.toMap());
    }

    print("新增账单条目了$billItems");
    return await batch.commit();
  }

  // 修改单条
  Future<int> updateBillItem(BillItem item) async => (await database).update(
        BriefAccountingDdl.tableNameOfBillItem,
        item.toMap(),
        where: 'bill_item_id = ?',
        whereArgs: [item.billItemId],
      );

  // 删除单条
  Future<int> deleteBillItemById(String billItemId) async =>
      (await database).delete(
        BriefAccountingDdl.tableNameOfBillItem,
        where: "bill_item_id=?",
        whereArgs: [billItemId],
      );

  // 账单查询默认查询所有不分页(全部查询到但加载时上滑显示更多；还是上滑时再查询？？？)
  // 但前端不会显示查询所有的选项，而是会指定日期范围
  // 一般是当日、当月、当年、最近3年，更多自定义范围根据需要来看是否支持
  Future<CusDataResult> queryBillItemList({
    String? billItemId,
    int? itemType, // 0 收入，1 支出
    String? itemKeyword, // 条目关键字
    String? startDate, // 日期范围
    String? endDate,
    double? minValue, // 金额范围
    double? maxValue,
    int? page,
    int? pageSize, // 不传就默认为10
  }) async {
    Database db = await database;

    print("账单查询传入的条件：");
    print("billItemId $billItemId");
    print("itemType $itemType");
    print("itemKeyword $itemKeyword");
    print("startDate $startDate");
    print("endDate $endDate");
    print("page $page");
    print("pageSize $pageSize");

    // 分页相关处理
    page ??= 1;
    // 如果size为0,则查询所有(暂时这个所有就10w吧)
    if (pageSize == 0) {
      pageSize = 100000;
    } else if (pageSize == null || pageSize < 1 && pageSize != 0) {
      pageSize = 10;
    }

    print("page2222 $page");
    print("pageSize2222 $pageSize");

    final offset = (page - 1) * pageSize;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (billItemId != null) {
      where.add('bill_item_id = ?');
      whereArgs.add(billItemId);
    }

    if (itemType != null) {
      where.add('item_type = ?');
      whereArgs.add(itemType);
    }

    if (itemKeyword != null) {
      where.add('item LIKE ?');
      whereArgs.add("%$itemKeyword%");
    }

    if (startDate != null && startDate != "") {
      where.add(" date >= ? ");
      whereArgs.add(startDate);
    }
    if (endDate != null && endDate != "") {
      where.add(" date <= ? ");
      whereArgs.add(endDate);
    }

    if (minValue != null) {
      where.add(" value >= ? ");
      whereArgs.add(minValue);
    }
    if (maxValue != null) {
      where.add(" value <= ? ");
      whereArgs.add(maxValue);
    }

    final rows = await db.query(
      BriefAccountingDdl.tableNameOfBillItem,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
      orderBy: "date DESC",
    );

    // 数据是分页查询的，但这里带上满足条件的一共多少条
    String sql =
        'SELECT COUNT(*) FROM ${BriefAccountingDdl.tableNameOfBillItem}';
    if (where.isNotEmpty) {
      sql += ' WHERE ${where.join(' AND ')}';
    }

    int totalCount =
        Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;

    print(sql);
    print("whereArgs $whereArgs totalCount $totalCount");

    var dishes = rows.map((row) => BillItem.fromMap(row)).toList();

    return CusDataResult(data: dishes, total: totalCount);
  }

  Future<CusDataResult> queryBillItemWithBillCountList({
    String? startDate, // 日期范围
    String? endDate,
    int? page,
    int? pageSize, // 不传就默认为10
  }) async {
    Database db = await database;

    print("queryBillItemWithBillCountList 账单查询传入的条件：");
    print("startDate $startDate");
    print("endDate $endDate");
    print("page $page");
    print("pageSize $pageSize");

    // 分页相关处理
    page ??= 1;
    // 如果size为0,则查询所有(暂时这个所有就10w吧)
    if (pageSize == 0) {
      pageSize = 100000;
    } else if (pageSize == null || pageSize < 1 && pageSize != 0) {
      pageSize = 10;
    }

    print("page2222 $page");
    print("pageSize2222 $pageSize");

    final offset = (page - 1) * pageSize;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    var formatStr = "%Y-%m";
    var rangeWhere = "";
    if (startDate != null && endDate != null) {
      rangeWhere = 'WHERE "date" BETWEEN "$startDate" AND "$endDate"';
    }

    // var sql2 = """
    //   SELECT
    //       *,
    //       strftime("$formatStr", "date") AS month,
    //       SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0 END) OVER (PARTITION BY strftime("$formatStr", "date")) AS expend_total,
    //       SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0 END) OVER (PARTITION BY strftime("$formatStr", "date")) AS income_total
    //   FROM ${BriefAccountingDdl.tableNameOfBillItem}
    //   $rangeWhere
    //   ORDER BY "date" DESC
    //   LIMIT $pageSize
    //   OFFSET $offset
    //   """;

    // sql2语句中的OVER、PARTITION等新特性好像 sqflite: 2.3.2 不支持,而且这个查询很耗性能
    var sql3 = """
      SELECT       
          b.*,  
        strftime("$formatStr", "date") AS month,
          (SELECT ROUND(SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0.0 END), 2) 
          FROM ${BriefAccountingDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS expend_total,  
          (SELECT ROUND(SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0.0 END), 2)  
          FROM ${BriefAccountingDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS income_total  
      FROM ${BriefAccountingDdl.tableNameOfBillItem} AS b
      $rangeWhere 
      ORDER BY b."date" DESC  
      LIMIT $pageSize 
      OFFSET $offset
      """;

    try {
      final rows = await db.rawQuery(sql3);

      // 数据是分页查询的，但这里带上满足条件的一共多少条
      String sql =
          'SELECT COUNT(*) FROM ${BriefAccountingDdl.tableNameOfBillItem}';
      if (where.isNotEmpty) {
        sql += ' WHERE ${where.join(' AND ')}';
      }

      int totalCount =
          Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;

      print(sql);
      print("whereArgs $whereArgs totalCount $totalCount");

      var dishes = rows.map((row) => BillItem.fromMap(row)).toList();

      return CusDataResult(data: dishes, total: totalCount);
    } catch (e) {
      print("eeeeeeeeeeeeeeee=$e");

      return CusDataResult(data: [], total: 1);
    }
  }

  /// 查询当前账单记录中存在的年月数据，供下拉筛选
  Future<List<Map<String, Object?>>> queryMonthList() async {
    return (await database).rawQuery(
      """
      SELECT DISTINCT strftime('%Y-%m', `date`) AS month     
      FROM ${BriefAccountingDdl.tableNameOfBillItem} 
      order by `date` DESC 
      """,
    );
  }

  // 账单中存在的日期范围，用筛选
  Future<SimplePeriodRange> queryDateRangeList() async {
    var list = await (await database).rawQuery(
      """
      SELECT MIN("date") AS min_date, MAX("date") AS max_date  
      FROM ${BriefAccountingDdl.tableNameOfBillItem} 
      """,
    );

    // 默认起止范围为当前
    var range = SimplePeriodRange(
      minDate: DateTime.now(),
      maxDate: DateTime.now(),
    );

    print("------------------$list");
    // 如果有账单记录，则获取到最大最小值
    if (list.isNotEmpty &&
        list.first["min_date"] != null &&
        list.first["max_date"] != null) {
      range = SimplePeriodRange.fromMap(list.first);
    }
    return range;
  }

  /// 查询月度、年度统计数据
  Future<List<BillPeriodCount>> queryBillCountList({
    // 年度统计year 或者月度统计 month
    String? countType,
    // 查询日期范围固定为年月日的完整日期格式，只是统计结果时才切分到年或月
    // 所有月度统计2024-04,但起止范围为2024-04-10 ~ 2024-04-15,也只是这5天的范围
    String? startDate,
    String? endDate,
  }) async {
    // 默认是月度统计，除非指定到年度统计
    var formatStr = "%Y-%m";
    if (countType == "year") {
      formatStr = "%Y";
    }

    // 默认统计所有，除非有指定范围
    var dateWhere = "";
    if (startDate != null && endDate != null) {
      dateWhere = ' "date" BETWEEN "$startDate" AND "$endDate" AND';
    }

    var sql = """
      SELECT         
          period,        
          round(SUM(expend_total_value), 2) AS expend_total_value,        
          round(SUM(income_total_value), 2) AS income_total_value,      
          CASE       
              WHEN SUM(income_total_value) = 0.0 THEN 0.0      
              ELSE round(SUM(expend_total_value) / NULLIF(SUM(income_total_value), 0.0), 5)      
          END AS ratio      
      FROM   
          (SELECT   
              strftime("$formatStr", "date") AS period,   
              CASE WHEN item_type = 1 THEN value ELSE 0.0 END AS expend_total_value,  
              CASE WHEN item_type = 0 THEN value ELSE 0.0 END AS income_total_value  
          FROM ${BriefAccountingDdl.tableNameOfBillItem}   
          WHERE $dateWhere item_type IN (0, 1)) AS combined_data  
      GROUP BY period        
      ORDER BY period ASC;
      """;

    var rows = await (await database).rawQuery(sql);
    return rows.map((row) => BillPeriodCount.fromMap(row)).toList();
  }

  // 简单统计每月、每年、每日的收支总计
  Future<List<BillPeriodCount>> querySimpleBillCountList({
    // 年度统计year 或者月度统计 month
    String? countType,
    // 查询日期范围固定为年月日的完整日期格式，只是统计结果时才切分到年或月
    // 所有月度统计2024-04,但起止范围为2024-04-10 ~ 2024-04-15,也只是这5天的范围
    String? startDate,
    String? endDate,
  }) async {
    // 默认是月度统计，除非指定到年度统计
    var formatStr = "%Y-%m";
    if (countType == "year") {
      formatStr = "%Y";
    } else if (countType == "day") {
      formatStr = "%Y-%m-%d";
    }

    // 默认统计所有，除非有指定范围
    var dateWhere = "";
    if (startDate != null && endDate != null) {
      dateWhere = ' WHERE "date" BETWEEN "$startDate" AND "$endDate" ';
    }

    var sql = """
      SELECT  
        strftime('$formatStr', "date") AS period,  
        round(SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0.0 END), 2) AS expend_total_value,  
        round(SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0.0 END), 2) AS income_total_value  
    FROM  
        ${BriefAccountingDdl.tableNameOfBillItem} 
    $dateWhere 
    GROUP BY period 
      """;

    var rows = await (await database).rawQuery(sql);
    return rows.map((row) => BillPeriodCount.fromMap(row)).toList();
  }

  ///***********************************************/
  /// AI chat 的相关操作
  ///

  // 查询所有对话记录
  Future<List<ChatSession>> queryChatList({
    String? uuid,
    String? keyword,
    String? cateType = 'aigc',
  }) async {
    Database db = await database;

    print("对话历史记录查询参数：");
    print("uuid $uuid");
    print("keyword $keyword");
    print("cateType $cateType");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (uuid != null) {
      where.add('uuid = ?');
      whereArgs.add(uuid);
    }

    if (keyword != null) {
      where.add('title LIKE ?');
      whereArgs.add("%$keyword%");
    }

    if (cateType != null) {
      where.add('chat_type = ?');
      whereArgs.add(cateType);
    }

    final rows = await db.query(
      BriefAccountingDdl.tableNameOfChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmt_create DESC",
    );

    return rows.map((row) => ChatSession.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteChatById(String uuid) async => (await database).delete(
        BriefAccountingDdl.tableNameOfChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertChatList(List<ChatSession> chats) async {
    var batch = (await database).batch();
    for (var item in chats) {
      batch.insert(BriefAccountingDdl.tableNameOfChatHistory, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateChatSession(ChatSession item) async =>
      (await database).update(
        BriefAccountingDdl.tableNameOfChatHistory,
        item.toMap(),
        where: 'uuid = ?',
        whereArgs: [item.uuid],
      );

  ///***********************************************/
  /// AI 文生图的相关操作
  ///

// 查询所有记录
  Future<List<TextToImageResult>> queryTextToImageResultList({
    String? requestId,
    String? prompt,
  }) async {
    Database db = await database;

    print("文生图历史记录查询参数：");
    print("uuid $requestId");
    print("正向提示词关键字 $prompt");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (requestId != null) {
      where.add('request_id = ?');
      whereArgs.add(requestId);
    }

    if (prompt != null) {
      where.add('prompt LIKE ?');
      whereArgs.add("%$prompt%");
    }

    final rows = await db.query(
      BriefAccountingDdl.tableNameOfText2ImageHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmt_create DESC",
    );

    return rows.map((row) => TextToImageResult.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteTextToImageResultById(String requestId) async =>
      (await database).delete(
        BriefAccountingDdl.tableNameOfText2ImageHistory,
        where: "request_id=?",
        whereArgs: [requestId],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertTextToImageResultList(
      List<TextToImageResult> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        BriefAccountingDdl.tableNameOfText2ImageHistory,
        item.toMap(),
      );
    }
    return await batch.commit();
  }
}
