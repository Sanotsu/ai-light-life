/// 定义云平台
enum CloudPlatform {
  aliyun,
  tencent,
  baidu,
}

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
  baiduErnieSpeedAppBuilder,
  baiduErnieLite8K0922,
  baiduErnieLite8K0308,
  baiduErnieTiny8K,
  tencentHunyuanLite,
  aliyunQwen1p8BChat, // 1.8b -> 1point8b -> 1p8b
}

/// 定义一个Map来存储枚举值和对应的字符串表示
/// 一般这都是拼接在url中的，取值直接 `llmNames[llmName]` 就好
final Map<PlatformLLM, String> llmNames = {
  PlatformLLM.baiduErnieSpeed8K: 'ernie_speed',
  PlatformLLM.baiduErnieSpeed128K: 'ernie-speed-128k',
  PlatformLLM.baiduErnieSpeedAppBuilder: 'ai_apaas',
  PlatformLLM.baiduErnieLite8K0922: 'eb-instant',
  PlatformLLM.baiduErnieLite8K0308: 'ernie-lite-8k',
  PlatformLLM.baiduErnieTiny8K: 'ernie-tiny-8k',
  PlatformLLM.tencentHunyuanLite: 'hunyuan-lite', // 256k上下文，最大输出6k
  PlatformLLM.aliyunQwen1p8BChat: 'qwen-1.8b-chat', // 8k上下文，最大输出6k
};
