// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// 付费的和免费的分开来，不管是平台还是指定模型
/// 如果是平台既有免费又有付费，则两边都有
/// 2024-08-08 这里全是免费的

/// 定义云平台
/// FreeCloudPlatform
enum FreeCP {
  baidu,
  tencent,
  aliyun,
  siliconCloud,
}

// 模型对应的中文名
final Map<FreeCP, String> FREE_CP_NAME_MAP = {
  FreeCP.baidu: '百度',
  FreeCP.tencent: '腾讯',
  FreeCP.aliyun: '阿里',
  FreeCP.siliconCloud: '硅动科技',
};

/// 所有免费平台中免费对话模型
/// 基座模型（base）、聊天模型（chat）和指令模型（instruct/it）
enum FreeCCLLM {
  // 命名规则(尽量)：部署所在平台_模型版本_参数(_类型)_上下文长度
  baidu_Ernie_Speed_8K,
  baidu_Ernie_Speed_128K,
  // baiduErnieSpeedAppBuilder,
  baidu_Ernie_Lite_8K,
  baidu_Ernie_Tiny_8K,
  tencent_Hunyuan_Lite,
  aliyun_Qwen_1p8B_Chat,
  aliyun_Qwen1p5_1p8B_Chat,
  aliyun_Qwen1p5_0p5B_Chat,
  aliyun_FaruiPlus_32K,
  // 硅动科技免费的
  siliconCloud_Qwen2_7B_Instruct,
  siliconCloud_Qwen2_1p5B_Instruct,
  siliconCloud_Qwen1p5_7B_Chat,
  siliconCloud_GLM4_9B_Chat,
  siliconCloud_ChatGLM3_6B,
  siliconCloud_Yi1p5_9B_Chat_16K,
  siliconCloud_Yi1p5_6B_Chat,
  // 2024-08-08 查看时又有一些免费的(国外的，英文模型)
  siliconCloud_GEMMA2_9B_Instruct,
  siliconCloud_InternLM2p5_7B_Chat,
  siliconCloud_LLAMA3_8B_Instruct,
  siliconCloud_LLAMA3p1_8B_Instruct,
  siliconCloud_Mistral_7B_Instruct_v0p2,
}

// 限时限量的对话模型(比底部的示例那个简单点)
class FreeCCLLMSpec {
  // 模型字符串(平台API参数的那个model的值,一般要做为参数)
  final String model;
  // 模型名称(主要用于显示)
  final String name;
  // 上下文长度数值
  final int contextLength;
  // 模型简述
  String spec;

  FreeCCLLMSpec(this.model, this.name, this.contextLength, this.spec);
}

