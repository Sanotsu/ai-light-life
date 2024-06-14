/// 定义云平台
enum CloudPlatform {
  baidu,
  tencent,
  aliyun,
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
  // baiduErnieLite8K0922, // 2024-07-04 下线
  // baiduErnieLite8K0308,
  baiduErnieLite8K, // 2024-06-12 有短信通知，使用不带日期后缀的为宜
  baiduErnieTiny8K,
  tencentHunyuanLite,
  aliyunQwen1p8BChat, // 1.8b -> 1point8b -> 1p8b
  aliyunQwen1p51p8BChat, //  千问1.5开源本，18亿参数
  aliyunQwen1p50p5BChat, //  千问1.5开源本，5亿参数
  aliyunFaruiPlus32K,
}

/// 定义一个Map来存储枚举值和对应的字符串表示
/// 一般这都是拼接在url中的，取值直接 `llmNames[llmName]` 就好
final Map<PlatformLLM, String> llmModels = {
  PlatformLLM.baiduErnieSpeed8K: 'ernie_speed',
  PlatformLLM.baiduErnieSpeed128K: 'ernie-speed-128k',
  // PlatformLLM.baiduErnieSpeedAppBuilder: 'ai_apaas',
  // PlatformLLM.baiduErnieLite8K0922: 'eb-instant',
  // PlatformLLM.baiduErnieLite8K0308: 'ernie-lite-8k',
  PlatformLLM.baiduErnieLite8K: 'ernie-lite-8k',
  PlatformLLM.baiduErnieTiny8K: 'ernie-tiny-8k',
  PlatformLLM.tencentHunyuanLite: 'hunyuan-lite', // 256k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p8BChat: 'qwen-1.8b-chat', // 8k上下文，最大输出2k
  PlatformLLM.aliyunQwen1p51p8BChat: 'qwen1.5-1.8b-chat', // 32k上下文，最大输出2k
  PlatformLLM.aliyunQwen1p50p5BChat: 'qwen1.5-0.5b-chat', // 32k上下文，最大输出2k
  PlatformLLM.aliyunFaruiPlus32K: 'farui-plus',
};

// 模型对应的中文名
final Map<PlatformLLM, String> llmNames = {
  PlatformLLM.baiduErnieSpeed8K: 'ERNIE-Speed-8K',
  PlatformLLM.baiduErnieSpeed128K: 'ERNIE-Speed-128K',
  // PlatformLLM.baiduErnieSpeedAppBuilder: 'ERNIE-Speed-AppBuilder-8K-0322',
  // PlatformLLM.baiduErnieLite8K0922: 'ERNIE-Lite-8K-0922',
  // PlatformLLM.baiduErnieLite8K0308: 'ERNIE-Lite-8K-0308',
  PlatformLLM.baiduErnieLite8K: 'ERNIE-Lite-8K',
  PlatformLLM.baiduErnieTiny8K: 'ERNIE-Tiny-8K',
  PlatformLLM.tencentHunyuanLite: '混元-Lite', // 256k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p8BChat: '通义千问-开源版-1.8B', // 8k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p51p8BChat: '通义千问1.5-开源版-1.8B', //32k上下文，最大输出2k
  PlatformLLM.aliyunQwen1p50p5BChat: '通义千问1.5-开源版-0.5B', //32k上下文，最大输出2k
  PlatformLLM.aliyunFaruiPlus32K: '通义法睿-Plus-32K',
};

// 模型对应的分类(比如短小的基础对话、专业的知识等)
final Map<PlatformLLM, String> llmDescriptions = {
  PlatformLLM.baiduErnieSpeed8K:
      'ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-8K是模型的一个版本，上下文窗口为8K。',
  PlatformLLM.baiduErnieSpeed128K:
      'ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-128K是模型的一个版本，上下文窗口为128K。。',
  // PlatformLLM.baiduErnieSpeedAppBuilder: '针对企业级大模型应用进行了专门的指令调优，在问答场景、智能体相关场景可以获得同等规模模型下更好的效果',
  // PlatformLLM.baiduErnieLite8K0922: '轻量级大语言模型，兼顾优异的模型效果与推理性能',
  // PlatformLLM.baiduErnieLite8K0308: '轻量级大语言模型，兼顾优异的模型效果与推理性能',
  PlatformLLM.baiduErnieLite8K:
      'ERNIE Lite是百度自研的轻量级大语言模型，兼顾优异的模型效果与推理性能，适合低算力AI加速卡推理使用。',
  PlatformLLM.baiduErnieTiny8K:
      'ERNIE Tiny是百度自研的超高性能大语言模型，部署与精调成本在文心系列模型中最低。\n\nERNIE-Tiny-8K是模型的一个版本，上下文窗口为8K。',
  PlatformLLM.tencentHunyuanLite:
      '腾讯混元大模型(Tencent Hunyuan)是由腾讯研发的大语言模型，具备强大的中文创作能力，复杂语境下的逻辑推理能力，以及可靠的任务执行能力。\\nn混元-Lite 升级为MOE结构，上下文窗口为256k，在NLP，代码，数学，行业等多项评测集上领先众多开源模型。',
  PlatformLLM.aliyunQwen1p8BChat:
      '"通义千问-开源版-1.8B"是通义千问对外开源的1.8B规模参数量的经过人类指令对齐的chat模型，模型支持 8k tokens上下文，API限定用户输入为6k Tokens。',
  PlatformLLM.aliyunQwen1p51p8BChat:
      '"通义千问1.5-开源版-1.8B"是通义千问1.5对外开源的1.8B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。',
  PlatformLLM.aliyunQwen1p50p5BChat:
      '"通义千问1.5-开源版-0.5B"是通义千问1.5对外开源的0.5B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。',
  PlatformLLM.aliyunFaruiPlus32K:
      '"通义法睿"是以通义千问为基座经法律行业数据和知识专门训练的法律行业大模型产品，综合运用了模型精调、强化学习、 RAG检索增强、法律Agent技术，具有回答法律问题、推理法律适用、推荐裁判类案、辅助案情分析、生成法律文书、检索法律知识、审查合同条款等功能。',
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
