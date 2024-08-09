// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../../dio_client/interceptor_error.dart';
import '../../models/ai_interface_state/platform_aigc_commom_state.dart';
import '../../models/llm_spec/cc_llm_spec_free.dart';
import '../_self_keys.dart';
import '../gen_access_token/tencet_hunyuan_signature_v3.dart';

enum PlatUrl {
  tencentCCUrl,
  aliyunCCUrl,
  baiduCCUrl,
  baiduCCAuthUrl,
  siliconFlowCCUrl,
}

const Map<PlatUrl, String> platUrls = {
  PlatUrl.tencentCCUrl: "https://hunyuan.tencentcloudapi.com/",
  PlatUrl.aliyunCCUrl:
      "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
  PlatUrl.baiduCCUrl:
      "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/",
  PlatUrl.baiduCCAuthUrl: "https://aip.baidubce.com/oauth/2.0/token",
  PlatUrl.siliconFlowCCUrl: "https://api.siliconflow.cn/v1/chat/completions",
};

/// 获取流式和非流式的对话响应数据
Future<Stream<CommonRespBody>> getCCResponse(
  String url,
  Map<String, dynamic> headers,
  Map<String, dynamic> data, {
  bool stream = false,
}) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: url,
      method: HttpMethod.post,
      responseType: stream ? ResponseType.stream : ResponseType.json,
      headers: headers,
      data: data,
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("aigc响应耗时: ${(end - start) / 1000} 秒");

    if (stream) {
      // 处理流式响应
      if (respData is ResponseBody) {
        final streamController = StreamController<CommonRespBody>();

        var subscription = respData.stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              final decodedData = utf8.decoder.convert(data);
              final lines = decodedData.split('\n');
              for (var line in lines) {
                if (line.startsWith('data:')) {
                  sink.add(line);
                }
              }
            },
          ),
        ).listen(
          (data) {
            if ((data as String).contains('[DONE]')) {
              if (!streamController.isClosed) {
                streamController.add(CommonRespBody(customReplyText: '[DONE]'));
                streamController.close();
              }
            } else {
              final jsonData = json.decode(data.substring(5));
              final commonRespBody = CommonRespBody.fromJson(jsonData);
              if (!streamController.isClosed) {
                streamController.add(commonRespBody);
              }
            }
          },
          onDone: () {
            if (!streamController.isClosed) {
              streamController.add(CommonRespBody(customReplyText: '[DONE]'));
              streamController.close();
            }
          },
          onError: (error) {
            if (!streamController.isClosed) {
              streamController.addError(error);
              streamController.close();
            }
          },
        );

        // 添加 onCancel 回调
        streamController.onCancel = () {
          subscription.cancel();
        };

        return streamController.stream;
      } else {
        throw HttpException(code: 500, msg: '不符合预期的数据流响应类型');
      }
    } else {
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }
      return Stream.value(CommonRespBody.fromJson(respData));
    }
  } on HttpException catch (e) {
    return Stream.value(CommonRespBody(
      customReplyText: e.toString(),
      errorCode: e.code.toString(),
      errorMsg: e.msg,
    ));
  } catch (e) {
    rethrow;
  }
}

/// 腾讯的请求方法
Future<Stream<CommonRespBody>> tencentCCResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.tencent_Hunyuan_Lite]!.model;
  var body = CommonReqBody(model: model, messages: messages, stream: stream);
  var headers = genHunyuanLiteSignatureHeaders(
    commonReqBodyToJson(body, caseType: "pascal"),
    TENCENT_SECRET_ID,
    TENCENT_SECRET_KEY,
  );
  return getCCResponse(
    platUrls[PlatUrl.tencentCCUrl]!,
    headers,
    body.toJson(caseType: "pascal"),
    stream: stream,
  );
}

/// 阿里的请求方法
Future<Stream<CommonRespBody>> aliyunCCResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.aliyun_Qwen_1p8B_Chat]!.model;
  var body = CommonReqBody(
    model: model,
    input: AliyunInput(messages: messages),
    parameters: stream
        ? AliyunParameters(resultFormat: "message", incrementalOutput: true)
        : AliyunParameters(resultFormat: "message"),
  );
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $ALIYUN_API_KEY",
  };
  if (stream) {
    headers.addAll({"X-DashScope-SSE": "enable"});
  }
  return getCCResponse(
    platUrls[PlatUrl.aliyunCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// 百度的请求方法
Future<String> getAccessToken() async {
  try {
    var respData = await HttpUtils.post(
      path: platUrls[PlatUrl.baiduCCAuthUrl]!,
      method: HttpMethod.post,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      data: {
        "grant_type": "client_credentials",
        "client_id": BAIDU_API_KEY,
        "client_secret": BAIDU_SECRET_KEY,
      },
    );
    return respData['access_token'];
  } on HttpException catch (e) {
    return e.msg;
  } catch (e) {
    return e.toString();
  }
}

Future<Stream<CommonRespBody>> baiduCCResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  String? system,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.baidu_Ernie_Speed_128K]!.model;
  String token = await getAccessToken();
  var body = system != null
      ? CommonReqBody(messages: messages, stream: stream, system: system)
      : CommonReqBody(messages: messages, stream: stream);
  var headers = {"Content-Type": "application/json"};
  return getCCResponse(
    "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// siliconFlow 的请求方法
Future<Stream<CommonRespBody>> siliconFlowCCResp(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ??
      Free_CC_LLM_SPEC_MAP[FreeCCLLM.siliconCloud_Qwen2_7B_Instruct]!.model;
  var body = CommonReqBody(model: model, messages: messages, stream: stream);
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $siliconCloudAk",
  };
  return getCCResponse(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}

///
///
///===========可以取消流的写法
///
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);
}

