/// 定义云平台
// ignore_for_file: constant_identifier_names

enum CloudPlatform {
  baidu,
  tencent,
  aliyun,
  limited, // 限时限量的测试
  siliconCloud,
}

// 模型对应的中文名
final Map<CloudPlatform, String> cpNames = {
  CloudPlatform.baidu: '百度',
  CloudPlatform.tencent: '腾讯',
  CloudPlatform.aliyun: '阿里',
  CloudPlatform.limited: '限量',
  CloudPlatform.siliconCloud: '硅动科技',
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
  // 少量免费的(9个)
  baiduErnieSpeed8KFREE,
  baiduErnieSpeed128KFREE,
  // baiduErnieSpeedAppBuilder,
  baiduErnieLite8KFREE, // 2024-06-12 有短信通知，使用不带日期后缀的为宜
  baiduErnieTiny8KFREE,
  tencentHunyuanLiteFREE,
  aliyunQwen1p8BChatFREE, // 1.8b -> 1point8b -> 1p8b
  aliyunQwen1p51p8BChatFREE, //  千问1.5开源本，18亿参数
  aliyunQwen1p50p5BChatFREE, //  千问1.5开源本，5亿参数
  aliyunFaruiPlus32KFREE,
  // 硅动科技免费的
  // SF 前缀 SiliconFlow中免费的
  // 命名规则：平台_企业_模型版本_参数(_类型)_上下文长度
  siliconCloud_Qwen2_7B_Instruct_FREE,
  siliconCloud_Qwen2_1p5B_Instruct_FREE, // 1p5B-> ipoint5B -> 1.5B
  siliconCloud_Qwen1p5_7B_Chat_FREE,
  siliconCloud_GLM4_9B_Chat_FREE,
  siliconCloud_ChatGLM3_6B_FREE,
  siliconCloud_Yi1p5_9B_Chat_16K_FREE,
  siliconCloud_Yi1p5_6B_Chat_FREE,

  /// 其实就是阿里云中限时限量的部分(25个)
  limitedQwenMax, // 8k，6k输入
  limitedQwenMax0428, // 8k，6k输入
  limitedQwenLong, // 10000k
  limitedQwenMaxLongContext, // 28k
  limitedQwenPlus, // 32k
  limitedQwenTurbo, // 8k
  limitedQwenVLMax, // 支持上传图片理解的对话
  limitedQwenVLPlus, // 支持上传图片理解的对话

  limitedBaichuan2Turbo, // 8k
  limitedBaichuan2Turbo192K, // 192k

  limitedBaichuan27BChatV1, // 4k
  limitedBaichuan213BChatV1, // 4k
  limitedBaichuan7BV1, // 4k

  limitedMoonshotV18K, // 8k
  limitedMoonshotV132K, // 32k
  limitedMoonshotV1128K, // 128k

  limitedLLaMa38B, // 8k
  limitedLLaMa370B, // 128k
  limitedLLaMa213B, // 128k

  limitedChatGLM26B, // 8k
  limitedChatGLM36B, // 8k

  limitedYiLarge, // 32k
  limitedYiLargeTurbo, // 16K
  limitedYiLargeRAG, // 16K
  limitedYiMedium, // 16K

  // 少量支持用户自行配置的付费的(10个)
  baiduErnie4p08K,
  baiduErnie3p58K,

  aliyunQwenMax,
  aliyunQwenPlus,
  aliyunQwenTurbo,
  aliyunQwenLong,
  aliyunQwenMaxLongContext,

  tencentHunyuanPro,
  tencentHunyuanStandard,
  tencentHunyuanStandard256k,
}

