// ignore_for_file: avoid_print

import 'dart:convert';

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../models/common_llm_info.dart';
import '_self_keys.dart';
import 'gen_access_token/tencet_hunyuan_signature_v3.dart';

/// 阿里平台通用aigc的请求地址
var aliyunAigcUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation";

/// 百度平台大模型API的前缀地址
const baiduAigcUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";
// 百度的token请求地址
const baiduAigcAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

/// 腾讯平台大模型API的前缀地址
const tencentAigcUrl = "https://hunyuan.tencentcloudapi.com/";

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///

///
///-----------------------------------------------------------------------------
/// 阿里云的请求方法
///
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

  var respData = await HttpUtils.post(
    path: "$baiduAigcUrl$model?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  // 响应是json格式
  return CommonRespBody.fromJson(respData);
}

///
///-----------------------------------------------------------------------------
/// 腾讯的请求方法
///
/// 获取指定设备类型(产品)包含的功能列表
Future<CommonRespBody> getTencentAigcCommonResp(
  List<CommonMessage> messages, {
  String? model,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? llmModels[PlatformLLM.tencentHunyuanLite]!;

  var body = CommonReqBody(model: model, messages: messages);

  var respData = await HttpUtils.post(
    path: tencentAigcUrl,
    method: HttpMethod.post,
    headers: genHunyuanLiteSignatureHeaders(
      commonReqBodyToJson(body, caseType: "pascal"),
    ),
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body.toJson(caseType: "pascal"),
  );

  /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
  if (respData.runtimeType == String) {
    respData = json.decode(respData);
  }

  // 响应是json格式
  return CommonRespBody.fromJson(respData["Response"]);
}
