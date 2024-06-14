import 'dart:convert';

import 'platform_aigc_commom_state.dart';

///
/// 在百度云平台的图像理解模型Fuyu-8B 的请求响应
///

// 请求
class BaiduFuyu8BReq {
  // 请求信息，需要对图像进行发问的内容
  String prompt;
  // 图片base64数据
  String image;
  // 是否以流式接口的形式返回数据，默认false
  bool? stream;
  // 还有很多可选参数，和对话的接口是类似的，暂时不用了

  BaiduFuyu8BReq({
    required this.prompt,
    required this.image,
    this.stream = false,
  });

  factory BaiduFuyu8BReq.fromRawJson(String str) =>
      BaiduFuyu8BReq.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BaiduFuyu8BReq.fromJson(Map<String, dynamic> json) => BaiduFuyu8BReq(
        prompt: json["prompt"],
        image: json["image"],
        stream: json["stream"],
      );

  Map<String, dynamic> toJson() => {
        "prompt": prompt,
        "image": image,
        "stream": stream,
      };
}

// 响应
class BaiduFuyu8BResp {
  // 本轮对话的id
  String? id;
  // 回包类型。 completion：文本生成返回
  String? object;
  // 时间戳
  int? created;
  // 表示当前子句的序号。只有在流式接口模式下会返回该字段
  int? sentenceId;
  // 表示当前子句是否是最后一句。只有在流式接口模式下会返回该字段
  bool? isEnd;
  // 对话返回结果(非流式直接取值)
  String? result;
  // 说明：· 1：表示输入内容无安全风险· 0：表示输入内容有安全风险
  int? isSafe;
  // token统计信息(和对话中使用的是一样的结构)
  CommonUsage? usage;
  // 错误码
  String? errorCode;
  // 错误描述信息，帮助理解和解决发生的错误
  String? errorMsg;

  BaiduFuyu8BResp({
    this.id,
    this.object,
    this.created,
    this.sentenceId,
    this.isEnd,
    this.result,
    this.isSafe,
    this.usage,
    this.errorCode,
    this.errorMsg,
  });

  factory BaiduFuyu8BResp.fromRawJson(String str) =>
      BaiduFuyu8BResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BaiduFuyu8BResp.fromJson(Map<String, dynamic> json) =>
      BaiduFuyu8BResp(
        id: json["id"],
        object: json["object"],
        created: json["created"],
        sentenceId: json["sentence_id"],
        isEnd: json["is_end"],
        result: json["result"],
        isSafe: json["is_safe"],
        usage:
            json["usage"] == null ? null : CommonUsage.fromJson(json["usage"]),
        errorCode: json["error_code"],
        errorMsg: json["error_msg"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "created": created,
        "sentence_id": sentenceId,
        "is_end": isEnd,
        "result": result,
        "is_safe": isSafe,
        "usage": usage?.toJson(),
        "error_code": errorCode,
        "error_msg": errorMsg,
      };
}
