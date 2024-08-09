// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:logger/logger.dart';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../dio_client/interceptor_error.dart';
import '../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../models/llm_spec/cc_llm_spec_free.dart';

import '../services/cus_get_storage.dart';
import '_self_keys.dart';
import 'gen_access_token/tencet_hunyuan_signature_v3.dart';

/// 腾讯平台大模型API的前缀地址
const tencentAigcUrl = "https://hunyuan.tencentcloudapi.com/";

///
///-----------------------------------------------------------------------------
/// 腾讯的请求方法
///
/// 获取流式和非流式的对话响应数据
Future<List<CommonRespBody>> getTencentAigcResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  bool isUserConfig = true,
}) async {
  print("-isUserConfig-----------------$isUserConfig");
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.tencent_Hunyuan_Lite]!.model;

  var body = CommonReqBody(model: model, messages: messages, stream: stream);

  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: tencentAigcUrl,
      method: HttpMethod.post,
      headers: genHunyuanLiteSignatureHeaders(
        commonReqBodyToJson(body, caseType: "pascal"),
        // 如果是用户自行配置，使用用户通用配置；否则是自己的账号key
        isUserConfig
            ? MyGetStorage().getTencentCommonAppId() ?? ""
            : TENCENT_SECRET_ID,
        isUserConfig
            ? MyGetStorage().getTencentCommonAppKey() ?? ""
            : TENCENT_SECRET_KEY,
      ),
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: body.toJson(caseType: "pascal"),
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("腾讯aigc响应耗时: ${(end - start) / 1000} 秒");

    /// ??? 流式返回都是String，没有区分正常和报错返回
    if (stream) {
      List<CommonRespBody> list = (respData as String)
          .split("data:")
          .where((e) => e.isNotEmpty)
          .map((e) => CommonRespBody.fromJson(json.decode(e)))
          .toList();
      return list;
    } else {
      /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 响应是json格式
      return [CommonRespBody.fromJson(respData["Response"])];
    }
  } on HttpException catch (e) {
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )
    ];
  } catch (e) {
    print("ttttttttttttttttttttt ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: "10000",
        errorMsg: e.toString(),
      )
    ];
  }
}

/// 阿里平台通用aigc的请求地址
var aliyunAigcUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation";

// ？？？2024-07-17 注意：这里不是所有的模型都支持配置resultFormat，限量的那些不行，但还没去处理
Future<List<CommonRespBody>> getAliyunAigcResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  bool isUserConfig = true,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.aliyun_Qwen_1p8B_Chat]!.model;

  var body = CommonReqBody(
    model: model,
    input: AliyunInput(messages: messages),
    parameters: stream
        ? AliyunParameters(resultFormat: "message", incrementalOutput: true)
        : AliyunParameters(resultFormat: "message"),
  );

  var start = DateTime.now().millisecondsSinceEpoch;

  var header = {
    "Content-Type": "application/json",
    // 如果是用户自行配置，使用检查用户通用配置；否则是自己的账号key
    "Authorization":
        "Bearer ${isUserConfig ? MyGetStorage().getAliyunCommonAppKey() : ALIYUN_API_KEY}",
  };
  // 如果是流式，开启SSE
  if (stream) {
    header.addAll({"X-DashScope-SSE": "enable"});
  }

  try {
    var respData = await HttpUtils.post(
      path: aliyunAigcUrl,
      method: HttpMethod.post,
      headers: header,
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: body,
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("阿里云aigc响应耗时: ${(end - start) / 1000} 秒");

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

      List<CommonRespBody> list = dataArray
          .map((e) => CommonRespBody.fromJson(json.decode(e)))
          .toList();

      print(list);

      return list;
    } else {
      ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 响应是json格式
      return [CommonRespBody.fromJson(respData ?? {})];
    }
  } on HttpException catch (e) {
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )
    ];
  } catch (e) {
    print("aaaaaaaaaaaaaaaaaaaa ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: "10000",
        errorMsg: e.toString(),
      )
    ];
  }
}

/// 百度平台大模型API的前缀地址
const baiduAigcUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";
// 百度的token请求地址
const baiduAigcAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

///
///-----------------------------------------------------------------------------
/// 百度的请求方法
///
/// 使用 AK，SK 生成鉴权签名（Access Token）
Future<String> getAccessToken({
  bool isUserConfig = true,
}) async {
  try {
    // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了
    var respData = await HttpUtils.post(
      path: baiduAigcAuthUrl,
      method: HttpMethod.post,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      data: {
        "grant_type": "client_credentials",
        // 如果是用户自行配置，使用检查用户通用配置；否则是自己的账号key
        "client_id":
            isUserConfig ? MyGetStorage().getBaiduCommonAppId() : BAIDU_API_KEY,
        "client_secret": isUserConfig
            ? MyGetStorage().getBaiduCommonAppKey()
            : BAIDU_SECRET_KEY,
      },
    );

    // 响应是json格式
    return respData['access_token'];
  } on HttpException catch (e) {
    return e.msg;
  } catch (e) {
    // API请求报错，显示报错信息
    return e.toString();
  }
}

