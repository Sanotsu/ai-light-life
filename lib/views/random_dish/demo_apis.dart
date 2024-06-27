// ignore_for_file: avoid_print

import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../common/components/tool_widget.dart';
import '../../common/constants.dart';
import '../../common/db_tools/db_helper.dart';
import '../../models/dish.dart';

final DBHelper _dbHelper = DBHelper();

Future<List<Object?>> insertDemoDish({int? size = 10}) async {
  print("【【【插入测试数据 start-->:insertDemoFood ");

  var foods = List.generate(
    size ?? 10,
    (index) => Dish(
      dishId: const Uuid().v1(),
      dishName: generateRandomString(5, 20),
      description: generateRandomString(50, 100),
      photos: [
        generateRandomString(10, 50),
        generateRandomString(10, 50),
        generateRandomString(10, 50),
      ].join(","),
      // 随机获取几个标签和分类，拼到一起
      tags: List.generate(
        Random().nextInt(5) + 1,
        (index) =>
            dishTagOptions[Random().nextInt(dishTagOptions.length)].value,
      ).join(","),
      mealCategories: List.generate(
        Random().nextInt(5) + 1,
        (index) =>
            dishCateOptions[Random().nextInt(dishCateOptions.length)].value,
      ).join(","),
      recipe: generateRandomString(50, 100),
    ),
  );

  var rst = await _dbHelper.insertDishList(foods);

  print("【【【插入测试数据 end-->:insertDemoFood ");

  return rst;
}
