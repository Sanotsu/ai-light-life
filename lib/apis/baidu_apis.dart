// ignore_for_file: avoid_print, constant_identifier_names

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/baidu_ernie_state.dart';
import '_self_keys.dart';

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///

///-------------------------------------------------
/// 列举支持的百度大模型，已经用于拼接url的字符串
/// 2024-05-31 从文档上来看，下面是免费的：
///  https://console.bce.baidu.com/qianfan/ais/console/onlineService?tab=preset
/// 限制：RPM=300,TPM=300000
///   RPM（Requests Per Minute）：每分钟处理请求数。
///   TPM（Tokens Per Minute）：每分钟处理tokens数（输入+输出）。
/// 注意，带日期的后续可能随时停用更版本的，注意跟进
enum ErnieLLM {
  Speed8K,
  Speed128K,
  SpeedAppBuilder,
  Lite8K0922,
  Lite8K0308,
  Tiny8K,
}

// 定义一个Map来存储枚举值和对应的字符串表示
final Map<ErnieLLM, String> llmStrings = {
  ErnieLLM.Speed8K: 'ernie_speed',
  ErnieLLM.Speed128K: 'ernie-speed-128k',
  ErnieLLM.SpeedAppBuilder: 'ai_apaas',
  ErnieLLM.Lite8K0922: 'eb-instant',
  ErnieLLM.Lite8K0308: 'ernie-lite-8k',
  ErnieLLM.Tiny8K: 'ernie-tiny-8k',
};

// 定义一个函数来从枚举值获取字符串表示
String? ernieLlmToString(ErnieLLM llmName) {
  // 取不到也返回null
  return llmStrings[llmName];
}

// 定义一个函数来从字符串获取枚举值
ErnieLLM stringToErnieLlm(String value) {
  for (final entry in llmStrings.entries) {
    if (entry.value == value) {
      return entry.key;
    }
  }
  // 如果找不到匹配的枚举值，则设置默认值
  return ErnieLLM.Speed8K;
}

// token请求地址
const baiduERNIEOAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

// 大模型API的前缀地址
const baiduErnieUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";

///-----------------------------------------------------------------------------

/// 使用 AK，SK 生成鉴权签名（Access Token）
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了
  var respData = await HttpUtils.post(
    path: baiduERNIEOAuthUrl,
    method: HttpMethod.post,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    data: {
      "grant_type": "client_credentials",
      "client_id": BAIDU_API_KEY,
      "client_secret": BAIDU_SECRET_KEY
    },
  );

  // 响应是json格式
  return respData['access_token'];
}

/// 获取指定设备类型(产品)包含的功能列表
Future<BaiduErnieResponseBody> getErnieSpeedResponse(
  List<ErnieMessage> messages, {
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  ErnieLLM llmName = ErnieLLM.Speed8K,
}) async {
  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  var body = BaiduErnieRequestBody(messages: messages);

  var nameStr =
      ernieLlmToString(llmName) ?? ernieLlmToString(ErnieLLM.Speed8K)!;

  var respData = await HttpUtils.post(
    path: "$baiduErnieUrl$nameStr?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  // 响应是json格式
  return BaiduErnieResponseBody.fromJson(respData);
}
