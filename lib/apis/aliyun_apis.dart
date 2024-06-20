// ignore_for_file: avoid_print

import 'dart:convert';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/ai_interface_state/aliyun_text2image_state.dart';
import '_self_keys.dart';

/// 阿里平台通用aigc的请求地址
var aliyunAigcUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation";

/// 2024-06-011 非流式的阿里返回content是空字符串？？？
/*
非流式就类似这样返回，明明output都有，但content是空的，原因不明，之前是ok的。
{
     output: {
         choices: [{finish_reason: stop, message: {role: assistant, content: }}]
    }
     usage: {total_tokens: 87, output_tokens: 82, input_tokens: 5},
     request_id: "4d9a188f-39ee-9c1b-839c-6ad961b211af"
}
*/
// 【暂未用到】
// Future<CommonRespBody> getAliyunAigcCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   model = model ?? llmModels[PlatformLLM.aliyunQwen1p8BChatFREE]!;

//   var body = CommonReqBody(
//     model: model,
//     input: AliyunInput(messages: messages),
//     parameters: AliyunParameters(resultFormat: "message"),
//   );

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: aliyunAigcUrl,
//     method: HttpMethod.post,
//     headers: {
//       // "X-DashScope-SSE": "enable", // 不开启 SSE 响应
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $ALIYUN_API_KEY",
//     },
//     // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
//     data: body,
//   );

//   print("===============$respData");

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

//   ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
//   if (respData.runtimeType == String) {
//     respData = json.decode(respData);
//   }

//   // 响应是json格式
//   return CommonRespBody.fromJson(respData ?? "{}");
// }

// /// 限量的查询，为了避免麻烦，模型参数【暂未用到】
// Future<CommonRespBody> getAliyunLimitedAigcCommonResp(
//   List<CommonMessage> messages,
//   String? model,
// ) async {
//   /// 2024-06-16 阿里云中限量的零一万物没有看到流式的入参数，也没有resultFormat等参数
//   /// 又因为 parameters 不可为空，这里传一个占位的
//   var body = CommonReqBody(
//     model: model,
//     input: AliyunInput(messages: messages),
//     parameters: AliyunParameters(topP: 0.7),
//   );

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: aliyunAigcUrl,
//     method: HttpMethod.post,
//     headers: {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $ALIYUN_API_KEY",
//     },
//     // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
//     data: body,
//   );

//   print("limited===============$respData");

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

//   ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
//   if (respData.runtimeType == String) {
//     respData = json.decode(respData);
//   }

//   // 响应是json格式
//   return CommonRespBody.fromJson(respData ?? {});
// }

// // 【暂未用到】
// Future<List<CommonRespBody>> getAliyunAigcStreamCommonResp(
//   List<CommonMessage> messages, {
//   String? model,
// }) async {
//   // 如果有传模型名称，就用传递的；没有就默认的
//   model = model ?? llmModels[PlatformLLM.aliyunQwen1p8BChatFREE]!;

//   var body = CommonReqBody(
//     model: model,
//     input: AliyunInput(messages: messages),
//     parameters: AliyunParameters(
//       resultFormat: "message",
//       incrementalOutput: true,
//     ),
//   );

//   var start = DateTime.now().millisecondsSinceEpoch;

//   var respData = await HttpUtils.post(
//     path: aliyunAigcUrl,
//     method: HttpMethod.post,
//     headers: {
//       "X-DashScope-SSE": "enable", // 开启SSE
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $ALIYUN_API_KEY",
//     },
//     // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
//     data: body,
//   );

//   print("aliyun的SSE-----------$respData");

//   // 使用正则表达式匹配所有以"data:{"开头的字符串
//   final regex = RegExp(r'.*data:\{".*}', multiLine: true);
//   final matches = regex.allMatches(respData);

//   print("===============matches $matches");

//   // 提取匹配到的字符串并添加到数组中
//   List<String> dataArray = [];
//   for (final match in matches) {
//     // 替换"data:"为空字符串(看结果data后面的冒号没有空格)
//     final replacedString = match.group(0)!.replaceAll(RegExp(r'data:'), '');
//     dataArray.add(replacedString);
//   }

//   List<CommonRespBody> list =
//       dataArray.map((e) => CommonRespBody.fromJson(json.decode(e))).toList();

//   // 输出提取到的数据，或者进行其他操作

//   print("===============$respData");

//   var end = DateTime.now().millisecondsSinceEpoch;

//   print("1111111111xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");
//   print(dataArray);
//   print(list);

//   // 响应是json格式
//   return list;
// }

///
/// 文生图任务提交 POST https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis
///
var aliyunText2imageUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis";

Future<AliyunTextToImgResp> commitAliyunText2ImgJob(
  Input input,
  Parameters parameters,
) async {
  // var body = AliyunTextToImgReq(
  //   model: "wanx-v1",
  //   input: Input(
  //     prompt: "一只奔跑的猫、猫娘",
  //     negativePrompt: "肥胖、加菲、老",
  //   ),
  //   parameters: Parameters(
  //     style: "<3d cartoon>",
  //     size: "1024*1024",
  //     n: 2,
  //     seed: 12345678,
  //     strength: 0.5,
  //   ),
  // );

  var body = AliyunTextToImgReq(
    model: "wanx-v1",
    input: input,
    parameters: parameters,
  );

  var start = DateTime.now().millisecondsSinceEpoch;

  var respData = await HttpUtils.post(
    path: aliyunText2imageUrl,
    method: HttpMethod.post,
    headers: {
      "X-DashScope-Async": "enable", // 固定的，异步方式提交作业。
      "Content-Type": "application/json",
      "Authorization": "Bearer $ALIYUN_API_KEY",
    },
    // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
    data: body,
  );

  print("阿里云文生图---------------------$respData");

  var end = DateTime.now().millisecondsSinceEpoch;

  print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

  ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
  if (respData.runtimeType == String) {
    respData = json.decode(respData);
  }

  // 响应是json格式
  return AliyunTextToImgResp.fromJson(respData ?? {});
}

///
/// 作业任务状态查询和结果获取接口
/// GET https://dashscope.aliyuncs.com/api/v1/tasks/{task_id}
///
Future<AliyunTextToImgResp> getAliyunText2ImgJobResult(String taskId) async {
  var start = DateTime.now().millisecondsSinceEpoch;

  // var taskId = "8bb11ab3-a7b2-4e37-b90f-f7d31d356279";

  var respData = await HttpUtils.post(
    path: "https://dashscope.aliyuncs.com/api/v1/tasks/$taskId",
    method: HttpMethod.get,
    headers: {
      "Authorization": "Bearer $ALIYUN_API_KEY",
    },
  );

  print("阿里云文生图结果查询---------------------$respData");

  var end = DateTime.now().millisecondsSinceEpoch;

  print("333333xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

  ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
  if (respData.runtimeType == String) {
    respData = json.decode(respData);
  }

  // 响应是json格式
  return AliyunTextToImgResp.fromJson(respData ?? "{}");
}
