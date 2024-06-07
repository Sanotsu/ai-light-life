import 'dart:convert';

///
/// 阿里云、百度和其他一般第三方常规的aigc(大模型文本对话)返回的消息列表都是role和content。
///   腾讯其所有json请求或响应的body，都是首字母全大写的Pascal命名，其他的就是全小写加下划线的snake命名。
///

class CommonMessage {
  String role;
  String content;

  CommonMessage({
    required this.role,
    required this.content,
  });

  factory CommonMessage.fromRawJson(String str) =>
      CommonMessage.fromJson(json.decode(str));

  // 为了通用，都带上命名方式，默认就snake，可传pascal
  String toRawJson({String? caseType}) =>
      json.encode(toJson(caseType: caseType));

  factory CommonMessage.fromJson(Map<String, dynamic> json) => CommonMessage(
        role: json["role"] ?? json["Role"],
        content: json["content"] ?? json["Content"],
      );

  Map<String, dynamic> toJson({String? caseType}) {
    return caseType?.toLowerCase() == "pascal"
        ? {"Role": role, "Content": content}
        : {"role": role, "content": content};
  }
}

///
/// 3个平台的usage都不一样，比较麻烦
///  所以索性就所有参数都带上，都可选这样来兼容
///
class CommonUsage {
  int? promptTokens;
  int? completionTokens;
  int? totalTokens;
  int? inputTokens;
  int? outputTokens;

  CommonUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.inputTokens,
    this.outputTokens,
  });

  factory CommonUsage.fromJson(Map<String, dynamic> json) {
    return CommonUsage(
      promptTokens: json["PromptTokens"] ?? json["prompt_tokens"],
      completionTokens: json["CompletionTokens"] ?? json["completion_tokens"],
      totalTokens: json["TotalTokens"] ?? json["total_tokens"],
      inputTokens: json["input_tokens"],
      outputTokens: json["output_tokens"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "PromptTokens": promptTokens,
      "CompletionTokens": completionTokens,
      "TotalTokens": totalTokens,
      "input_tokens": inputTokens,
      "output_tokens": outputTokens,
    };
  }
}

///
/// 百度的响应结果直接是result栏位
///
class CommonChoice {
  CommonMessage message;
  String finishReason;
  int? index;

  CommonChoice({
    required this.message,
    required this.finishReason,
    this.index,
  });

  factory CommonChoice.fromJson(Map<String, dynamic> json) => CommonChoice(
        message: CommonMessage.fromJson(json["message"] ?? json["Message"]),
        finishReason: json["finish_reason"] ?? json["FinishReason"],
        index: json["index"],
      );

  Map<String, dynamic> toJson({String? caseType}) =>
      caseType?.toLowerCase() == "pascal"
          ? {
              "Message": message.toJson(),
              "FinishReason": finishReason,
              "index": index,
            }
          : {
              "message": message.toJson(),
              "finish_reason": finishReason,
              "index": index,
            };
}

///
/// 阿里云的请求响应参数层级还多一点
///   入参 input、parameters 还有单独的东西
///   出参 output 等
class AliyunInput {
  List<CommonMessage>? messages;

  AliyunInput({this.messages});

