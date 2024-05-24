/// 极简记账数据库中相关表的创建

class BriefAccountingDdl {
  // db名称
  static String databaseName = "brief_accounting.db";

// 账单条目表
  static const tableNameOfBillItem = 'ba_bill_item';

  static const String ddlForBillItem = """
    CREATE TABLE $tableNameOfBillItem (
      bill_item_id  TEXT      NOT NULL,
      item_type     INTEGER   NOT NULL,
      date	        TEXT,
      category      TEXT,
      item          TEXT      NOT NULL,
      value         REAL      NOT NULL,
      gmt_modified  TEXT      NOT NULL,
      PRIMARY KEY("bill_item_id")
    );
    """;

  /// ---------------------- 下面的暂时简化为上面，如果后续真的记录非常多，再考虑拆分为支出和收入两部分

  // 创建的表名加上数据库明缩写前缀，避免出现关键字问题
  // 基础活动基础表
  static const tableNameOfExpend = 'ba_expend';
  // 动作基础表
  static const tableNameOfIncome = 'ba_income';

  // (预留的)收入和支出的分类不一样，暂时只用一个表，加个栏位来区分时支出还是收入的分类
  static const tableNameOfCategory = 'ba_category';

  static const String ddlForExpend = """
    CREATE TABLE $tableNameOfExpend (
      expend_id   INTEGER,  NOT NULL,
      date	      TEXT,
      category    TEXT,
      item        TEXT      NOT NULL,
      value       REAL,     NOT NULL,
      PRIMARY KEY("expend_id" AUTOINCREMENT)
    );
    """;

  static const String ddlForIncome = """
    CREATE TABLE $tableNameOfIncome (
      income_id   INTEGER   NOT NULL,
      date	      TEXT,
      category    TEXT,
      item        TEXT      NOT NULL,
      value       REAL,     NOT NULL,
      PRIMARY KEY("income_id" AUTOINCREMENT)
    );
    """;
}
