import 'dart:convert';

/// 百度ernie大模型的请求参数
// To parse this JSON data, do
//     final baiduErnieRequestBody = baiduErnieRequestBodyFromJson(jsonString);

BaiduErnieRequestBody baiduErnieRequestBodyFromJson(String str) =>
    BaiduErnieRequestBody.fromJson(json.decode(str));

String baiduErnieRequestBodyToJson(BaiduErnieRequestBody data) =>
    json.encode(data.toJson());

/// 百度ernie大模型的请求参数
class BaiduErnieRequestBody {
  // 聊天上下文信息。说明：
  // （1）messages成员不能为空，1个成员表示单轮对话，多个成员表示多轮对话
  // （2）最后一个message为当前请求的信息，前面的message为历史对话信息
  // （3）必须为奇数个成员，成员中message的role必须依次为user、assistant
  // （4）message中的content总长度和system字段总内容不能超过516096个字符，且不能超过126976 tokens
  List<ErnieMessage> messages;
  // 是否以流式接口的形式返回数据，默认false
  // 流式就是一个问题的回答是截成一小段一小段响应返回的，在response的处理中也要一段段拼在一起才是该问题的整体
  bool? stream;
  // 较高的数值会使输出更加随机，而较低的数值会使其更加集中和确定。范围 (0, 1.0]
  double? temperature;
  // 影响输出文本的多样性，取值越大，生成文本的多样性越强；默认0.7，取值范围 [0, 1.0]
  double? topP;
  // 通过对已生成的token增加惩罚，减少重复生成的现象。
  // 说明：（1）值越大表示惩罚越大（2）默认1.0，取值范围：[1.0, 2.0]
  double? penaltyScore;
  // 模型人设，主要用于人设设定，例如：你是xxx公司制作的AI助手，
  // 说明：长度限制，message中的content总长度和system字段总内容不能超过516096个字符，且不能超过126976 tokens
  String? system;
  // 生成停止标识，当模型生成结果以stop中某个元素结尾时，停止文本生成。
  // 说明：（1）每个元素长度不超过20字符（2）最多4个元素
  List<String>? stop;
  // 指定模型最大输出token数，
  // 说明：（1）如果设置此参数，范围[2, 4096]（2）如果不设置此参数，最大输出token数为4096
  int? maxOutputTokens;
  // 表示最终用户的唯一标识符
  String? userId;

  BaiduErnieRequestBody({
    required this.messages,
    this.stream = false,
    this.temperature = 0.95,
    this.topP = 0.7,
    this.penaltyScore = 1.0,
    this.system,
    this.stop,
    this.maxOutputTokens,
    this.userId,
  });

  factory BaiduErnieRequestBody.fromRawJson(String str) =>
      BaiduErnieRequestBody.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BaiduErnieRequestBody.fromJson(Map<String, dynamic> json) =>
      BaiduErnieRequestBody(
        messages: List<ErnieMessage>.from(
          json["messages"].map((x) => ErnieMessage.fromJson(x)),
        ),
        stream: json["stream"],
        temperature: json["temperature"]?.toDouble(),
        topP: json["top_p"]?.toDouble(),
        penaltyScore: json["penalty_score"]?.toDouble(),
        system: json["system"],
        stop: json["stop"],
        maxOutputTokens: json["max_output_tokens"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "messages": messages,
      "stream": stream,
      "temperature": temperature,
      "top_p": topP,
      "penalty_score": penaltyScore,
      "system": system,
      "stop": stop,
      "max_output_tokens": maxOutputTokens,
      "user_id": userId,
    };

    return data;
  }
}

// 百度ernie的消息参数
class ErnieMessage {
  String role;
  String content;

  ErnieMessage({
    required this.role,
    required this.content,
  });

  factory ErnieMessage.fromRawJson(String str) => ErnieMessage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ErnieMessage.fromJson(Map<String, dynamic> json) => ErnieMessage(
        role: json["role"],
        content: json["content"],
      );

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
      };
}

