// ignore_for_file: avoid_print

import 'dart:convert';

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../models/common_llm_info.dart';
import '_self_keys.dart';

/// 百度平台大模型API的前缀地址
const baiduAigcUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";
// 百度的token请求地址
const baiduAigcAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///

///
///-----------------------------------------------------------------------------
/// 百度的请求方法
///
/// 使用 AK，SK 生成鉴权签名（Access Token）
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了
  var respData = await HttpUtils.post(
    path: baiduAigcAuthUrl,
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
Future<CommonRespBody> getBaiduAigcCommonResp(
  List<CommonMessage> messages, {
  String? model,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  model = model ?? llmModels[PlatformLLM.baiduErnieSpeed8K]!;

  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  var body = CommonReqBody(messages: messages);

  var start = DateTime.now().millisecondsSinceEpoch;

  var respData = await HttpUtils.post(
    path: "$baiduAigcUrl$model?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  var end = DateTime.now().millisecondsSinceEpoch;

  print("1111111111xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

  // 响应是json格式
  return CommonRespBody.fromJson(respData);
}

/// 获取流式响应数据
Future<List<CommonRespBody>> getBaiduAigcStreamCommonResp(
  List<CommonMessage> messages, {
  String? model,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  model = model ?? llmModels[PlatformLLM.baiduErnieSpeed128K]!;

  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  var body = CommonReqBody(messages: messages, stream: true);

  var start = DateTime.now().millisecondsSinceEpoch;

  var respData = await HttpUtils.post(
    path: "$baiduAigcUrl$model?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  print("流失返回的数据---------$respData");

  var end = DateTime.now().millisecondsSinceEpoch;

  print("xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

  // 这里返回的是String，不是Map<String, dynamic>

  // 注意要手动处理拼接字符串
  // List<String> list =
  //     (respData as String).split("data:").where((e) => e.isNotEmpty).toList();

  // List jsonList =
  //     list.map((e) => CommonRespBody.fromJson(json.decode(e))).toList();

  List<CommonRespBody> list = (respData as String)
      .split("data:")
      .where((e) => e.isNotEmpty)
      .map((e) => CommonRespBody.fromJson(json.decode(e)))
      .toList();

  print("=======================bbbbbbbbbbbbb\n$list");

  // 响应是json格式
  return list;
}
