// To parse this JSON data, do
//
//     final aliyunQwenVlReq = aliyunQwenVlReqFromJson(jsonString);

import 'dart:convert';

/// =================================================
/// 千问VL的请求和响应可以通用的部分
/// =================================================
class QwenVLMessage {
  String role;
  List<QwenVLContent> content;

  QwenVLMessage({required this.role, required this.content});

  factory QwenVLMessage.fromJson(Map<String, dynamic> json) => QwenVLMessage(
        role: json["role"],
        content: List<QwenVLContent>.from(
          json["content"]!.map((x) => QwenVLContent.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": List<dynamic>.from(content.map((x) => x.toJson())),
      };
}

// 千问vm的输入和输出都可以用这个，区别在于响应不带image，请求可以有image去做视觉理解
class QwenVLContent {
  String? text;
  String? image;

  QwenVLContent({this.text, this.image});

  factory QwenVLContent.fromJson(Map<String, dynamic> json) => QwenVLContent(
        text: json["text"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "image": image,
      };
}

/// =================================================
/// 千问VL的请求体
/// =================================================
AliyunQwenVlReq aliyunQwenVlReqFromJson(String str) =>
    AliyunQwenVlReq.fromJson(json.decode(str));

String aliyunQwenVlReqToJson(AliyunQwenVlReq data) =>
    json.encode(data.toJson());

class AliyunQwenVlReq {
  String model;
  QwenVLInput input;
  QwenVLParameters? parameters;

  AliyunQwenVlReq({
    required this.model,
    required this.input,
    this.parameters,
  });

  factory AliyunQwenVlReq.fromJson(Map<String, dynamic> json) =>
      AliyunQwenVlReq(
        model: json["model"],
        input: QwenVLInput.fromJson(json["input"]),
        parameters: json["parameters"] == null
            ? null
            : QwenVLParameters.fromJson(json["parameters"]),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "input": input.toJson(),
        "parameters": parameters?.toJson(),
      };

  Map<String, dynamic> toSimpleJson(isStream) => {
        "model": model,
        "input": input.toJson(),
        "parameters": parameters?.toSimpleJson(isStream),
      };
}

class QwenVLInput {
  List<QwenVLMessage> messages;

  QwenVLInput({required this.messages});

  factory QwenVLInput.fromJson(Map<String, dynamic> json) => QwenVLInput(
        messages: List<QwenVLMessage>.from(
            json["messages"]!.map((x) => QwenVLMessage.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
      };
}

class QwenVLParameters {
  // 2024-06-15 阿里云的请求这个parameters不能为null，但上面的在零一万物等模型中不存在，
  // 所以这里一个对话模型可能都有的参数
  // 控制生成结果的随机性。数值越小，随机性越弱；数值越大，随机性越强。
  //    取值范围： [.0f, 1.0f]。 多样性，越高，多样性越好, 缺省 0.3。
  double? topP;
  // 生成时，采样候选集的大小。
  //  取值越大，生成的随机性越高；取值越小，生成的确定性越高。注意：如果top_k的值大于100，top_k将采用默认值100
  double? topK;
  int? seed;
  // 流式响应时，是否增量输出
  // 默认为false，即后面的内容会包含已经输出的内容，不用手动叠加
  bool? incrementalOutput;

  QwenVLParameters({
    this.topP,
    this.topK,
    this.seed,
    this.incrementalOutput,
  });

  factory QwenVLParameters.fromJson(Map<String, dynamic> json) =>
      QwenVLParameters(
        topP: json["top_p"],
        topK: json["top_K"],
        seed: json["seed"],
        incrementalOutput: json["incremental_output"],
      );

  Map<String, dynamic> toJson() => {
        "top_p": topP,
        "top_K": topK,
        "seed": seed,
        "incremental_output": incrementalOutput,
      };

  Map<String, dynamic> toSimpleJson(bool sse) =>
      sse ? {"incremental_output": incrementalOutput} : {};
}

/// =================================================
/// 千问VL的响应体
///   和通用的CommonRespBody 更少的参数，output的内容也不一样(主要是message的结构)
/// =================================================
AliyunQwenVlResp aliyunQwenVlRespFromJson(String str) =>
    AliyunQwenVlResp.fromJson(json.decode(str));

String aliyunQwenVlRespToJson(AliyunQwenVlResp data) =>
    json.encode(data.toJson());

class AliyunQwenVlResp {
  QwenVLOutput? output;
  QwenVLUsage? usage;
  String? requestId;

  // 自己处理后直接拿的输出结果
  String customReplyText;

  // 错误码和错误消息
  String? errorCode;
  String? errorMsg;

  AliyunQwenVlResp({
    this.output,
    this.usage,
    this.requestId,
    required this.customReplyText,
    this.errorCode,
    this.errorMsg,
  });

  factory AliyunQwenVlResp.fromJson(Map<String, dynamic> json) {
    var customReplyText = "";

    // 流式的时候结构不一样？content从list变为string了？？？
    if (json["output"] != null) {
      // 2024-06-15 阿里的也有2种类型:一是一般text的格式,另一种是message的格式,理论上2者不会同时存在
      var temp = QwenVLOutput.fromJson(json["output"]);

      if (temp.choices.isNotEmpty) {
        var a = temp.choices.first.message.content;

        for (var e in a) {
          customReplyText += e.text ?? "";
        }
      }
    }

    return AliyunQwenVlResp(
      output:
          json["output"] == null ? null : QwenVLOutput.fromJson(json["output"]),
      usage: json["usage"] == null ? null : QwenVLUsage.fromJson(json["usage"]),
      requestId: json["request_id"],
      errorCode: json["code"],
      errorMsg: json["message"],
      customReplyText: customReplyText,
    );
  }

  Map<String, dynamic> toJson() => {
        "output": output?.toJson(),
        "usage": usage?.toJson(),
        "request_id": requestId,
        "code": errorCode,
        "message": errorMsg,
        "custom_reply_text": customReplyText,
      };
}

class QwenVLOutput {
  List<QwenVLChoice> choices;

  QwenVLOutput({
    required this.choices,
  });

  factory QwenVLOutput.fromJson(Map<String, dynamic> json) => QwenVLOutput(
        choices: List<QwenVLChoice>.from(
          json["choices"]!.map((x) => QwenVLChoice.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        "choices": List<dynamic>.from(choices.map((x) => x.toJson())),
      };
}

class QwenVLChoice {
  String? finishReason;
  QwenVLMessage message;

  QwenVLChoice({
    this.finishReason,
    required this.message,
  });

  factory QwenVLChoice.fromJson(Map<String, dynamic> json) => QwenVLChoice(
        finishReason: json["finish_reason"],
        message: QwenVLMessage.fromJson(json["message"]),
      );

  Map<String, dynamic> toJson() => {
        "finish_reason": finishReason,
        "message": message.toJson(),
      };
}

// 和通用的优点区别：token没有total，多一个image
class QwenVLUsage {
  int? outputTokens;
  int? inputTokens;
  int? imageTokens;

  QwenVLUsage({
    this.outputTokens,
    this.inputTokens,
    this.imageTokens,
  });

  factory QwenVLUsage.fromJson(Map<String, dynamic> json) => QwenVLUsage(
        outputTokens: json["output_tokens"],
        inputTokens: json["input_tokens"],
        imageTokens: json["image_tokens"],
      );

  Map<String, dynamic> toJson() => {
        "output_tokens": outputTokens,
        "input_tokens": inputTokens,
        "image_tokens": imageTokens,
      };
}
