/// 定义云平台
enum CloudPlatform {
  aliyun,
  tencent,
  baidu,
}

// 模型对应的中文名
final Map<CloudPlatform, String> cpNames = {
  CloudPlatform.baidu: '百度',
  CloudPlatform.tencent: '腾讯',
  CloudPlatform.aliyun: '阿里',
};

// 定义一个函数来从字符串获取枚举值
CloudPlatform stringToCloudPlatform(String value) {
  for (final entry in CloudPlatform.values) {
    if (entry.name == value) {
      return entry;
    }
  }
  // 如果找不到匹配的枚举值，则设置默认值
  return CloudPlatform.aliyun;
}

/// 所有的平台中可免费使用的模型
/// 后续可以根据模型的偏向分类，比如有的比较基础，有的比较擅长专业
/// 有可能的话，用户层不显示这些模型信息，平台连接的接口都统一话，服务于某方面的功能
enum PlatformLLM {
  baiduErnieSpeed8K,
  baiduErnieSpeed128K,
  // baiduErnieSpeedAppBuilder,
  baiduErnieLite8K0922,
  baiduErnieLite8K0308,
  baiduErnieTiny8K,
  tencentHunyuanLite,
  aliyunQwen1p8BChat, // 1.8b -> 1point8b -> 1p8b
  aliyunFaruiPlus32K,
}

/// 定义一个Map来存储枚举值和对应的字符串表示
/// 一般这都是拼接在url中的，取值直接 `llmNames[llmName]` 就好
final Map<PlatformLLM, String> llmModels = {
  PlatformLLM.baiduErnieSpeed8K: 'ernie_speed',
  PlatformLLM.baiduErnieSpeed128K: 'ernie-speed-128k',
  // PlatformLLM.baiduErnieSpeedAppBuilder: 'ai_apaas',
  PlatformLLM.baiduErnieLite8K0922: 'eb-instant',
  PlatformLLM.baiduErnieLite8K0308: 'ernie-lite-8k',
  PlatformLLM.baiduErnieTiny8K: 'ernie-tiny-8k',
  PlatformLLM.tencentHunyuanLite: 'hunyuan-lite', // 256k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p8BChat: 'qwen-1.8b-chat', // 8k上下文，最大输出6k
  PlatformLLM.aliyunFaruiPlus32K: 'farui-plus',
};

// 模型对应的中文名
final Map<PlatformLLM, String> llmNames = {
  PlatformLLM.baiduErnieSpeed8K: 'ERNIE-Speed-8K',
  PlatformLLM.baiduErnieSpeed128K: 'ERNIE-Speed-128K',
  // PlatformLLM.baiduErnieSpeedAppBuilder: 'ERNIE-Speed-AppBuilder-8K-0322',
  PlatformLLM.baiduErnieLite8K0922: 'ERNIE-Lite-8K-0922',
  PlatformLLM.baiduErnieLite8K0308: 'ERNIE-Lite-8K-0308',
  PlatformLLM.baiduErnieTiny8K: 'ERNIE-Tiny-8K',
  PlatformLLM.tencentHunyuanLite: '混元-Lite', // 256k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p8BChat: '通义千问-开源版-1.8B', // 8k上下文，最大输出6k
  PlatformLLM.aliyunFaruiPlus32K: '通义法睿-Plus-32K',
};

// 模型对应的分类(比如短小的基础对话、专业的知识等)
final Map<PlatformLLM, String> llmCategories = {
  PlatformLLM.baiduErnieSpeed8K: '通用能力',
  PlatformLLM.baiduErnieSpeed128K: '通用能力',
  // PlatformLLM.baiduErnieSpeedAppBuilder: '针对企业级大模型应用进行了专门的指令调优，在问答场景、智能体相关场景可以获得同等规模模型下更好的效果',
  PlatformLLM.baiduErnieLite8K0922: '轻量级大语言模型，兼顾优异的模型效果与推理性能',
  PlatformLLM.baiduErnieLite8K0308: '轻量级大语言模型，兼顾优异的模型效果与推理性能',
  PlatformLLM.baiduErnieTiny8K: '部署与精调成本在文心系列模型中最低',
  PlatformLLM.tencentHunyuanLite: '在NLP，代码，数学，行业等多项评测集上领先众多开源模型',
  PlatformLLM.aliyunQwen1p8BChat: '通义千问对外开源的1.8B规模参数量的经过人类指令对齐的chat模型',
  PlatformLLM.aliyunFaruiPlus32K: '通义法睿是以通义千问为基座经法律行业数据和知识专门训练的法律行业大模型产品',
};

///
/// 【？？？ 比较麻烦，暂时不弄了】
/// 2024-06-07 限量免费的，或者限时免费的放到下面来
///
/// 百度的：https://cloud.baidu.com/doc/WENXINWORKSHOP/s/hlrk4akp7
///

class LimitedLLM {
  // 模型所属的平台
  CloudPlatform platform;
  // 模型名称
  String name;
  // 用在拼接http请求或者作为参数时的模型字符串
  String model;
  // 分类：通用、轻量、专业、文生图……
  String? category;
  // 在处理限制时，要全部符合才行
  // 限定的token数量
  int? limitedTokenSize;
  // 限定的请求数量
  int? limitedRequestSize;
  // 限定的时间
  DateTime? deadline;

  LimitedLLM(
    this.platform,
    this.name,
    this.model,
    this.category,
    this.limitedTokenSize,
    this.limitedRequestSize,
    this.deadline,
  );
}

List requestLimitedLLM = [
  LimitedLLM(CloudPlatform.baidu, "Yi-34B-Chat", "yi_34b_chat", "chat", null,
      500, null),
  LimitedLLM(
      CloudPlatform.baidu, "Fuyu-8B", "fuyu_8b", "image2text", null, 500, null),
];
