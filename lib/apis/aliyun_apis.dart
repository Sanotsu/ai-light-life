// ignore_for_file: avoid_print

import 'dart:convert';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../dio_client/interceptor_error.dart';
import '../models/ai_interface_state/aliyun_qwenvl_state.dart';
import '../models/ai_interface_state/aliyun_text2image_state.dart';
import '../models/common_llm_info.dart';
import '../services/cus_get_storage.dart';
import '_self_keys.dart';

///
/// 文生图任务提交
///
var aliyunText2imageUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis";

Future<AliyunTextToImgResp> commitAliyunText2ImgJob(
  Input input,
  Parameters parameters,
) async {
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

///
/// 阿里的视觉大模型通义千问-VL 的请求
/// https://help.aliyun.com/document_detail/2712587.html
///

/// 阿里平台通用多模态视觉大模型的请求地址
var aliyunMultimodalUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation";

Future<List<AliyunQwenVlResp>> getAliyunQwenVLResp(
  List<QwenVLMessage> messages, {
  String? model,
  bool stream = false,
  bool isUserConfig = true,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? newLLMSpecs[PlatformLLM.limitedQwenVLPlus]!.model;

//  ?????
// 2024-06-21
// 明明和API文档一样了，为什么不行
// The item of `content` should be a message of a certain modal
  var body = AliyunQwenVlReq(
    model: model,
    input: QwenVLInput(messages: messages),
    parameters:
        stream ? QwenVLParameters(incrementalOutput: true) : QwenVLParameters(),
  );

  var start = DateTime.now().millisecondsSinceEpoch;

  var header = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer ${isUserConfig ? MyGetStorage().getCusAppKey() : ALIYUN_API_KEY}",
  };
  // 如果是流式，开启SSE
  if (stream) {
    header.addAll({"X-DashScope-SSE": "enable"});
  }

  print("""--------------------------------------
getAliyunQwenVLResp 的请求体，AliyunQwenVlResp：
${json.encode(body.toSimpleJson(stream))}
--------------------------------------
""");

  try {
    var respData = await HttpUtils.post(
      path: aliyunMultimodalUrl,
      method: HttpMethod.post,
      headers: header,
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: json.encode(body.toSimpleJson(stream)),
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("阿里云qwen-vl响应耗时: ${(end - start) / 1000} 秒");

    if (stream) {
      // 使用正则表达式匹配所有以"data:{"开头的字符串
      final regex = RegExp(r'.*data:\{".*}', multiLine: true);
      final matches = regex.allMatches(respData);

      // 提取匹配到的字符串并添加到数组中
      List<String> dataArray = [];
      for (final match in matches) {
        // 替换"data:"为空字符串(看结果data后面的冒号没有空格)
        final replacedString = match.group(0)!.replaceAll(RegExp(r'data:'), '');
        dataArray.add(replacedString);
      }

      List<AliyunQwenVlResp> list = dataArray
          .map((e) => AliyunQwenVlResp.fromJson(json.decode(e)))
          .toList();

      print(list);

      return list;
    } else {
      ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 响应是json格式
      return [AliyunQwenVlResp.fromJson(respData ?? {})];
    }
  } on HttpException catch (e) {
    return [
      AliyunQwenVlResp(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )
    ];
  } catch (e) {
    print("vvvvvvvvvvvvvvvvvvl ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return [
      AliyunQwenVlResp(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: "10000",
        errorMsg: e.toString(),
      )
    ];
  }
}

var a = {
  "model": "qwen-vl-plus",
  "input": {
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "text": "刚回家",
            "image":
                "https://dashscope.oss-cn-beijing.aliyuncs.com/images/dog_and_girl.jpeg"
          }
        ]
      }
    ]
  },
  "parameters": {}
};