// 限时限量的对话模型(比底部的示例那个简单点)
class ChatLLMSpec {
  // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，到期时间、限量数值，
  /// 收费输入时百万token价格价格，输出时百万token价格(限时免费没写价格就先写0)
  final String model;
  final String name;
  final int contextLength;
  final DateTime deadline;
  final int freeAmount;
  final double inputPrice; // 每千token单价
  final double outputPrice;
  // 2024-06-21
  // 是否是视觉理解大模型(即是否可以解析图片、分析图片内容，然后进行对话)
  // 比如通义千问-VL 的接口参数和对话的基本无二致，只是入参多个图像image，所以可以放到一起试试
  // 如果模型支持视觉，就显示上传图片按钮，可加载图片
  bool? isVisonLLM;
  // 模型简述
  String? spec;

  ChatLLMSpec(this.model, this.name, this.contextLength, this.deadline,
      this.freeAmount, this.inputPrice, this.outputPrice,
      {this.isVisonLLM = false, this.spec});
}

// 2024-06-15 阿里云的限时限量都是这两个值，放在外面好了
final dt1 = DateTime.parse("2024-07-04");
const num1 = 400 * 10000;
final dt2 = DateTime.parse("2024-12-02");
const num2 = 100 * 10000;

// 2024-06-20 官方免费的，其实不限时限量
final dt3 = DateTime.parse("2099-12-31");
const num3 = -1 >>> 1;

