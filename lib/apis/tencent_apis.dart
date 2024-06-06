// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:convert';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/aigc_state/platform_aigc_commom_state.dart';
import '../models/tencent_hunyuan_state.dart';
import 'tencet_hunyuan_signature_v3.dart';

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///

const tencentHunyuanLiteUrl = "https://hunyuan.tencentcloudapi.com/";

/// 获取指定设备类型(产品)包含的功能列表
Future<TencentHunYuanResponseBody> getHunyuanLiteResponse(
  List<HunyuanMessage> messages,
) async {
  var body = TencentHunYuanRequestBody(
    model: "hunyuan-lite",
    messages: messages,
  );

  var respData = await HttpUtils.post(
    path: tencentHunyuanLiteUrl,
    method: HttpMethod.post,
    headers: genHunyuanLiteSignatureHeaders(
      tencentHunYuanRequestBodyToJsonString(body),
    ),
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body,
  );

  print("===============$respData");

  // 响应是json格式
  return TencentHunYuanResponseBody.fromJson(respData["Response"]);
}

///
/// --------- 计划跨平台请求无感的方式---------------
///
/// 获取指定设备类型(产品)包含的功能列表
Future<CommonRespBody> getTencentAigcCommonResp(
  List<CommonMessage> messages, {
  // 万一以后有模型可选呢
  String llmName = "hunyuan-lite",
}) async {
  var body = CommonReqBody(model: llmName, messages: messages);

  var respData = await HttpUtils.post(
    path: tencentHunyuanLiteUrl,
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
