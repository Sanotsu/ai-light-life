// ignore_for_file: avoid_print, constant_identifier_names

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
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
  var body = TencentHunYuanRequestBody(messages: messages);

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