/// 百度ernie大模型的响应体
// To parse this JSON data, do
//     final baiduErnieResponseBody = baiduErnieResponseBodyFromJson(jsonString);

BaiduErnieResponseBody baiduErnieResponseBodyFromJson(String str) =>
    BaiduErnieResponseBody.fromJson(json.decode(str));

String baiduErnieResponseBodyToJson(BaiduErnieResponseBody data) =>
    json.encode(data.toJson());

class BaiduErnieResponseBody {
  // 本轮对话的id
  String? id;
  // 回包类型：chat.completion：多轮对话返回
  String? object;
  // 时间戳
  int? created;
  // 对话返回结果
  String? result;
  // 当前生成的结果是否被截断
  bool? isTruncated;
  // 表示用户输入是否存在安全风险，是否关闭当前会话，清理历史会话信息。
  //  true：是，表示用户输入存在安全风险，建议关闭当前会话，清理历史会话信息。
  //  false：否，表示用户输入无安全风险
  bool? needClearHistory;
  // token统计信息
  Usage? usage;

  /// 示例中没给的
  // 表示当前子句的序号。只有在流式接口模式下会返回该字段
  int? sentenceId;
  // 表示当前子句是否是最后一句。只有在流式接口模式下会返回该字段
  bool? isEnd;
  // 当need_clear_history为true时，此字段会告知第几轮对话有敏感信息，如果是当前问题，ban_round=-1
  int? banRound;

  BaiduErnieResponseBody({
    this.id,
    this.object,
    this.created,
    this.result,
    this.isTruncated,
    this.needClearHistory,
    this.usage,
    this.sentenceId,
    this.isEnd,
    this.banRound,
  });

  // 同步模式下，响应参数为以上字段的完整json包。
  // 流式模式下，各字段的响应参数为 data: {响应参数}。
  factory BaiduErnieResponseBody.fromJson(Map<String, dynamic> json) =>
      BaiduErnieResponseBody(
        id: json["id"],
        object: json["object"],
        created: json["created"],
        result: json["result"],
        isTruncated: json["is_truncated"],
        needClearHistory: json["need_clear_history"],
        usage: json["usage"] == null ? null : Usage.fromJson(json["usage"]),
        sentenceId: json["sentence_id"],
        isEnd: json["is_end"],
        banRound: json["ban_round"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "created": created,
        "result": result,
        "is_truncated": isTruncated,
        "need_clear_history": needClearHistory,
        "usage": usage?.toJson(),
        "sentence_id": sentenceId,
        "is_end": isEnd,
        "ban_round": banRound,
      };
}

class Usage {
  // 问题tokens数
  int? promptTokens;
  // 回答tokens数
  int? completionTokens;
  // tokens总数
  int? totalTokens;

  Usage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => Usage(
        promptTokens: json["prompt_tokens"],
        completionTokens: json["completion_tokens"],
        totalTokens: json["total_tokens"],
      );

  Map<String, dynamic> toJson() => {
        "prompt_tokens": promptTokens,
        "completion_tokens": completionTokens,
        "total_tokens": totalTokens,
      };
}

/// 百度ernie大模型的响应的报错体
// To parse this JSON data, do
//     final baiduErnieError = baiduErnieErrorFromJson(jsonString);

BaiduErnieError baiduErnieErrorFromJson(String str) =>
    BaiduErnieError.fromJson(json.decode(str));

String baiduErnieErrorToJson(BaiduErnieError data) =>
    json.encode(data.toJson());

class BaiduErnieError {
  int? errorCode;
  String? errorMsg;

  BaiduErnieError({
    this.errorCode,
    this.errorMsg,
  });

  factory BaiduErnieError.fromJson(Map<String, dynamic> json) =>
      BaiduErnieError(
        errorCode: json["error_code"],
        errorMsg: json["error_msg"],
      );

  Map<String, dynamic> toJson() => {
        "error_code": errorCode,
        "error_msg": errorMsg,
      };
}
