import 'dart:convert';

/// 阿里云中消息的结构
class AliyunMessage {
  String content;
  String role;

  AliyunMessage({
    required this.content,
    required this.role,
  });

  factory AliyunMessage.fromJson(Map<String, dynamic> json) => AliyunMessage(
        content: json["content"],
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "content": content,
        "role": role,
      };
}

/*
请求的最小参数
{
    "model": "farui-plus",
    "input": {
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant."
            },
            {
                "role": "user",
                "content": "我哥欠我10000块钱，给我生成起诉书。"
            }
        ]
    },
    "parameters": {
        "seed": 65535,
        "result_format": "message"
    }
}*/

// To parse this JSON data, do
//
//     final aliyunBailianRequesBody = aliyunBailianRequesBodyFromJson(jsonString);

AliyunBailianRequesBody aliyunBailianRequesBodyFromJson(String str) =>
    AliyunBailianRequesBody.fromJson(json.decode(str));

String aliyunBailianRequesBodyToJson(AliyunBailianRequesBody data) =>
    json.encode(data.toJson());

class AliyunBailianRequesBody {
  String model;
  Input input;
  Parameters? parameters;

  AliyunBailianRequesBody({
    required this.model,
    required this.input,
    this.parameters,
  });

  factory AliyunBailianRequesBody.fromJson(Map<String, dynamic> json) =>
      AliyunBailianRequesBody(
        model: json["model"],
        input: Input.fromJson(json["input"]),
        parameters: json["parameters"] == null
            ? null
            : Parameters.fromJson(json["parameters"]),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "input": input.toJson(),
        "parameters": parameters?.toJson(),
      };
}

class Input {
  List<AliyunMessage>? messages;

  Input({
    this.messages,
  });

  factory Input.fromJson(Map<String, dynamic> json) => Input(
        messages: json["messages"] == null
            ? []
            : List<AliyunMessage>.from(
                json["messages"]!.map((x) => AliyunMessage.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "messages": messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
      };
}

class Parameters {
  int? seed;
  String? resultFormat;

  Parameters({
    this.seed,
    this.resultFormat,
  });

  factory Parameters.fromJson(Map<String, dynamic> json) => Parameters(
        seed: json["seed"],
        resultFormat: json["result_format"],
      );

  Map<String, dynamic> toJson() => {
        "seed": seed,
        "result_format": resultFormat,
      };
}

/*
阿里云百炼文本对话最小的响应
{
  "output": {
    "choices": [
      {
        "message": {
          "content": "你好，有什么我可以帮助你的吗？",
          "role": "assistant"
        },
        "index": 0,
        "finish_reason": "stop"
      }
    ]
  },
  "usage": { "total_tokens": 12, "input_tokens": 3, "output_tokens": 9 },
  "request_id": "8673e696-ee22-9ed0-9c35-b8673d4b87bc"
}
*/

// To parse this JSON data, do
//
//     final aliyunBailianResponseBody = aliyunBailianResponseBodyFromJson(jsonString);

AliyunBailianResponseBody aliyunBailianResponseBodyFromJson(String str) =>
    AliyunBailianResponseBody.fromJson(json.decode(str));

String aliyunBailianResponseBodyToJson(AliyunBailianResponseBody data) =>
    json.encode(data.toJson());

class AliyunBailianResponseBody {
  Output output;
  Usage usage;
  String requestId;
  int? statusCode; // 响应的状态
  String? code; // 错误代码
  String? message; // 错误信息

  AliyunBailianResponseBody({
    required this.output,
    required this.usage,
    required this.requestId,
    this.statusCode,
    this.code,
    this.message,
  });

  factory AliyunBailianResponseBody.fromJson(Map<String, dynamic> json) =>
      AliyunBailianResponseBody(
        output: Output.fromJson(json["output"]),
        usage: Usage.fromJson(json["usage"]),
        requestId: json["request_id"],
        statusCode: json["status_code"],
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "output": output.toJson(),
        "usage": usage.toJson(),
        "request_id": requestId,
        "status_code": statusCode,
        "code": code,
        "message": message,
      };
}

class Output {
  // 入参result_format=text时候的返回值
  String? text;
  String? finishReason;
  // 入参result_format=message时候的返回值
  List<Choice>? choices;

  Output({
    this.text,
    this.finishReason,
    this.choices,
  });

  factory Output.fromJson(Map<String, dynamic> json) => Output(
        text: json["text"],
        finishReason: json["finish_reason"],
        choices: json["choices"] == null
            ? []
            : List<Choice>.from(
                json["choices"]!.map((x) => Choice.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "finish_reason": finishReason,
        "choices": choices == null
            ? []
            : List<dynamic>.from(choices!.map((x) => x.toJson())),
      };
}

class Choice {
  AliyunMessage message;
  String finishReason;
  int? index;

  Choice({
    required this.message,
    required this.finishReason,
    this.index,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
        message: AliyunMessage.fromJson(json["message"]),
        index: json["index"],
        finishReason: json["finish_reason"],
      );

  Map<String, dynamic> toJson() => {
        "message": message.toJson(),
        "index": index,
        "finish_reason": finishReason,
      };
}

class Usage {
  int totalTokens;
  int inputTokens;
  int outputTokens;

  Usage({
    required this.totalTokens,
    required this.inputTokens,
    required this.outputTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => Usage(
        totalTokens: json["total_tokens"],
        inputTokens: json["input_tokens"],
        outputTokens: json["output_tokens"],
      );

  Map<String, dynamic> toJson() => {
        "total_tokens": totalTokens,
        "input_tokens": inputTokens,
        "output_tokens": outputTokens,
      };
}