/// 2024-06-14 这个可以抽成1个对象即可，暂时先改限时限量版本的
/// list 取值一定记住顺序：模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，限时字符串、限量数值，
/// 收费输入时百万token价格价格，输出时百万token价格(限时免费没写价格就先写0)
/// 2024-06-15 后续应该放到配置文件，或者用户导入（自行输入，那就要配置平台、密钥等，这就比较麻烦点了）
final Map<PlatformLLM, ChatLLMSpec> newLLMSpecs = {
  /// 下面是官方免费的
  PlatformLLM.baiduErnieSpeed8KFREE: ChatLLMSpec(
      "ernie_speed", 'ERNIESpeed8K', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          "ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-8K是模型的一个版本，上下文窗口为8K。"),
  PlatformLLM.baiduErnieSpeed128KFREE: ChatLLMSpec(
      "ernie-speed-128k", 'ERNIESpeed128K', 128 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          'ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-128K是模型的一个版本，上下文窗口为128K。。'),
  PlatformLLM.baiduErnieLite8KFREE: ChatLLMSpec(
      "ernie-lite-8k", 'ERNIELite8K', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: "ERNIE Lite是百度自研的轻量级大语言模型，兼顾优异的模型效果与推理性能，适合低算力AI加速卡推理使用。"),
  PlatformLLM.baiduErnieTiny8KFREE: ChatLLMSpec(
      "ernie-tiny-8k", 'ERNIETiny8K', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          "ERNIE Tiny是百度自研的超高性能大语言模型，部署与精调成本在文心系列模型中最低。\n\nERNIE-Tiny-8K是模型的一个版本，上下文窗口为8K。"),
  PlatformLLM.tencentHunyuanLiteFREE: ChatLLMSpec(
      "hunyuan-lite", '混元Lite', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          "腾讯混元大模型(Tencent Hunyuan)是由腾讯研发的大语言模型，具备强大的中文创作能力，复杂语境下的逻辑推理能力，以及可靠的任务执行能力。\\nn混元-Lite 升级为MOE结构，上下文窗口为256k，在NLP，代码，数学，行业等多项评测集上领先众多开源模型。"),
  PlatformLLM.aliyunQwen1p8BChatFREE: ChatLLMSpec(
      "qwen-1.8b-chat", '通义千问开源版1.8B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          '"通义千问-开源版-1.8B"是通义千问对外开源的1.8B规模参数量的经过人类指令对齐的chat模型，模型支持 8k tokens上下文，API限定用户输入为6k Tokens。'),
  PlatformLLM.aliyunQwen1p51p8BChatFREE: ChatLLMSpec(
      "qwen1.5-1.8b-chat", '通义千问1.5开源版', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          '通义千问1.5-开源版-1.8B"是通义千问1.5对外开源的1.8B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。'),
  PlatformLLM.aliyunQwen1p50p5BChatFREE: ChatLLMSpec(
      "qwen1.5-0.5b-chat", '通义千问1.5开源版0.5B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          '"通义千问1.5-开源版-0.5B"是通义千问1.5对外开源的0.5B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。'),
  PlatformLLM.aliyunFaruiPlus32KFREE: ChatLLMSpec(
      "farui-plus", '通义法睿Plus32K', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec:
          '"通义法睿"是以通义千问为基座经法律行业数据和知识专门训练的法律行业大模型产品，综合运用了模型精调、强化学习、 RAG检索增强、法律Agent技术，具有回答法律问题、推理法律适用、推荐裁判类案、辅助案情分析、生成法律文书、检索法律知识、审查合同条款等功能。'),

  PlatformLLM.siliconCloud_Qwen2_7B_Instruct_FREE: ChatLLMSpec(
      "Qwen/Qwen2-7B-Instruct", '通义千问2开源版7B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: '通义千问2开源版7B'),
  PlatformLLM.siliconCloud_Qwen2_1p5B_Instruct_FREE: ChatLLMSpec(
      "Qwen/Qwen2-1.5B-Instruct", '通义千问2开源版1.5B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: '通义千问2开源版1.5B'),
  PlatformLLM.siliconCloud_Qwen1p5_7B_Chat_FREE: ChatLLMSpec(
      "Qwen/Qwen1.5-7B-Chat", '通义千问1.5开源版7B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: '通义千问1.5开源版7B'),
  PlatformLLM.siliconCloud_GLM4_9B_Chat_FREE: ChatLLMSpec(
      "THUDM/glm-4-9b-chat", 'GLM4开源版9B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: 'GLM4开源版9B'),
  PlatformLLM.siliconCloud_ChatGLM3_6B_FREE: ChatLLMSpec(
      "THUDM/chatglm3-6b", 'ChatGLM3开源版6B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: 'ChatGLM3开源版6B'),
  PlatformLLM.siliconCloud_Yi1p5_9B_Chat_16K_FREE: ChatLLMSpec(
      "01-ai/Yi-1.5-6B-Chat", '零一万物1.5开源版9B', 16 * 1000, dt3, num3, 0.0, 0.0,
      spec: '零一万物1.5开源版9B'),
  PlatformLLM.siliconCloud_Yi1p5_6B_Chat_FREE: ChatLLMSpec(
      "01-ai/Yi-1.5-6B-Chat", '零一万物1.5开源版6B', 8 * 1000, dt3, num3, 0.0, 0.0,
      spec: '零一万物1.5开源版6B'),

  /// 下面是支持用户自行配置的少数几个(用户自己配置的，也当作不限时限量)

  // 百度
  PlatformLLM.baiduErnie4p08K: ChatLLMSpec(
      "completions_pro", 'ERNIE-4.0-8K', 8 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.baiduErnie3p58K:
      ChatLLMSpec("completions", 'ERNIE-3.5-8K', 8 * 1000, dt3, num3, 0.0, 0.0),
  // 阿里
  PlatformLLM.aliyunQwenMax:
      ChatLLMSpec("qwen-max", '通义千问-Max', 8 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.aliyunQwenPlus:
      ChatLLMSpec('qwen-plus', '通义千问-Plus', 32 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.aliyunQwenTurbo:
      ChatLLMSpec('qwen-turbo', '通义千问-Turbo', 8 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.aliyunQwenLong:
      ChatLLMSpec("qwen-long", '通义千问-长文', 10000 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.aliyunQwenMaxLongContext: ChatLLMSpec(
      'qwen-max-longcontext', '通义千问-Max-30K', 28 * 1000, dt3, num3, 0.0, 0.0),
  // 腾讯
  PlatformLLM.tencentHunyuanPro:
      ChatLLMSpec('hunyuan-pro', '混元Pro', 8 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.tencentHunyuanStandard: ChatLLMSpec(
      'hunyuan-standard', '混元Standard', 8 * 1000, dt3, num3, 0.0, 0.0),
  PlatformLLM.tencentHunyuanStandard256k: ChatLLMSpec(
      'hunyuan-standard-256K', '混元Standard256K', 8 * 1000, dt3, num3, 0.0, 0.0),

  /// 下面是受限的(因为使用一个虚构的limited平台，所以在显示的名称后面手动加上平台)
  // 通义千问
  PlatformLLM.limitedQwenMax:
      ChatLLMSpec("qwen-max", '通义千问-Max_阿里云', 8 * 1000, dt1, num1, 0.04, 0.12),
  PlatformLLM.limitedQwenMax0428: ChatLLMSpec(
      "qwen-max-0428", '通义千问-Max-0428_阿里云', 8 * 1000, dt1, num2, 0.04, 0.12),
  PlatformLLM.limitedQwenPlus: ChatLLMSpec(
      'qwen-plus', '通义千问-Plus_阿里云', 32 * 1000, dt1, num1, 0.004, 0.012),
  PlatformLLM.limitedQwenTurbo: ChatLLMSpec(
      'qwen-turbo', '通义千问-Turbo_阿里云', 8 * 1000, dt1, num1, 0.002, 0.006),
  PlatformLLM.limitedQwenLong: ChatLLMSpec(
      "qwen-long", '通义千问-长文_阿里云', 10000 * 1000, dt1, num1, 0.04, 0.12),
  PlatformLLM.limitedQwenMaxLongContext: ChatLLMSpec('qwen-max-longcontext',
      '通义千问-Max-30K_阿里云', 28 * 1000, dt1, num2, 0.04, 0.12),
  // 2024-06-21 视觉理解大模型
  PlatformLLM.limitedQwenVLMax: ChatLLMSpec(
      'qwen-vl-max', '通义千问VL-Max_阿里云', 8 * 1000, dt1, num2, 0.02, 0.02,
      isVisonLLM: true),
  PlatformLLM.limitedQwenVLPlus: ChatLLMSpec(
      'qwen-vl-plus', '通义千问VL-Plus_阿里云', 8 * 1000, dt1, num2, 0.008, 0.008,
      isVisonLLM: true),

  // 百川
  PlatformLLM.limitedBaichuan2Turbo: ChatLLMSpec('baichuan2-turbo',
      'Baichuan2-Turbo_百川', 4 * 1000, dt2, num2, 0.008, 0.008),
  PlatformLLM.limitedBaichuan2Turbo192K: ChatLLMSpec('baichuan2-turbo-192k',
      'Baichuan2-Turbo-192k_百川', 192 * 1000, dt2, num2, 0.008, 0.008),

  // 百川开源版
  PlatformLLM.limitedBaichuan27BChatV1: ChatLLMSpec('baichuan2-7b-chat-v1',
      'Baichuan2-7B_百川', 4 * 1000, dt2, num2, 0.008, 0.008),
  PlatformLLM.limitedBaichuan213BChatV1: ChatLLMSpec('baichuan2-13b-chat-v1',
      'Baichuan2-开源版-13B_百川', 4 * 1000, dt2, num2, 0.008, 0.008),
  PlatformLLM.limitedBaichuan7BV1: ChatLLMSpec('baichuan-7b-v1',
      'Baichuan2-开源版-7B_百川', 4 * 1000, dt2, num2, 0.008, 0.008),

  // 月之暗面
  PlatformLLM.limitedMoonshotV18K: ChatLLMSpec('moonshot-v1-8k',
      'Moonshot-v1-8K_月之暗面', 8 * 1000, dt2, num2, 0.008, 0.008),
  PlatformLLM.limitedMoonshotV132K: ChatLLMSpec('moonshot-v1-32k',
      'Moonshot-v1-32K_月之暗面', 32 * 1000, dt2, num2, 0.008, 0.008),
  PlatformLLM.limitedMoonshotV1128K: ChatLLMSpec('moonshot-v1-128k',
      'Moonshot-v1-128K_月之暗面', 128 * 1000, dt2, num2, 0.008, 0.008),

  // LLaMa
  PlatformLLM.limitedLLaMa38B: ChatLLMSpec(
      'llama3-8b-instruct', 'LLaMa3-8B_Meta', 8 * 1000, dt2, num2, 0.1, 0.1),
  PlatformLLM.limitedLLaMa370B: ChatLLMSpec(
      'llama3-70b-instruct', 'LLaMa3-70B_Meta', 8 * 1000, dt2, num2, 0.1, 0.1),
  PlatformLLM.limitedLLaMa213B: ChatLLMSpec(
      'llama2-13b-chat-v2', 'Llama2-13B_Meta', 8 * 1000, dt2, num2, 0.1, 0.1),

  // 智谱
  PlatformLLM.limitedChatGLM26B: ChatLLMSpec(
      'chatglm-6b-v2', 'ChatGLM2-6B_智谱', 8 * 1000, dt2, num2, 0.006, 0.006),
  PlatformLLM.limitedChatGLM36B: ChatLLMSpec(
      'chatglm3-6b', 'ChatGLM3-开源版-6B_智谱', 8 * 1000, dt2, num2, 0.006, 0.006),

  // 零一万物
  PlatformLLM.limitedYiLarge:
      ChatLLMSpec('yi-large', 'Yi-Large_零一万物', 32000, dt2, num2, 0, 0),
  PlatformLLM.limitedYiLargeTurbo: ChatLLMSpec(
      'yi-large-turbo', 'Yi-Large-Turbo_零一万物', 16000, dt2, num2, 0, 0),
  PlatformLLM.limitedYiLargeRAG:
      ChatLLMSpec('yi-large-rag', 'Yi-Large-RAG_零一万物', 16000, dt2, num2, 1, 1),
  PlatformLLM.limitedYiMedium:
      ChatLLMSpec('yi-medium', 'Yi-Medium_零一万物', 16000, dt2, num2, 1, 1),
};

///
///
/// 2024-06-14 大模型简单分成积累，默认的是对话模型，文生图、图生文等得另外来
///
///
enum Image2TextLLM {
  baiduFuyu8B, // 百度平台第三方的图像理解模型
}

final Map<Image2TextLLM, String> i2tLlmModels = {
  Image2TextLLM.baiduFuyu8B: 'fuyu-8b',
};
final Map<Image2TextLLM, String> i2tLlmNames = {
  Image2TextLLM.baiduFuyu8B: 'Fuyu-8B',
};
final Map<Image2TextLLM, String> i2tLlmDescriptions = {
  Image2TextLLM.baiduFuyu8B:
      'Fuyu-8B是由Adept AI训练的多模态图像理解模型，可以支持多样的图像分辨率，回答图形图表有关问题。模型在视觉问答和图像描述等任务上表现良好。',
};

///
///
/// 2024-06-21 上面的是单纯文本对话的大模型，下面是视觉理解大模型，即可以上传图片
/// 没法合并到一起是因为，之前通用的请求参数类中的 CommonMessage 的content 属性：
///     前者是一个String即可，
///     后者需要 [{String text,String image}] 的 list，
/// 也为了区分，切换不同页面，单独一个规格
///
///

// 通用视觉理解大模型信息
class VsionLLMSpec {
  // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，到期时间、限量数值，
  /// 收费输入时百万token价格价格，输出时百万token价格(限时免费没写价格就先写0)
  final String model;
  final String name;
  final int contextLength;
  final DateTime deadline;
  final int freeAmount;
  final double inputPrice; // 每千token单价
  final double outputPrice;
  // 2024-06-21
  // 是否是视觉理解大模型(即是否可以解析图片、分析图片内容，然后进行对话)
  // 比如通义千问-VL 的接口参数和对话的基本无二致，只是入参多个图像image，所以可以放到一起试试
  // 如果模型支持视觉，就显示上传图片按钮，可加载图片
  bool? isVisonLLM;

  VsionLLMSpec(this.model, this.name, this.contextLength, this.deadline,
      this.freeAmount, this.inputPrice, this.outputPrice,
      {this.isVisonLLM = false});
}
