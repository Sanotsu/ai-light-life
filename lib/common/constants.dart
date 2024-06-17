// 时间格式化字符串
const constDatetimeFormat = "yyyy-MM-dd HH:mm:ss";
const constDateFormat = "yyyy-MM-dd";
const constMonthFormat = "yyyy-MM";
const constTimeFormat = "HH:mm:ss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';


const String placeholderImageUrl = 'assets/images/no_image.jpg';

// 数据库分页查询数据的时候，还需要带上一个该表的总数量
// 还可以按需补入其他属性
class CusDataResult {
  List<dynamic> data;
  int total;

  CusDataResult({
    required this.data,
    required this.total,
  });
}

// 自定义标签，常用来存英文、中文、全小写带下划线的英文等。
class CusLabel {
  final String enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({
    required this.enLabel,
    required this.cnLabel,
    required this.value,
  });
}

// 菜品的分类和标签都用预设的
// 2024-03-10 这个项目取值都直接取value，就不区别中英文了
List<CusLabel> dishTagOptions = [
  CusLabel(enLabel: 'LuCuisine', cnLabel: "鲁菜", value: '鲁菜'),
  CusLabel(enLabel: 'ChuanCuisine', cnLabel: "川菜", value: '川菜'),
  CusLabel(enLabel: 'YueCuisine', cnLabel: "粤菜", value: '粤菜'),
  CusLabel(enLabel: 'SuCuisine', cnLabel: "苏菜", value: '苏菜'),
  CusLabel(enLabel: 'MinCuisine', cnLabel: "闽菜", value: '闽菜'),
  CusLabel(enLabel: 'ZheCuisine', cnLabel: "浙菜", value: '浙菜'),
  CusLabel(enLabel: 'XiangCuisine', cnLabel: "湘菜", value: '湘菜'),
  CusLabel(enLabel: 'stir-fried', cnLabel: "炒", value: '炒'),
  CusLabel(enLabel: 'Quick-fry', cnLabel: "爆", value: '爆'),
  CusLabel(enLabel: 'sauté', cnLabel: "熘", value: '熘'),
  CusLabel(enLabel: 'fry', cnLabel: "炸", value: '炸'),
  CusLabel(enLabel: 'boil', cnLabel: "烹", value: '烹'),
  CusLabel(enLabel: 'decoct', cnLabel: "煎", value: '煎'),
  CusLabel(enLabel: 'paste', cnLabel: "贴", value: '贴'),
  CusLabel(enLabel: 'bake', cnLabel: "烧", value: '烧'),
  CusLabel(enLabel: 'sweat', cnLabel: "焖", value: '焖'),
  CusLabel(enLabel: 'stew', cnLabel: "炖", value: '炖'),
  CusLabel(enLabel: 'steam', cnLabel: "蒸", value: '蒸'),
  CusLabel(enLabel: 'quick-boil', cnLabel: "汆", value: '汆'),
  CusLabel(enLabel: 'boil', cnLabel: "煮", value: '煮'),
  CusLabel(enLabel: 'braise', cnLabel: "烩", value: '烩'),
  CusLabel(enLabel: 'Qiang', cnLabel: "炝", value: '炝'),
  CusLabel(enLabel: 'salt', cnLabel: "腌", value: '腌'),
  CusLabel(enLabel: 'stir-and-mix', cnLabel: "拌", value: '拌'),
  CusLabel(enLabel: 'roast', cnLabel: "烤", value: '烤'),
  CusLabel(enLabel: 'bittern', cnLabel: "卤", value: '卤'),
  CusLabel(enLabel: 'freeze', cnLabel: "冻", value: '冻'),
  CusLabel(enLabel: 'wire-drawing', cnLabel: "拔丝", value: '拔丝'),
  CusLabel(enLabel: 'honey-sauce', cnLabel: "蜜汁", value: '蜜汁'),
  CusLabel(enLabel: 'smoked', cnLabel: "熏", value: '熏'),
  CusLabel(enLabel: 'roll', cnLabel: "卷", value: '卷'),
  CusLabel(enLabel: 'other', cnLabel: "其他技法", value: '其他技法'),
];

List<CusLabel> dishCateOptions = [
  CusLabel(enLabel: 'Breakfast', cnLabel: "早餐", value: '早餐'),
  CusLabel(enLabel: 'Lunch', cnLabel: "早茶", value: '早茶'),
  CusLabel(enLabel: 'Lunch', cnLabel: "午餐", value: '午餐'),
  CusLabel(enLabel: 'AfternoonTea', cnLabel: "下午茶", value: '下午茶'),
  CusLabel(enLabel: 'Dinner', cnLabel: "晚餐", value: '晚餐'),
  CusLabel(enLabel: 'MidnightSnack', cnLabel: "夜宵", value: '夜宵'),
  CusLabel(enLabel: 'Dessert', cnLabel: "甜点", value: '甜点'),
  CusLabel(enLabel: 'Other', cnLabel: "其他", value: '其他'),
];