/// 获取流式和非流式的对话响应数据
Future<StreamWithCancel<CommonRespBody>> getAigcResponse(
  String url,
  Map<String, dynamic> headers,
  Map<String, dynamic> data, {
  bool stream = false,
}) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: url,
      method: HttpMethod.post,
      responseType: stream ? ResponseType.stream : ResponseType.json,
      headers: headers,
      data: data,
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("aigc响应耗时: ${(end - start) / 1000} 秒");

    if (stream) {
      // 处理流式响应
      if (respData is ResponseBody) {
        final streamController = StreamController<CommonRespBody>();

        final subscription = respData.stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              final decodedData = utf8.decoder.convert(data);
              final lines = decodedData.split('\n');
              for (var line in lines) {
                if (line.startsWith('data: ')) {
                  sink.add(line);
                }
              }
            },
          ),
        ).listen((data) {
          if ((data as String).contains('[DONE]')) {
            if (!streamController.isClosed) {
              streamController.add(CommonRespBody(customReplyText: '[DONE]'));
              streamController.close();
            }
          } else {
            final jsonData = json.decode(data.substring(5));
            final commonRespBody = CommonRespBody.fromJson(jsonData);
            if (!streamController.isClosed) {
              streamController.add(commonRespBody);
            }
          }
        }, onDone: () {
          if (!streamController.isClosed) {
            streamController.add(CommonRespBody(customReplyText: '[DONE]'));
            streamController.close();
          }
        }, onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        });

        Future<void> cancel() async {
          print("执行了取消-----");
          // ？？？占位用的，先发送最后一个手动终止的信息，再实际取消(手动的更没有token信息了)
          if (!streamController.isClosed) {
            streamController.add(CommonRespBody(customReplyText: '[手动终止]'));
          }
          await subscription.cancel();
          if (!streamController.isClosed) {
            streamController.close();
          }
        }

        return StreamWithCancel(streamController.stream, cancel);
      } else {
        throw HttpException(code: 500, msg: '不符合预期的数据流响应类型');
      }
    } else {
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }
      return StreamWithCancel(
        Stream.value(CommonRespBody.fromJson(respData)),
        () async {},
      );
    }
  } on HttpException catch (e) {
    return StreamWithCancel(
      Stream.value(CommonRespBody(
        customReplyText: e.toString(),
        errorCode: e.code.toString(),
        errorMsg: e.msg,
      )),
      () async {},
    );
  } catch (e) {
    rethrow;
  }
}

/// 腾讯的请求方法
Future<StreamWithCancel<CommonRespBody>> tencentCCRespWitchCancel(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.tencent_Hunyuan_Lite]!.model;
  var body = CommonReqBody(model: model, messages: messages, stream: stream);
  var headers = genHunyuanLiteSignatureHeaders(
    commonReqBodyToJson(body, caseType: "pascal"),
    TENCENT_SECRET_ID,
    TENCENT_SECRET_KEY,
  );
  return getAigcResponse(
    platUrls[PlatUrl.tencentCCUrl]!,
    headers,
    body.toJson(caseType: "pascal"),
    stream: stream,
  );
}

/// 阿里的请求方法
Future<StreamWithCancel<CommonRespBody>> aliyunCCRespWithCancel(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.aliyun_Qwen_1p8B_Chat]!.model;
  var body = CommonReqBody(
    model: model,
    input: AliyunInput(messages: messages),
    parameters: stream
        ? AliyunParameters(resultFormat: "message", incrementalOutput: true)
        : AliyunParameters(resultFormat: "message"),
  );
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $ALIYUN_API_KEY",
  };
  if (stream) {
    headers.addAll({"X-DashScope-SSE": "enable"});
  }
  return getAigcResponse(
    platUrls[PlatUrl.aliyunCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}

Future<StreamWithCancel<CommonRespBody>> baiduCCRespWithCancel(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
  String? system,
}) async {
  model = model ?? Free_CC_LLM_SPEC_MAP[FreeCCLLM.baidu_Ernie_Speed_128K]!.model;
  String token = await getAccessToken();
  var body = system != null
      ? CommonReqBody(messages: messages, stream: stream, system: system)
      : CommonReqBody(messages: messages, stream: stream);
  var headers = {"Content-Type": "application/json"};
  return getAigcResponse(
    "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// siliconFlow 的请求方法
Future<StreamWithCancel<CommonRespBody>> siliconFlowCCRespWithCancel(
  List<CommonMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ??
      Free_CC_LLM_SPEC_MAP[FreeCCLLM.siliconCloud_Qwen2_7B_Instruct]!.model;
  var body = CommonReqBody(model: model, messages: messages, stream: stream);
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $siliconCloudAk",
  };
  return getAigcResponse(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}
