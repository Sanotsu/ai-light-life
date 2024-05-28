import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../common/components/tool_widget.dart';
import '../../common/constants.dart';
import '../../common/utils/db_helper.dart';
import '../../models/brief_accounting_state.dart';
import '../home_page.dart';

///
/// 新增账单条目的简单布局：
///
/// 收入/支出选项(switch之类也行)
/// 选择大分类 category
/// 输入细项 item
/// 输入金额 value
/// 指定日期 datetime picker，默认当前，但也可以是添加以前的流水项目
///
class BillEditPage extends StatefulWidget {
  // 列表页面长按修改的时候可能会传账单条目
  final BillItem? billItem;

  const BillEditPage({super.key, this.billItem});

  @override
  State createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  final DBHelper _dbHelper = DBHelper();

  // 表单的全局key
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  // 表单输入金额是否有错
  bool _amountHasError = false;

  // 保存中
  bool isLoading = false;

  void _onChanged(dynamic val) => debugPrint(val.toString());

  // 这些选项都是FormBuilderChipOption类型
  String selectedCategoryType = "支出";
  var categoryList = [
    // 饮食
    "三餐", "外卖", "零食", "夜宵", "烟酒", "饮料",
    // 购物
    "购物", "买菜", "日用", "水果", "买花", "服装",
    // 娱乐
    "娱乐", "电影", "旅行", "运动", "纪念", "充值",
    // 住、行
    "交通", "住房", "房租", "房贷",
    // 生活
    "理发", "还款",
  ];
  var incomeCategoryList = [
    // 饮食
    "工资", "炒股", "基金", "摆摊", "投资", "代练",
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.billItem != null) {
        setState(() {
          _formKey.currentState?.patchValue(widget.billItem!.toStringMap());
          selectedCategoryType = widget.billItem!.itemType != 0 ? "支出" : "收入";
        });
      }
    });
  }

  // 构建收支条目
  List<FormBuilderChipOption<String>> _categoryChipOptions() {
    return (selectedCategoryType == "支出" ? categoryList : incomeCategoryList)
        .map((e) => FormBuilderChipOption(value: e))
        .toList();
  }

  /// 保存账单条目到数据库
  saveBillItem() async {
    if (_formKey.currentState!.saveAndValidate()) {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });

      var temp = _formKey.currentState!.value;

      var tempItem = BillItem(
        billItemId: const Uuid().v4(),
        itemType: temp['item_type'] == '收入' ? 0 : 1,
        date: DateFormat(constDateFormat).format(temp['date']),
        category: temp['category'],
        item: temp['item'],
        value: double.tryParse(temp['value']) ?? 0,
        gmtModified: DateFormat(constDatetimeFormat).format(DateTime.now()),
      );

      try {
        // 没传是新增
        if (widget.billItem == null) {
          await _dbHelper.insertBillItemList([tempItem]);
        } else {
          // 有传是修改
          tempItem.billItemId = widget.billItem!.billItemId;
          await _dbHelper.updateBillItem(tempItem);
        }

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        // 新增或修改成功了，跳转到主页面去(homepage默认是账单列表)
        // 因为可能是修改(从账单列表来的)或者新增(从新增按钮来的)，来源不一样，所以这里不是返回而是替换
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        commonExceptionDialog(context, "异常警告", e.toString());
        setState(() {
          isLoading = false;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.billItem != null ? '修改' : '新增'}账单项目"),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.saveAndValidate()) {
                // 处理表单数据，如保存到数据库等
                saveBillItem();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FormBuilderChoiceChip<String>(
                  name: 'item_type',
                  initialValue: '支出',
                  // 可让选项居中
                  alignment: WrapAlignment.center,
                  options: const [
                    FormBuilderChipOption(value: '支出'),
                    FormBuilderChipOption(value: '收入'),
                  ],
                  onChanged: (String? val) {
                    if (val != null) {
                      setState(() {
                        selectedCategoryType = val;
                      });
                    }
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                FormBuilderDateTimePicker(
                  name: 'date',
                  initialEntryMode: DatePickerEntryMode.calendar,
                  initialValue: DateTime.now(),
                  inputType: InputType.both,
                  decoration: InputDecoration(
                    labelText: '时间',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _formKey.currentState!.fields['date']?.didChange(null);
                      },
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  locale: Localizations.localeOf(context),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                FormBuilderChoiceChip<String>(
                  decoration: const InputDecoration(
                    labelText: '分类',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  name: 'category',
                  initialValue: '三餐',
                  // 可让选项居中
                  alignment: WrapAlignment.center,
                  // 选项标签的一些大小修改配置
                  labelStyle: TextStyle(fontSize: 10.sp),
                  labelPadding: EdgeInsets.all(1.sp),
                  elevation: 5,
                  // padding: EdgeInsets.all(0.sp),
                  // 标签之间垂直的间隔
                  // runSpacing: 10.sp,
                  // 标签之间水平的间隔
                  // spacing: 10.sp,
                  options: _categoryChipOptions(),
                  onChanged: _onChanged,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                FormBuilderTextField(
                  name: 'item',
                  decoration: const InputDecoration(
                    labelText: '项目',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  // initialValue: '12',
                  // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
                  // 2024-05-27 9.3.0 版本了还没修
                  enableSuggestions: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                FormBuilderTextField(
                  // autovalidateMode: AutovalidateMode.always,
                  name: 'value',
                  decoration: InputDecoration(
                    labelText: '金额',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                    suffixIcon: _amountHasError
                        ? const Icon(Icons.error, color: Colors.red)
                        : const Icon(Icons.check, color: Colors.green),
                  ),
                  onChanged: (val) {
                    setState(() {
                      // 如果金额输入不符合规范，尾部图标会实时切换
                      _amountHasError = !(_formKey.currentState?.fields['value']
                              ?.validate() ??
                          false);
                    });
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                  ]),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
