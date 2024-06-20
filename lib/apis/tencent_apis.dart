// // ignore_for_file: avoid_print

// import 'dart:convert';

// import '../dio_client/cus_http_client.dart';
// import '../dio_client/cus_http_request.dart';
// import '../models/ai_interface_state/platform_aigc_commom_state.dart';
// import '../models/common_llm_info.dart';

// import '../services/cus_get_storage.dart';
// import '_self_keys.dart';
// import 'gen_access_token/tencet_hunyuan_signature_v3.dart';

// /// 腾讯平台大模型API的前缀地址
// const tencentAigcUrl = "https://hunyuan.tencentcloudapi.com/";

// ///
// ///-----------------------------------------------------------------------------
// /// 腾讯的请求方法
// ///
// /// 获取指定设备类型(产品)包含的功能列表【暂没用到】
// Future<CommonRespBody> getTencentAigcCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
//   bool isUserConfig = true,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   model = model ?? llmModels[PlatformLLM.tencentHunyuanLiteFREE]!;

//   var body = CommonReqBody(model: model, messages: messages);

//   var respData = await HttpUtils.post(
//     path: tencentAigcUrl,
//     method: HttpMethod.post,
//     headers: genHunyuanLiteSignatureHeaders(
//       commonReqBodyToJson(body, caseType: "pascal"),
//       isUserConfig ? MyGetStorage().getCusAppId() ?? "" : TENCENT_SECRET_ID,
//       isUserConfig ? MyGetStorage().getCusAppKey() ?? "" : TENCENT_SECRET_KEY,
//     ),
//     // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
//     data: body.toJson(caseType: "pascal"),
//   );

//   /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
//   if (respData.runtimeType == String) {
//     respData = json.decode(respData);
//   }

//   // 响应是json格式
//   return CommonRespBody.fromJson(respData["Response"]);
// }

// /// 获取流式响应数据【暂没用到】
// Future<List<CommonRespBody>> getTencentAigcStreamCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
//   bool isUserConfig = true,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   model = model ?? llmModels[PlatformLLM.tencentHunyuanLiteFREE]!;

//   var body = CommonReqBody(model: model, messages: messages, stream: true);

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: tencentAigcUrl,
//     method: HttpMethod.post,
//     headers: genHunyuanLiteSignatureHeaders(
//       commonReqBodyToJson(body, caseType: "pascal"),
//       isUserConfig ? MyGetStorage().getCusAppId() ?? "" : TENCENT_SECRET_ID,
//       isUserConfig ? MyGetStorage().getCusAppKey() ?? "" : TENCENT_SECRET_KEY,
//     ),
//     // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
//     data: body.toJson(caseType: "pascal"),
//   );

//   print("流式返回的数据---------$respData");

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

//   /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
//   // if (respData.runtimeType == String) {
//   //   respData = json.decode(respData);
//   // }

//   /// ??? 流式返回都是String，没有区分正常和报错返回
//   List<CommonRespBody> list = (respData as String)
//       .split("data:")
//       .where((e) => e.isNotEmpty)
//       .map((e) => CommonRespBody.fromJson(json.decode(e)))
//       .toList();

//   print("=======================ttttttttt\n$list");

//   // 响应是json格式
//   return list;
// }
