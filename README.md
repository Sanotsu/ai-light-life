# free_brief_accounting

极度简单的支出流水账记录……

## Getting Started

虽然名字是记账，但实际上就是一些流水账(laundry list)

### 核心想法

记账，“账”虽然是重点，但也不应该忽视“记”这个动作，如果全都自动化了，岂不是"强化数字消费中的失去感"。

还是觉得手动记账，一笔一笔在输入时才能体会的金钱的份量、和记账的意义。

理论上：

- 消费和收入的分类应该有非常专业详细的数据，在后续的报表时肯定用得上。
- 多账本、预算、循环记账等等比较专业的东西，不会，所以没有。
- 什么其他账单的关联(微信、支付宝什么的)，就天方夜谭了。

所以，流水账，非常简单，sqlite 的 DDL：

```sql
CREATE TABLE "income_list" (
	"income_id"	    INTEGER NOT NULL,
	"date"	    TEXT,
	"category"	TEXT,
	"item"	    TEXT,
	"value"	    REAL,
	PRIMARY KEY("income_id" AUTOINCREMENT)
);

CREATE TABLE "expend_list" (
	"expend_id"	    INTEGER,
	"date"	    TEXT,
	"category"	TEXT,
	"item"	    TEXT,
	"value"	    REAL,
	PRIMARY KEY("expend_id" AUTOINCREMENT)
);
```

=>
再简单一点，只有一个表，用`type`表示收入和支出；
再加一个`gmt_modified`，排序时联合`date`栏位共同排序避免和实际新增记录时不一致

```sql
CREATE TABLE "bill_item_list" (
	"bill_item_id"	TEXT, 		-- 账单条目编号(万一多账本有bill_id呢)
	"item_type"		INTEGER,	-- 0 收入；1 支出
	"date"	    	TEXT,		-- yyyy-MM-dd 年月日即可
	"category"		TEXT,		-- 支出或收入的大分类(比如支出的：通勤、医疗、饮食……)
	"item"	    	TEXT,		-- 支出或收入的细项目(比如饮食的晚餐吃快餐) 还可以有细节就再多个detail表
	"value"	    	REAL,		-- 支出或收入的具体数值
	"gmt_modified"	TEXT,		-- 记录的创建或者修改时间
	PRIMARY KEY("bill_item_id")
);
```

目前设想的功能：

- 流水账(支出列表显示)的显示和记录(全手动输入的简单表单)
- 收入/支出 item 的关键字查询
- 报表仅仅按月、按年显示相关数据
  - (核心目的就是单纯想之前 python 编写的脚本绘制的柱状图在 app 显示罢了)

### 页面设计

就 3 个页面

- 主页面：列表显示每条支出/收入的数据
  - (测试数据的工资收入默认就每月 1 号到账了)
- 新增页面：非常简单的一个表单填写数据
- 报表页面：几个预设的简单图表
- 导入/导出：因为是 app 内置的 sqlite 中，所以导出备份比较重要
  - 方便导入导出，都 json 格式好了，不要什么 excel、pdf 之类的了，不好处理。
