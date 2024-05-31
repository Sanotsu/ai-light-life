import 'dart:convert';

/// 腾讯hunyuan-lite大模型的消息的接口
// 稍微有点不一样，混元时首字母大写的key，ernie是全小写的下划线
class HunyuanMessage {
  // system(如存在必须是对话第一个)、user、assistant
  String role;
  String content;

  HunyuanMessage({
    required this.role,
    required this.content,
  });

  factory HunyuanMessage.fromJson(Map<String, dynamic> json) => HunyuanMessage(
        role: json["Role"],
        content: json["Content"],
      );

  Map<String, dynamic> toJson() => {
        "Role": role,
        "Content": content,
      };
}

/// 腾讯hunyuan-lite大模型的最小请求参数
/*
{
    "Model": "hunyuan-lite",
    "Messages": [
        {
            "Role": "user",
            "Content": "计算1+1"
        }
    ]
}
*/
// To parse this JSON data, do
//     final tencentHunYuanRequestBody = tencentHunYuanRequestBodyFromJson(jsonString);
TencentHunYuanRequestBody tencentHunYuanRequestBodyFromJson(String str) =>
    TencentHunYuanRequestBody.fromJson(json.decode(str));

String tencentHunYuanRequestBodyToJsonString(TencentHunYuanRequestBody data) =>
    json.encode(data.toJson());

class TencentHunYuanRequestBody {
  /// 2024-05-30 经过实测，这个action和version会放在header中，添加到参数中会报错:The parameter `Action` is not recognized
  // // 公共参数，本接口取值：ChatCompletions。
  // String action;
  // // 公共参数，本接口取值：2023-09-01。
  // String version;
  // 地域参数，用来标识希望操作哪个地域的数据。(【此处接口不必用】)
  // 注意：某些接口不需要传递该参数，接口文档中会对此特别说明，此时即使传递该参数也不会生效。
  String? region;
  // 模型名称，可选值包括 hunyuan-lite(目前就这个免费)。
  String model;
  // 聊天上下文信息。
  // 1. 长度最多为 40，按对话时间从旧到新在数组中排列。
  // 2. Message.Role 可选值：system、user、assistant。
  //  中，system 角色可选，如存在则必须位于列表的最开始。
  //  user 和 assistant 需交替出现（一问一答），以 user 提问开始和结束，且 Content 不能为空。
  //  Role 的顺序示例：[system（可选） user assistant user assistant user …]。
  // 3. Messages 中 Content 总长度不能超过模型输入长度上限（可参考 产品概述 文档），
  //  超过则会截断最前面的内容，只保留尾部内容。
  List<HunyuanMessage> messages;
  // 流式调用开关。
  //   说明：
  // 1. 未传值时默认为非流式调用（false）。
  // 2. 流式调用时以 SSE 协议增量返回结果（返回值取 Choices[n].Delta 中的值，需要拼接增量数据才能获得完整结果）。
  // 3. 非流式调用时：
  // 调用方式与普通 HTTP 请求无异。
  // 接口响应耗时较长，如需更低时延建议设置为 true。
  // 只返回一次最终结果（返回值取 Choices[n].Message 中的值）。
  // 注意：
  //  通过 SDK 调用时，流式和非流式调用需用不同的方式获取返回值。
  bool? stream;
  // 流式输出审核开关。
  //   说明：
  // 1. 当使用流式输出（Stream 字段值为 true）时，该字段生效。
  // 2. 输出审核有流式和同步两种模式，流式模式首包响应更快。未传值时默认为流式模式（true）。
  // 3. 如果值为 true，将对输出内容进行分段审核，审核通过的内容流式输出返回。如果出现审核不过，响应中的 FinishReason 值为 sensitive。
  // 4. 如果值为 false，则不使用流式输出审核，需要审核完所有输出内容后再返回结果
  bool? streamModeration;
  //   说明：
  // 1. 影响输出文本的多样性，取值越大，生成文本的多样性越强。
  // 2. 默认 1.0，取值区间为 [0.0, 1.0]。
  // 3. 非必要不建议使用，不合理的取值会影响效果。
  double? topP;
  //   说明：
  // 1. 较高的数值会使输出更加随机，而较低的数值会使其更加集中和确定。
  // 2. 默认 1.0，取值区间为 [0.0, 2.0]。
  // 3. 非必要不建议使用，不合理的取值会影响效果。
  double? temperature;
  //   功能增强（如搜索）开关。
  // 说明：
  // 1. hunyuan-lite 无功能增强（如搜索）能力，该参数对 hunyuan-lite 版本不生效。
  // 2. 未传值时默认打开开关。
  // 3. 关闭时将直接由主模型生成回复内容，可以降低响应时延（对于流式输出时的首字时延尤为明显）。
  //    但在少数场景里，回复效果可能会下降。
  // 4. 安全审核能力不属于功能增强范围，不受此字段影响。
  bool? enableEnhancement;

  TencentHunYuanRequestBody({
    // 2024-05-30 看文档时的预设值
    // https://console.cloud.tencent.com/api/explorer?Product=hunyuan&Version=2023-09-01&Action=ChatCompletions
    // this.action = "ChatCompletions",
    // this.version = "2023-09-01",
    this.model = "hunyuan-lite",
    required this.messages,
    this.stream = false,
    this.streamModeration = false,
    this.topP = 1.0,
    this.temperature = 1.0,
    this.enableEnhancement = true,
  });

