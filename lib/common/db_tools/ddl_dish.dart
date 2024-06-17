/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class DishDdl {
  // db名称
  static String databaseName = "embedded_random_dish.db";

  // 菜品基础表
  static const tableNameOfDish = 'ba_dish';

  // 2023-03-10 避免导入时重复导入，还是加一个unique
  static const String ddlForDish = """
    CREATE TABLE $tableNameOfDish (
      dish_id           TEXT      NOT NULL PRIMARY KEY,
      dish_name         TEXT      NOT NULL,
      description       TEXT,
      photos            TEXT,
      videos            TEXT,
      tags              TEXT,
      meal_categories   TEXT,
      recipe            TEXT,
      recipe_picture    TEXT,
      UNIQUE(dish_name,tags)
    );
    """;
}
