// ignore_for_file: avoid_print

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../models/ai_interface_state/baidu_fuyu8b_state.dart';
import '_self_keys.dart';

/// 百度平台大模型API的前缀地址
const baiduAigcUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";
// 百度的token请求地址
const baiduAigcAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

// 百度平台下第三方的fuyu图像理解模型API接口
const baiduFuyu8BUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/image2text/fuyu_8b";

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

// /// 获取百度对话请求的响应数据
// Future<CommonRespBody> getBaiduAigcCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
//   model = model ?? llmModels[PlatformLLM.baiduErnieSpeed8KFREE]!;

//   // 每次请求都要实时获取最小的token
//   String token = await getAccessToken();

//   var body = CommonReqBody(messages: messages);

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: "$baiduAigcUrl$model?access_token=$token",
//     method: HttpMethod.post,
//     headers: {"Content-Type": "application/json"},
//     data: body,
//   );

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("1111111111xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

//   // 响应是json格式
//   return CommonRespBody.fromJson(respData);
// }

// /// 获取流式响应数据
// Future<List<CommonRespBody>> getBaiduAigcStreamCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
//   model = model ?? llmModels[PlatformLLM.baiduErnieSpeed128KFREE]!;

//   // 每次请求都要实时获取最小的token
//   String token = await getAccessToken();

//   var body = CommonReqBody(messages: messages, stream: true);

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: "$baiduAigcUrl$model?access_token=$token",
//     method: HttpMethod.post,
//     headers: {"Content-Type": "application/json"},
//     data: body,
//   );

//   print("流失返回的数据---------$respData");

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

//   // 这里返回的是String，不是Map<String, dynamic>

//   // 注意要手动处理拼接字符串
//   // List<String> list =
//   //     (respData as String).split("data:").where((e) => e.isNotEmpty).toList();

//   // List jsonList =
//   //     list.map((e) => CommonRespBody.fromJson(json.decode(e))).toList();

//   List<CommonRespBody> list = (respData as String)
//       .split("data:")
//       .where((e) => e.isNotEmpty)
//       .map((e) => CommonRespBody.fromJson(json.decode(e)))
//       .toList();

//   print("=======================bbbbbbbbbbbbb\n$list");

//   // 响应是json格式
//   return list;
// }

/// 获取Fuyu-8B图像理解的响应结果
Future<BaiduFuyu8BResp> getBaiduFuyu8BResp(String prompt, String image) async {
  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  var body = BaiduFuyu8BReq(prompt: prompt, image: image);

  var start = DateTime.now().millisecondsSinceEpoch;

  var respData = await HttpUtils.post(
    path: "$baiduFuyu8BUrl?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  var end = DateTime.now().millisecondsSinceEpoch;

  print("百度图生文-------耗时${(end - start) / 1000} 秒");
  print("百度图生文-------$respData");

  // 响应是json格式
  return BaiduFuyu8BResp.fromJson(respData);
}