/// 获取流式响应数据
Future<List<CommonRespBody>> getBaiduAigcResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  bool isUserConfig = true,
  String? system,
}) async {
  // 如果有传模型名称，就用传递的；没有就默认的
  // 百度免费的ernie-speed和ernie-lite 接口使用上是一致的，就是模型名称不一样
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.baidu_Ernie_Speed_128K]!.model;

  // 每次请求都要实时获取最小的token
  String token = await getAccessToken(isUserConfig: isUserConfig);

  var body = system != null
      ? CommonReqBody(messages: messages, stream: stream, system: system)
      : CommonReqBody(messages: messages, stream: stream);

  var start = DateTime.now().millisecondsSinceEpoch;

  try {
    var respData = await HttpUtils.post(
      path: "$baiduAigcUrl$model?access_token=$token",
      method: HttpMethod.post,
      headers: {"Content-Type": "application/json"},
      data: body,
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("百度 aigc 响应耗时: ${(end - start) / 1000} 秒");

    if (stream) {
      List<CommonRespBody> list = (respData as String)
          .split("data:")
          .where((e) => e.isNotEmpty)
          .map((e) => CommonRespBody.fromJson(json.decode(e)))
          .toList();

      print("=======================bbbbbbbbbbbbb\n$list");

      // 响应是json格式
      return list;
    } else {
      return [CommonRespBody.fromJson(respData)];
    }
  } on HttpException catch (e) {
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )
    ];
  } catch (e) {
    print("bbbbbbbbbbbbbbbb ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: "10000",
        errorMsg: e.toString(),
      )
    ];
  }
}

///
///-----------------------------------------------------------------------------
/// siliconFlow 的请求方法
///

String siliconflowAigcUrl = "https://api.siliconflow.cn/v1/chat/completions";

var lr = Logger();

/// 获取流式和非流式的对话响应数据
Future<List<CommonRespBody>> getSiliconFlowAigcResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  bool isUserConfig = true,
}) async {
  print("-isUserConfig-----------------$isUserConfig");
  // 如果有传模型名称，就用传递的；没有就默认的
  model = model ??
      Free_CC_LLM_SPEC_MAP[FreeCCLLM.siliconCloud_Qwen2_7B_Instruct]!.model;

  var body = CommonReqBody(model: model, messages: messages, stream: stream);

  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: siliconflowAigcUrl,
      method: HttpMethod.post,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $siliconCloudAk",
      },
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: body.toJson(),
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("siliconCloud aigc响应耗时: ${(end - start) / 1000} 秒");
    print("硅动科技返回的结果：${respData.runtimeType} $respData");

    // lr.e(respData);

    /// ??? 流式返回都是String，没有区分正常和报错返回
    if (stream) {
      // 注意：硅动科技流式返回的数据中，除了`data:`开始之外，最后一条时`data: [DONE]`结尾
      List<CommonRespBody> list = (respData as String)
          .split("data:")
          .where((e) => e.isNotEmpty && !e.contains("[DONE]"))
          .map((e) => CommonRespBody.fromJson(json.decode(e)))
          .toList();

      return list;
    } else {
      /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 响应是json格式
      return [CommonRespBody.fromJson(respData)];
    }
  } on HttpException catch (e) {
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )
    ];
  } catch (e) {
    print("gggggggggggggggggggggggggg ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return [
      CommonRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        errorCode: "10000",
        errorMsg: e.toString(),
      )
    ];
  }
}

var data = {
  "id": "0190de5df42fb805695fcd64480ec339",
  "object": "chat.completion.chunk",
  "created": 1721717617,
  "model": "Qwen/Qwen2-7B-Instruct",
  "choices": [
    {
      "index": 0,
      "delta": {"role": "assistant"},
      "finish_reason": null,
      "content_filter_results": {
        "hate": {"filtered": false},
        "self_harm": {"filtered": false},
        "sexual": {"filtered": false},
        "violence": {"filtered": false}
      }
    }
  ],
  "system_fingerprint": "",
  "usage": {"prompt_tokens": 24, "completion_tokens": 0, "total_tokens": 24}
};

var data2 = {
  "id": "0190de5df42fb805695fcd64480ec339",
  "object": "chat.completion.chunk",
  "created": 1721717617,
  "model": "Qwen/Qwen2-7B-Instruct",
  "choices": [
    {
      "index": 0,
      "delta": {"content": "你好"},
      "finish_reason": null,
      "content_filter_results": {
        "hate": {"filtered": false},
        "self_harm": {"filtered": false},
        "sexual": {"filtered": false},
        "violence": {"filtered": false}
      }
    }
  ],
  "system_fingerprint": "",
  "usage": {"prompt_tokens": 24, "completion_tokens": 1, "total_tokens": 25}
};
