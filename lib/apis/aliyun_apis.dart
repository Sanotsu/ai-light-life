// ignore_for_file: avoid_print

import 'dart:convert';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../models/common_llm_info.dart';
import '_self_keys.dart';

/// 阿里平台通用aigc的请求地址
var aliyunAigcUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation";

Future<CommonRespBody> getAliyunAigcCommonResp(
  List<CommonMessage> messages, {
  String? model,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? llmModels[PlatformLLM.aliyunQwen1p8BChat]!;

  var body = CommonReqBody(
    model: model,
    input: AliyunInput(messages: messages),
    parameters: AliyunParameters(resultFormat: "message"),
  );

  var start = DateTime.now().millisecondsSinceEpoch;

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

  var end = DateTime.now().millisecondsSinceEpoch;

  print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

  // 响应是json格式
  return CommonRespBody.fromJson(respData);
}

Future<List<CommonRespBody>> getAliyunAigcStreamCommonResp(
  List<CommonMessage> messages, {
  String? model,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? llmModels[PlatformLLM.aliyunQwen1p8BChat]!;

  var body = CommonReqBody(
    model: model,
    input: AliyunInput(messages: messages),
    parameters: AliyunParameters(
      resultFormat: "message",
      incrementalOutput: true,
    ),
  );

  var start = DateTime.now().millisecondsSinceEpoch;

  var respData = await HttpUtils.post(
    path: aliyunAigcUrl,
    method: HttpMethod.post,
    headers: {
      "Accept": "text/event-stream", // 开启SSE
      "Content-Type": "application/json",
      "Authorization": "Bearer $ALIYUN_API_KEY",
    },
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body,
  );

  print("aliyun的SSE-----------$respData");

  // 使用正则表达式匹配所有以"data:{"开头的字符串
  final regex = RegExp(r'.*data:\{".*}', multiLine: true);
  final matches = regex.allMatches(respData);

  print("===============matches $matches");

  // 提取匹配到的字符串并添加到数组中
  List<String> dataArray = [];
  for (final match in matches) {
    // 替换"data:"为空字符串(看结果data后面的冒号没有空格)
    final replacedString = match.group(0)!.replaceAll(RegExp(r'data:'), '');
    dataArray.add(replacedString);
  }

  List<CommonRespBody> list =
      dataArray.map((e) => CommonRespBody.fromJson(json.decode(e))).toList();

  // 输出提取到的数据，或者进行其他操作

  print("===============$respData");

  var end = DateTime.now().millisecondsSinceEpoch;

  print("1111111111xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");
  print(dataArray);
  print(list);

  // 响应是json格式
  return list;
}