final Map<FreeCCLLM, FreeCCLLMSpec> Free_CC_LLM_SPEC_MAP = {
  /// 下面是官方免费的
  FreeCCLLM.baidu_Ernie_Speed_8K: FreeCCLLMSpec(
    "ernie_speed",
    'ERNIESpeed8K',
    8 * 1000,
    "ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-8K是模型的一个版本，上下文窗口为8K。",
  ),
  FreeCCLLM.baidu_Ernie_Speed_128K: FreeCCLLMSpec(
    "ernie-speed-128k",
    'ERNIESpeed128K',
    128 * 1000,
    'ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。\n\nERNIE-Speed-128K是模型的一个版本，上下文窗口为128K。',
  ),
  FreeCCLLM.baidu_Ernie_Lite_8K: FreeCCLLMSpec(
    "ernie-lite-8k",
    'ERNIELite8K',
    8 * 1000,
    "ERNIE Lite是百度自研的轻量级大语言模型，兼顾优异的模型效果与推理性能，适合低算力AI加速卡推理使用。",
  ),
  FreeCCLLM.baidu_Ernie_Tiny_8K: FreeCCLLMSpec(
    "ernie-tiny-8k",
    'ERNIETiny8K',
    8 * 1000,
    "ERNIE Tiny是百度自研的超高性能大语言模型，部署与精调成本在文心系列模型中最低。\n\nERNIE-Tiny-8K是模型的一个版本，上下文窗口为8K。",
  ),
  FreeCCLLM.tencent_Hunyuan_Lite: FreeCCLLMSpec(
    "hunyuan-lite",
    '混元Lite',
    8 * 1000,
    "腾讯混元大模型(Tencent Hunyuan)是由腾讯研发的大语言模型，具备强大的中文创作能力，复杂语境下的逻辑推理能力，以及可靠的任务执行能力。\\nn混元-Lite 升级为MOE结构，上下文窗口为256k，在NLP，代码，数学，行业等多项评测集上领先众多开源模型。",
  ),
  FreeCCLLM.aliyun_Qwen_1p8B_Chat: FreeCCLLMSpec(
    "qwen-1.8b-chat",
    '通义千问开源版1.8B_对话',
    8 * 1000,
    '"通义千问-开源版-1.8B"是通义千问对外开源的1.8B规模参数量的经过人类指令对齐的chat模型，模型支持 8k tokens上下文，API限定用户输入为6k Tokens。',
  ),
  FreeCCLLM.aliyun_Qwen1p5_1p8B_Chat: FreeCCLLMSpec(
    "qwen1.5-1.8b-chat",
    '通义千问1.5开源版1.8B_对话',
    8 * 1000,
    '通义千问1.5-开源版-1.8B"是通义千问1.5对外开源的1.8B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。',
  ),
  FreeCCLLM.aliyun_Qwen1p5_0p5B_Chat: FreeCCLLMSpec(
    "qwen1.5-0.5b-chat",
    '通义千问1.5开源版0.5B_对话',
    8 * 1000,
    '"通义千问1.5-开源版-0.5B"是通义千问1.5对外开源的0.5B规模参数量是经过人类指令对齐的chat模型，模型支持 32k tokens上下文，API限定用户输入为30k Tokens。',
  ),
  FreeCCLLM.aliyun_FaruiPlus_32K: FreeCCLLMSpec(
    "farui-plus",
    '通义法睿Plus32K',
    8 * 1000,
    '"通义法睿"是以通义千问为基座经法律行业数据和知识专门训练的法律行业大模型产品，综合运用了模型精调、强化学习、 RAG检索增强、法律Agent技术，具有回答法律问题、推理法律适用、推荐裁判类案、辅助案情分析、生成法律文书、检索法律知识、审查合同条款等功能。',
  ),

  FreeCCLLM.siliconCloud_Qwen2_7B_Instruct: FreeCCLLMSpec(
    "Qwen/Qwen2-7B-Instruct",
    '通义千问2开源版7B_指令',
    8 * 1000,
    '通义千问2开源版7B_指令模型',
  ),
  FreeCCLLM.siliconCloud_Qwen2_1p5B_Instruct: FreeCCLLMSpec(
    "Qwen/Qwen2-1.5B-Instruct",
    '通义千问2开源版1.5B_指令',
    8 * 1000,
    '通义千问2开源版1.5B_指令模型',
  ),
  FreeCCLLM.siliconCloud_Qwen1p5_7B_Chat: FreeCCLLMSpec(
    "Qwen/Qwen1.5-7B-Chat",
    '通义千问1.5开源版7B_对话',
    8 * 1000,
    '通义千问1.5开源版7B_对话模型',
  ),
  FreeCCLLM.siliconCloud_GLM4_9B_Chat: FreeCCLLMSpec(
    "THUDM/glm-4-9b-chat",
    'GLM4开源版9B_对话',
    8 * 1000,
    'GLM4开源版9B_对话模型',
  ),
  FreeCCLLM.siliconCloud_ChatGLM3_6B: FreeCCLLMSpec(
    "THUDM/chatglm3-6b",
    'ChatGLM3开源版6B_对话',
    8 * 1000,
    'ChatGLM3开源版6B_对话模型',
  ),
  FreeCCLLM.siliconCloud_Yi1p5_9B_Chat_16K: FreeCCLLMSpec(
    "01-ai/Yi-1.5-6B-Chat",
    '零一万物1.5开源版9B_对话',
    16 * 1000,
    '零一万物1.5开源版9B_对话模型',
  ),
  FreeCCLLM.siliconCloud_Yi1p5_6B_Chat: FreeCCLLMSpec(
    "01-ai/Yi-1.5-6B-Chat",
    '零一万物1.5开源版6B_对话',
    8 * 1000,
    '零一万物1.5开源版6B_对话模型',
  ),
  // 2024-08-08 查看时又有一些免费的(国际领先的模型，最好使用英文指令)
  FreeCCLLM.siliconCloud_GEMMA2_9B_Instruct: FreeCCLLMSpec(
    "google/gemma-2-9b-it",
    '国际_Gemma2_9B_指令',
    8 * 1000,
    '国际模型_谷歌gemma2_9B_指令模型',
  ),
  FreeCCLLM.siliconCloud_InternLM2p5_7B_Chat: FreeCCLLMSpec(
    "internlm/internlm2_5-7b-chat",
    '国际_InternLM2.5_7B_对话',
    32 * 1000,
    '国际模型_InternLM2.5_7B_对话模型',
  ),
  FreeCCLLM.siliconCloud_LLAMA3_8B_Instruct: FreeCCLLMSpec(
    "meta-llama/Meta-Llama-3-8B-Instruct",
    '国际_Llama3_8B_指令',
    8 * 1000,
    '国际模型_Meta_LLAMA3_8B_指令模型',
  ),
  FreeCCLLM.siliconCloud_LLAMA3p1_8B_Instruct: FreeCCLLMSpec(
    "meta-llama/Meta-Llama-3.1-8B-Instruct",
    '国际_Llama 3.1_8B_指令',
    8 * 1000,
    '国际模型_Meta_LLAMA3.1_8B_指令模型',
  ),
  FreeCCLLM.siliconCloud_Mistral_7B_Instruct_v0p2: FreeCCLLMSpec(
    "mistralai/Mistral-7B-Instruct-v0.2",
    '国际_Mistral_7B_指令',
    32 * 1000,
    '国际模型_Mistral_7B_指令模型',
  ),
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