  factory AliyunInput.fromJson(Map<String, dynamic> json) => AliyunInput(
        messages: json["messages"] == null
            ? []
            : List<CommonMessage>.from(
                json["messages"]!.map((x) => CommonMessage.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "messages": messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
      };
}

class AliyunParameters {
  int? seed;
  String? resultFormat;

  AliyunParameters({this.seed, this.resultFormat});

  factory AliyunParameters.fromJson(Map<String, dynamic> json) =>
      AliyunParameters(seed: json["seed"], resultFormat: json["result_format"]);

  Map<String, dynamic> toJson() =>
      {"seed": seed, "result_format": resultFormat};
}

class AliyunOutput {
  // 入参result_format=text时候的返回值
  String? text;
  String? finishReason;
  // 入参result_format=message时候的返回值
  List<CommonChoice>? choices;

  AliyunOutput({
    this.text,
    this.finishReason,
    this.choices,
  });

  factory AliyunOutput.fromJson(Map<String, dynamic> json) => AliyunOutput(
        text: json["text"],
        finishReason: json["finish_reason"],
        choices: json["choices"] == null
            ? []
            : List<CommonChoice>.from(
                json["choices"]!.map((x) => CommonChoice.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "finish_reason": finishReason,
        "choices": choices == null
            ? []
            : List<dynamic>.from(choices!.map((x) => x.toJson())),
      };
}

///
/// ============================================================================
/// aigc传参，都是最小的、必传的，其他都预设(一般人也不会调)
///  注意，都使用非流式的回复
///=============================================================================

CommonReqBody commonReqBodyFromJson(String str) =>
    CommonReqBody.fromJson(json.decode(str));

String commonReqBodyToJson(CommonReqBody data, {String? caseType}) =>
    json.encode(data.toJson(caseType: caseType));

class CommonReqBody {
  // [腾讯、阿里云]需要显示指定模型名称
  String? model;
  // [腾讯、百度] 百度只需要这一个，模型在构建authorition就处理了
  List<CommonMessage>? messages;
  // [阿里云] 把消息体单独再放到一个input类中，该类还可以有其他属性
  AliyunInput? input;
  // [阿里云] 额外的，阿里还可以配置其他参数，比较有用的是指定输出消息的格式，阿里云不同模型可能默认响应不一样
  AliyunParameters? parameters;

  CommonReqBody({this.model, this.messages, this.input, this.parameters});

  factory CommonReqBody.fromRawJson(String str) =>
      CommonReqBody.fromJson(json.decode(str));

  String toRawJson({String? caseType}) =>
      json.encode(toJson(caseType: caseType));

  factory CommonReqBody.fromJson(Map<String, dynamic> json) => CommonReqBody(
        // 腾讯请求应该不用传这个
        model: json["model"] ?? json["Model"],
        // 注意腾讯是帕斯卡命名，但只需要关注这一个栏位即可   ///????
        messages: List<CommonMessage>.from(
          ((json["messages"] ?? json["Messages"]) as List)
              .map((x) => CommonMessage.fromJson(x)),
        ),
        input:
            json["input"] == null ? null : AliyunInput.fromJson(json["input"]),
        parameters: json["parameters"] == null
            ? null
            : AliyunParameters.fromJson(json["parameters"]),
      );

  Map<String, dynamic> toJson({String? caseType}) {
    /// ???? 有问题，传入不支持的参数会报错？？
    return caseType?.toLowerCase() == "pascal"
        ? {
            "Model": model,
            "Messages": messages
                ?.map(
                  (e) => e.toJson(caseType: "pascal"),
                )
                .toList(),
          }
        : {
            "model": model,
            "messages": messages,
            "input": input?.toJson(),
            "parameters": parameters?.toJson(),
          };
  }
}

///
/// aigc 的响应，自然就是越多越好，那最多就是把3个平台的所有值都当做了参数
///   不过可能在取值显示的时候，可能不通用。
///     比如百度的结果是result，腾讯是choices的某条message，阿里在choices外面还有一层output
/// 这个就要尽量全一点了，取值更方便
///
/*
/// 百度文心lite的响应
{
    id: "as-b8fxqv4yht",
    object: "chat.completion",
    created: 1717662144,
    result: "你好！有什么我可以帮助你的吗？",
    is_truncated: false,
    need_clear_history: false,
    usage: {prompt_tokens: 1, completion_tokens: 8, total_tokens: 9}
}
/// 腾讯混元lite的响应
{
    Response: {
        RequestId: "1881a408-b517-4ee8-83db-b291e265dbb8",
        Note: "以上内容为AI生成，不代表开发者立场，请勿删除或修改本标记",
        Choices: [{Message: {Role: assistant, Content: 你好！很高兴为您提供帮助，请问您有什么问题？}, FinishReason: stop}]
        Created: 1717662179,
        Id: "1881a408-b517-4ee8-83db-b291e265dbb8",
        Usage: {PromptTokens: 3, CompletionTokens: 12, TotalTokens: 15}
  }
}
/// 阿里云千问开源的响应
{
    output: {
        choices: [{finish_reason: stop, message: {role: assistant, content: 你好！有什么我可以帮助你的吗？}}]
    }
    usage: {total_tokens: 9, output_tokens: 8, input_tokens: 1},
    request_id: "ca2f16c4-661e-9ffb-af92-59e393c138b5"
 }
*/
CommonRespBody commonRespBodyFromJson(String str) =>
    CommonRespBody.fromJson(json.decode(str));

String commonRespBodyToJson(CommonRespBody data) => json.encode(data.toJson());

class CommonRespBody {
  ///
  /// 百度千帆大模型 对话Chat
  ///   https://cloud.baidu.com/doc/WENXINWORKSHOP/s/6ltgkzya5
  /// id、object、created、sentence_id、is_end、is_truncated、result
  /// need_clear_history、ban_round、usage
  ///
  /// 腾讯混元生文(首字母大写)
  /// https://cloud.tencent.com/document/api/1729/105701
  /// Created、Usage、Note、Id、Choices、ErrorMsg、RequestId
  ///
  /// 阿里云通义千问等部分 开源文本(入参result_format=message时候的返回值)
  /// https://help.aliyun.com/document_detail/2712575.html#58595f510c3zl
  ///
  /// request_id、usage、output(text、finish_reason、choise)
  ///   入参result_format=text时,output的内容单独2个栏位在外层：text、finish_reason
  ///
  ///

  /// 已经通用的、或者可以想办法通用的
  // token统计信息
  CommonUsage? usage;
  // 本轮对话的 ID。
  String? id;
  // 唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。
  //定位问题时需要提供该次请求的 RequestId。
  //本接口为流式响应接口，当请求成功时，RequestId 会被放在 HTTP 响应的 Header "X-TC-RequestId" 中。
  String? requestId;
  // 创建的 Unix 时间戳，单位为秒
  int? created;
  // 错误码和错误消息
  String? errorCode;
  String? errorMsg;
  // 腾讯的还嵌一层
  TencentError? tencentError;

  /// 回复内容的主体(各不相同)
  // 响应的状态
  int? statusCode;
  // 百度响应内容
  String? result;
  // 腾讯响应内容
  List<CommonChoice>? choices;
  // 阿里云响应内容
  AliyunOutput? output;

  /// 2024-06-06 3个不同的搞成一样的？?? 我现在是需要用到显示的值，其他的都暂时不考虑
  String customReplyText;

  /// [百度 特有]
  // 回包类型：chat.completion：多轮对话返回
  String? object;
  // 当前生成的结果是否被截断
  bool? isTruncated;
  // 表示用户输入是否存在安全风险，是否关闭当前会话，清理历史会话信息。
  //  true：是，表示用户输入存在安全风险，建议关闭当前会话，清理历史会话信息。
  //  false：否，表示用户输入无安全风险
  bool? needClearHistory;
  // 当need_clear_history为true时，此字段会告知第几轮对话有敏感信息，
  // 如果是当前问题，ban_round=-1
  int? banRound;
  // 表示当前子句的序号。只有在流式接口模式下会返回该字段
  int? sentenceId;
  // 表示当前子句是否是最后一句。只有在流式接口模式下会返回该字段
  bool? isEnd;
  // [腾讯 特有] 免责声明。
  String? note;

  CommonRespBody({
    /// 尽量通用
    this.usage,
    this.id,
    this.requestId,
    this.created,
    this.errorCode,
    this.errorMsg,
    this.tencentError,

    /// 消息主体
    this.statusCode,
    this.result,
    this.choices,
    this.output,
    required this.customReplyText,

    /// 一些特有
    this.object,
    this.isTruncated,
    this.needClearHistory,
    this.banRound,
    this.sentenceId,
    this.isEnd,
    this.note,
  });

  // 同步模式下，响应参数为以上字段的完整json包。
  // Created、Usage、Note、Id、Choices、ErrorMsg、RequestId
  factory CommonRespBody.fromJson(Map<String, dynamic> json) {
    var customReplyText = "<未取得数据……>";

    /// 理论上，这三个只会存在一个有值
    // 百度的基础消息
    if (json["result"] != null) {
      customReplyText = json["result"];
    }
    // 阿里的基础消息
    if (json["output"] != null) {
      var temp = AliyunOutput.fromJson(json["output"]);
      if (temp.choices != null && temp.choices!.isNotEmpty) {
        customReplyText = temp.choices!.first.message.content;
      }
    }
    // 腾讯的基础消息
    if (json["Choices"] != null) {
      var temp = List<CommonChoice>.from(
        json["Choices"]!.map((x) => CommonChoice.fromJson(x)),
      );
      if (temp.isNotEmpty) {
        customReplyText = temp.first.message.content;
      }
    }
    if (json["Note"] != null) {
      customReplyText += "\n\n\n\n**${json["Note"]}**";
    }

    /// 报错信息很重要，先判断没有报错才显示正文回复的
    var errorCode = json["error_code"] ?? json["code"];
    var errorMsg = json["error_msg"] ?? json["message"];
    if (json["Error"] != null) {
      var temp = TencentError.fromJson(json["Error"]);
      errorCode = temp.code;
      errorMsg = temp.message;
    }

    return CommonRespBody(
      /// 公共
      usage: (json["Usage"] == null && json["usage"] == null)
          ? null
          : (json["usage"] != null
              ? CommonUsage.fromJson(json["usage"])
              : CommonUsage.fromJson(json["Usage"])),
      id: json["id"] ?? json["Id"],
      requestId: json["request_id"] ?? json["RequestId"],
      created: json["created"] ?? json["Created"],
      errorCode: errorCode?.toString(),
      errorMsg: errorMsg,
      tencentError: json["ErrorMsg"] == null
          ? null
          : TencentError.fromJson(json["ErrorMsg"]),

      /// 消息主体
      statusCode: json["status_code"],
      result: json["result"],
      choices: json["Choices"] == null
          ? []
          : List<CommonChoice>.from(
              json["Choices"]!.map((x) => CommonChoice.fromJson(x)),
            ),
      output:
          json["output"] == null ? null : AliyunOutput.fromJson(json["output"]),
      customReplyText: customReplyText,

      /// 特有
      object: json["object"],
      isTruncated: json["is_truncated"],
      needClearHistory: json["need_clear_history"],
      banRound: json["ban_round"],
      sentenceId: json["sentence_id"],
      isEnd: json["is_end"],
      note: json["Note"],
    );
  }

  Map<String, dynamic> toJson() => {
        /// 通用的(百度的大写就额外多一个)
        "usage": usage?.toJson(),
        "Usage": usage?.toJson(),
        "id": id,
        "Id": id,
        "request_id": requestId,
        "RequestId": requestId,
        "created": created,
        "Created": created,
        "error_code": errorCode,
        "error_msg": errorMsg,
        "code": errorCode,
        "message": errorMsg,
        "ErrorMsg": tencentError?.toJson(),

        /// 主体内容
        "status_code": statusCode,
        // 百度
        "result": result,
        // 阿里
        "output": output?.toJson(),
        // 腾讯
        "Choices": choices == null
            ? []
            : List<dynamic>.from(choices!.map((x) => x.toJson())),
        "Note": note,

        /// 一些特有的
        "object": object,
        "is_truncated": isTruncated,
        "need_clear_history": needClearHistory,
        "ban_round": banRound,
        "sentence_id": sentenceId,
        "is_end": isEnd,
      };
}

/// 腾讯混元大模型响应的报错体
TencentError tencentHunYuanErrorFromJson(String str) =>
    TencentError.fromJson(json.decode(str));

String tencentHunYuanErrorToJson(TencentError data) =>
    json.encode(data.toJson());

class TencentError {
  String code;
  String message;

  TencentError({required this.code, required this.message});

  factory TencentError.fromJson(Map<String, dynamic> json) =>
      TencentError(code: json["Code"], message: json["Message"]);

  Map<String, dynamic> toJson() => {"Code": code, "Message": message};
}
