// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../../dio_client/interceptor_error.dart';
import '../../models/chat_completion/paid_llm/common_chat_completion_state.dart';
import '../../models/llm_spec/cc_llm_spec_paid.dart';
import '../_self_keys.dart';
import 'common_cc_apis.dart';

///
/// 这里都是用自己的账号,要付费的
/// cc => ChatCompletions
///

/// 流式和同步通用
Future<StreamWithCancel<CCRespBody>> lingyiwanwuCCRespWithCancel(
  ApiPlatform platform,
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var body = CCReqBody(
    model: model,
    messages: messages,
    stream: stream,
  );

  var start = DateTime.now().millisecondsSinceEpoch;

  try {
    // 如果选择的平台不存在，抛错
    var spec = platformUrls.where((e) => e.platform == platform).toList();

    if (spec.isEmpty) {
      return throw Exception("未找到${platform.name}的配置");
    }

    // 存在，则拼接访问的地址
    var path = spec.first.url;

    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${cusAKMap[platform]!}",
    };

    var respData = await HttpUtils.post(
      path: path,
      method: HttpMethod.post,
      responseType: stream ? ResponseType.stream : ResponseType.json,
      headers: header,
      data: body,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    var end = DateTime.now().millisecondsSinceEpoch;
    print("CC 响应耗时: ${(end - start) / 1000} 秒");

    print("-------------在转换前--------$respData----------");

    if (stream) {
      // 处理流式响应
      if (respData is ResponseBody) {
        final streamController = StreamController<CCRespBody>();

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
              streamController.add(CCRespBody(customReplyText: '[DONE]'));
              streamController.close();
            }
          } else {
            final jsonData = json.decode(data.substring(5));
            final commonRespBody = CCRespBody.fromJson(jsonData);
            if (!streamController.isClosed) {
              streamController.add(commonRespBody);
            }
          }
        }, onDone: () {
          if (!streamController.isClosed) {
            streamController.add(CCRespBody(customReplyText: '[DONE]'));
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
            streamController.add(CCRespBody(customReplyText: '[手动终止]'));
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
        Stream.value(CCRespBody.fromJson(respData)),
        () async {},
      );
    }
  } on HttpException catch (e) {
    // 这里是拦截器抛出的http异常的处理
    print("零一万物 aaaaaaaaaaaaa ${e.runtimeType}---${e.msg}");
    return StreamWithCancel(
      Stream.value(CCRespBody(
        customReplyText: e.toString(),
        error: RespError(code: "10001", type: "http异常", message: e.toString()),
      )),
      () async {},
    );
  } catch (e) {
    rethrow;
  }
}

/// 为了省钱，都只用非流式的请求
Future<CCRespBody> getChatResp(
  ApiPlatform platform,
  List<CCMessage> messages, {
  String? model,
}) async {
  var body = CCReqBody(model: model, messages: messages);

  var start = DateTime.now().millisecondsSinceEpoch;

  try {
    // 如果选择的平台不存在，抛错
    var spec = platformUrls.where((e) => e.platform == platform).toList();

    if (spec.isEmpty) {
      return throw Exception("未找到${platform.name}的配置");
    }

    // 存在，则拼接访问的地址
    var path = spec.first.url;

    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${cusAKMap[platform]!}",
    };

    var respData = await HttpUtils.post(
      path: path,
      method: HttpMethod.post,
      headers: header,
      data: body,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    var end = DateTime.now().millisecondsSinceEpoch;
    print("CC 响应耗时: ${(end - start) / 1000} 秒");

    print("-------------在转换前--------$respData----------");
    return CCRespBody.fromJson(respData);
  } on HttpException catch (e) {
    // 这里是拦截器抛出的http异常的处理
    print("零一万物 aaaaaaaaaaaaa ${e.runtimeType}---${e.msg}");
    return CCRespBody(
      customReplyText: e.toString(),
      error: RespError(code: "10001", type: "http异常", message: e.toString()),
    );
  } catch (e) {
    // 这里是其他异常处理
    print("零一万物 bbbbbbbbbbbbbb ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    // return CCRespBody(
    //   customReplyText: e.toString(),
    //   // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
    //   error: RespError(code: "10000", type: "其他异常", message: e.toString()),
    // );
    rethrow;
  }
}
