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

### 依赖版本

2024-05-27 使用最新 flutter 版本：

```sh
$ flutter --version
Flutter 3.22.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision a14f74ff3a (4 天前) • 2024-05-22 11:08:21 -0500
Engine • revision 55eae6864b
Tools • Dart 3.4.1 • DevTools 2.34.3
```

主要的工具库:

```yaml
sqflite: ^2.3.3+1 # sqlite数据库工具库
path_provider: ^2.1.3 # 获取主机平台文件系统上的常用位置
path: ^1.9.0 # 基于字符串的路径操作库
flutter_easyloading: ^3.0.5 #  loading/toast 小部件
flutter_screenutil: ^5.9.1 # 适配屏幕和字体大小的插件
intl: ^0.19.0 # 国际化/本地化处理库
flutter_localizations:
  sdk: flutter
collection: ^1.18.0 # 集合相关的适用工具库
bottom_picker: ^2.7.0 # 简洁，但不支持仅年月
month_picker_dialog: ^3.0.0 # 支持仅年月，但是是弹窗，和原始组件类似
syncfusion_flutter_charts: ^25.2.5 # 图表库
flutter_form_builder: ^9.3.0 # 表单组件
form_builder_validators: ^10.0.1 # 表单验证
uuid: ^4.4.0 # uuid
```

### 开发记录

直接在 widget 上用的函数就不加下划线了，如果在其他函数中用的，就加下划线前缀。

- 2024-05-24
  - 基本完成账单列表首页的基础功能和组件占位.
- 2024-05-26
  - 基本完成月度年度统计基础柱状图展示和相关组件的占位
- 2024-04-27
  - feat:完成账单条目的新增和修改功能;chore:升级 flutter 为 3.22.1,相关依赖库为当前最新.
- 2024-05-28
  - 账单条目关键字查询时切换到新的列表展示;feat:完成带月统计值的列表展示在有多个月数据时滚动到某个月就加载某个月的总计.
  - perf:优化了图表页面的相关方法，重复度高的代码抽成了公共组件或方法。
  - perf:优化了账单项目列表主页面、编辑项次表单页面的相关方法和细节。
- 2024-05-29
  - 修正了一些细节；将新增账单项次放到账单列表页面中，调整账单项次表单页面；添加分类选择底部弹窗组件(暂未用到)。
  - 重新调整了账单管理模块的结构，新增 AGI LLM 模块用于对话的组件框架。
- 2024-05-30
  - feat:调价了基于 dio 的通用 http client 工具类；构建了 Ernie 和 huanyuan 模型的 model 以及基础查询函数。

### todo

- 账单管理
  - 分类占比饼图等其他统计图
  - 导入导出的备份(定时的自动备份？)
