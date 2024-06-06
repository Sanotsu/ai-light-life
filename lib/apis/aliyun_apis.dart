// ignore_for_file: avoid_print

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/aigc_state/platform_aigc_commom_state.dart';
import '../models/aliyun_bailian_state.dart';
import '_self_keys.dart';

var aliyunAigcUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation";

Future<AliyunBailianResponseBody> getBailianAigcResponse(
  List<AliyunMessage> messages, {
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  String llmName = "",
}) async {
  var body = AliyunBailianRequesBody(
    model: 'qwen-1.8b-chat',
    input: Input(messages: messages),
  );

  var respData = await HttpUtils.post(
    path: aliyunAigcUrl,
    method: HttpMethod.post,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $ALIYUN_API_KEY",
    },
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body,
  );

  print("===============$respData");

  // 响应是json格式
  return AliyunBailianResponseBody.fromJson(respData);
}

///
/// --------- 计划跨平台请求无感的方式---------------
///

Future<CommonRespBody> getAliyunAigcCommonResp(
  List<CommonMessage> messages, {
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  String llmName = "",
}) async {
  var body = CommonReqBody(
    model: 'qwen-1.8b-chat',
    input: AliyunInput(messages: messages),
    parameters: AliyunParameters(resultFormat: "message"),
  );

  var respData = await HttpUtils.post(
    path: aliyunAigcUrl,
    method: HttpMethod.post,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $ALIYUN_API_KEY",
    },
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body,
  );

  print("===============$respData");

  // 响应是json格式
  return CommonRespBody.fromJson(respData);
}
