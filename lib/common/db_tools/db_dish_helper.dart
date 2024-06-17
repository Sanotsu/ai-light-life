// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dish.dart';
import '../constants.dart';
import 'db_helper.dart';
import 'ddl_dish.dart';

class DBDishHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDishHelper _dbHelper = DBDishHelper._createInstance();
  // 构造函数，返回单例
  factory DBDishHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDishHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${DishDdl.databaseName}";

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
      txn.execute(DishDdl.ddlForDish);
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
  /// dish 的相关操作
  ///

  // 新增多条食物(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertDishList(List<Dish> dishes) async {
    var batch = (await database).batch();
    for (var item in dishes) {
      batch.insert(DishDdl.tableNameOfDish, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条基础
  Future<int> updateDish(Dish dish) async => (await database).update(
        DishDdl.tableNameOfDish,
        dish.toMap(),
        where: 'dish_id = ?',
        whereArgs: [dish.dishId],
      );

  // 删除单条
  Future<int> deleteDishById(String dishId) async => (await database).delete(
        DishDdl.tableNameOfDish,
        where: "dish_id=?",
        whereArgs: [dishId],
      );

  // 条件查询食物列表
  Future<CusDataResult> queryDishList({
    String? dishId,
    String? dishName,
    List<String>? tags, // 食物的分类和餐次查询为多个，只有一个就一个值的数组
    List<String>? mealCategories,
    int? page,
    int? pageSize,
  }) async {
    Database db = await database;

    print("菜品条件查询传入的条件：");
    print("dishId $dishId");
    print("dishName $dishName");
    print("tags $tags");
    print("mealCategories $mealCategories");
    print("page $page");
    print("pageSize $pageSize");

    // f分页相关处理
    page ??= 1;
    pageSize ??= 10;

    final offset = (page - 1) * pageSize;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (dishId != null) {
      where.add('dish_id = ?');
      whereArgs.add(dishId);
    }

    if (dishName != null) {
      where.add('dish_name LIKE ?');
      whereArgs.add("%$dishName%");
    }

    // 这里应该是内嵌的or
    if (tags != null && tags.isNotEmpty) {
      for (var tag in tags) {
        where.add('tags LIKE ?');
        whereArgs.add("%$tag%");
      }
    }

    if (mealCategories != null && mealCategories.isNotEmpty) {
      for (var cate in mealCategories) {
        where.add('meal_categories LIKE ?');
        whereArgs.add("%$cate%");
      }
    }

    final dishRows = await db.query(
      DishDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
    );

    // 这个只有食物名称的关键字查询结果
    int? totalCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DishDdl.tableNameOfDish} '
        'WHERE dish_name LIKE ? ',
        ['%$dishName%'],
      ),
    );

    print('dish Total count: $totalCount, dishRows 长度 ${dishRows.length}');

    var dishes = dishRows.map((row) => Dish.fromMap(row)).toList();

    return CusDataResult(data: dishes, total: totalCount ?? 0);
  }

  // 随机查询10条数据
  // 主页显示的时候需要，可以传餐次和数量
  Future<List<Dish>> queryRandomDishList({String? cate, int? size = 10}) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cate != null) {
      where.add('meal_categories like ?');
      whereArgs.add('%$cate%');
    }

    List<Map<String, dynamic>> randomRows = await db.query(
      DishDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'RANDOM()',
      limit: size,
    );

    return randomRows.map((row) => Dish.fromMap(row)).toList();
  }
}