  factory TencentHunYuanRequestBody.fromJson(Map<String, dynamic> json) =>
      TencentHunYuanRequestBody(
        // action: json["Action"] ?? "ChatCompletions",
        // version: json["Version"] ?? "2023-09-01",
        model: json["Model"] ?? "hunyuan-lite",
        messages: List<HunyuanMessage>.from(
          json["Messages"].map((x) => HunyuanMessage.fromJson(x)),
        ),
        stream: json["Stream"] ?? false,
        streamModeration: json["StreamModeration"] ?? false,
        topP: json["TopP"] ?? 1.0,
        temperature: json["Temperature"] ?? 1.0,
        enableEnhancement: json["EnableEnhancement"] ?? true,
      );

  Map<String, dynamic> toJson() => {
        // "Action": action,
        // "Version": version,
        "Model": model,
        "Messages": List<dynamic>.from(messages.map((x) => x.toJson())),
        "Stream": stream,
        "StreamModeration": streamModeration,
        "TopP": topP,
        "Temperature": temperature,
        "EnableEnhancement": enableEnhancement,
      };
}

/// 腾讯hunyuan-lite大模型的响应参数
/*
// 成功：
{
  "Response": {
    "RequestId": "44024aec-90b1-4749-9e55-7dd5dbcf67f2",
    "Note": "以上内容为AI生成，不代表开发者立场，请勿删除或修改本标记",
    "Choices": [
      {
        "Message": {
          "Role": "assistant",
          "Content": "您好！很高兴为您服务，有什么我可以帮您的吗？"
        },
        "FinishReason": "stop"
      }
    ],
    "Created": 1717040653,
    "Id": "44024aec-90b1-4749-9e55-7dd5dbcf67f2",
    "Usage": {
      "PromptTokens": 4,
      "CompletionTokens": 13,
      "TotalTokens": 17
    }
  }
}
// 出错：
{
    "Response": {
        "RequestId": "188cc996-ab09-49a7-aa9f-1df88f11c6b4",
        "Error": {
            "Code": "InvalidParameter",
            "Message": "Temperature must be 2 or less"
        }
    }
}
*/
/// To parse this JSON data, do
//     final tencentHunYuanResponseBody = tencentHunYuanResponseBodyFromJson(jsonString);
TencentHunYuanResponseBody tencentHunYuanResponseBodyFromJson(String str) =>
    TencentHunYuanResponseBody.fromJson(json.decode(str));

String tencentHunYuanResponseBodyToJson(TencentHunYuanResponseBody data) =>
    json.encode(data.toJson());

class TencentHunYuanResponseBody {
  // 唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。
  //定位问题时需要提供该次请求的 RequestId。
  //本接口为流式响应接口，当请求成功时，RequestId 会被放在 HTTP 响应的 Header "X-TC-RequestId" 中。
  String requestId;
  // 免责声明。
  String? note;
  // 回复内容。
  List<Choice>? choices;
  // 创建的 Unix 时间戳，单位为秒
  int? created;
  // 本轮对话的 ID。
  String? id;
  // Token 统计信息。
  Usage? usage;
  //   错误信息。
  // 如果流式返回中服务处理异常，返回该错误信息。
  // 注意：此字段可能返回 null，表示取不到有效值。
  TencentHunYuanError? errorMsg;

  TencentHunYuanResponseBody({
    required this.requestId,
    this.note,
    this.choices,
    this.created,
    this.id,
    this.usage,
    this.errorMsg,
  });

  factory TencentHunYuanResponseBody.fromJson(Map<String, dynamic> json) =>
      TencentHunYuanResponseBody(
        requestId: json["RequestId"],
        note: json["Note"],
        choices: json["Choices"] == null
            ? []
            : List<Choice>.from(
                json["Choices"]!.map((x) => Choice.fromJson(x))),
        created: json["Created"],
        id: json["Id"],
        usage: json["Usage"] == null ? null : Usage.fromJson(json["Usage"]),
        errorMsg: json["ErrorMsg"] == null
            ? null
            : TencentHunYuanError.fromJson(json["ErrorMsg"]),
      );

  Map<String, dynamic> toJson() => {
        "RequestId": requestId,
        "Note": note,
        "Choices": choices == null
            ? []
            : List<dynamic>.from(choices!.map((x) => x.toJson())),
        "Created": created,
        "Id": id,
        "Usage": usage?.toJson(),
        "ErrorMsg": errorMsg?.toJson(),
      };
}

class Choice {
  HunyuanMessage message;
  String finishReason;

  Choice({
    required this.message,
    required this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
        message: HunyuanMessage.fromJson(json["Message"]),
        finishReason: json["FinishReason"],
      );

  Map<String, dynamic> toJson() => {
        "Message": message.toJson(),
        "FinishReason": finishReason,
      };
}

class Usage {
  int promptTokens;
  int completionTokens;
  int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => Usage(
        promptTokens: json["PromptTokens"],
        completionTokens: json["CompletionTokens"],
        totalTokens: json["TotalTokens"],
      );

  Map<String, dynamic> toJson() => {
        "PromptTokens": promptTokens,
        "CompletionTokens": completionTokens,
        "TotalTokens": totalTokens,
      };
}

/// 腾讯混元大模型的响应的报错体
/// 和百度的类似，也是key字符串的区别
// To parse this JSON data, do
//     final tencentHunYuanError = tencentHunYuanErrorFromJson(jsonString);
TencentHunYuanError tencentHunYuanErrorFromJson(String str) =>
    TencentHunYuanError.fromJson(json.decode(str));

String tencentHunYuanErrorToJson(TencentHunYuanError data) =>
    json.encode(data.toJson());

class TencentHunYuanError {
  String code;
  String message;

  TencentHunYuanError({
    required this.code,
    required this.message,
  });

  factory TencentHunYuanError.fromJson(Map<String, dynamic> json) =>
      TencentHunYuanError(
        code: json["Code"],
        message: json["Message"],
      );

  Map<String, dynamic> toJson() => {
        "Code": code,
        "Message": message,
      };
}
