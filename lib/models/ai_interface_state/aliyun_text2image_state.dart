import 'dart:convert';

///
/// 2024-06-12 以阿里的通义万相系列 API为蓝本的请求响应模型
///
class AliyunTextToImgReq {
  String? model;
  Input? input;
  Parameters? parameters;

  AliyunTextToImgReq({
    this.model, // 指明需要调用的模型，固定值wanx-v1
    this.input,
    this.parameters,
  });

  factory AliyunTextToImgReq.fromRawJson(String str) =>
      AliyunTextToImgReq.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AliyunTextToImgReq.fromJson(Map<String, dynamic> json) =>
      AliyunTextToImgReq(
        model: json["model"],
        input: json["input"] == null ? null : Input.fromJson(json["input"]),
        parameters: json["parameters"] == null
            ? null
            : Parameters.fromJson(json["parameters"]),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "input": input?.toJson(),
        "parameters": parameters?.toJson(),
      };
}

class Input {
  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断
  String? prompt;
  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String? negativePrompt;
  // 输入参考图像的URL；图片格式可为 jpg，png，tiff，webp等常见位图格式。默认为空。
  String? refImg;

  Input({this.prompt, this.negativePrompt, this.refImg});

  factory Input.fromRawJson(String str) => Input.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Input.fromJson(Map<String, dynamic> json) => Input(
        prompt: json["prompt"],
        negativePrompt: json["negative_prompt"],
        refImg: json["ref_img"],
      );

  Map<String, dynamic> toJson() => {
        "prompt": prompt,
        "negative_prompt": negativePrompt,
        "ref_img": refImg,
      };
}

class Parameters {
  // 输出图像的风格，目前支持以下风格取值(注意要有尖括号)：
  //   "<auto>"：默认; "<3d cartoon>"：3D卡通; "<anime>"：动画; "<oil painting>"：油画
  //   "<watercolor>"：水彩; "<sketch>" ：素描;"<chinese painting>"：中国画; "<flat illustration>"：扁平插画
  String? style;
  // 生成图像的分辨率，目前仅支持'1024*1024'，'720*1280'，'1280*720'三种分辨率，默认为1024*1024像素。
  String? size;
  // 本次请求生成的图片数量，目前支持1~4张，默认为1。
  int? n;
  // 图片生成时候的种子值，取值范围为(0, 4294967290) 。如果不提供，则算法自动用一个随机生成的数字作为种子，
  //  如果给定了，则根据 batch 数量分别生成 seed，seed+1，seed+2，seed+3为参数的图片。
  int? seed;
  // 期望输出结果与垫图（参考图）的相似度，取值范围[0.0, 1.0]，数字越大，生成的结果与参考图越相似
  double? strength;
  // 垫图（参考图）生图使用的生成方式，可选值为'repaint' （默认） 和 'refonly'; 其中 repaint代表参考内容，refonly代表参考风格
  String? refMode;

  Parameters({
    this.style,
    this.size,
    this.n,
    this.seed,
    this.strength,
    this.refMode,
  });

  factory Parameters.fromRawJson(String str) =>
      Parameters.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Parameters.fromJson(Map<String, dynamic> json) => Parameters(
        style: json["style"],
        size: json["size"],
        n: json["n"],
        seed: json["seed"],
        strength: json["strength"]?.toDouble(),
        refMode: json["ref_mode"],
      );

  Map<String, dynamic> toJson() => {
        "style": style,
        "size": size,
        "n": n,
        "seed": seed,
        "strength": strength,
        "ref_mode": refMode,
      };
}

///
/// 2024-06-12 以阿里的通义万相系列 API为蓝本的响应模型
///
class AliyunTextToImgResp {
  // 本次请求的系统唯一码。
  String? requestId;
  // 响应的结果
  Output? output;
  // 成功的话会带上消耗的请求数
  Usage? usage;
  // 状态码
  String? statusCode;
  // 错误代号和信息
  String? code;
  String? message;

  AliyunTextToImgResp({
    this.requestId,
    this.output,
    this.usage,
    this.statusCode,
    this.code,
    this.message,
  });

  factory AliyunTextToImgResp.fromRawJson(String str) =>
      AliyunTextToImgResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AliyunTextToImgResp.fromJson(Map<String, dynamic> json) =>
      AliyunTextToImgResp(
        requestId: json["request_id"],
        output: json["output"] == null ? null : Output.fromJson(json["output"]),
        usage: json["usage"] == null ? null : Usage.fromJson(json["usage"]),
        statusCode: json["status_code"],
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "request_id": requestId,
        "output": output?.toJson(),
        "usage": usage?.toJson(),
        "status_code": statusCode,
        "code": code,
        "message": message,
      };
}

/// 文生图默认响应用到这个，只有taskId和status，但作业任务状态查询和结果获取接口可以有更多的属性
class Output {
  // 本次请求的异步任务的作业 id，实际作业结果需要通过异步任务查询接口获取。
  String? taskId;
  // 提交异步任务后的作业状态
  String? taskStatus;
  // 有成功的图片，就会存在这里；如果是多个中部分成功，这里面还会有报错信息
  List<Result>? results;
  // 作业中每个batch任务的状态：
  //  TOTAL：总batch数目、SUCCEEDED：已经成功的batch数目、FAILED：已经失败的batch数目
  TaskMetrics? taskMetrics;
  // 整个请求全都出错，则也会带上错误代号和信息
  String? code;
  String? message;

  Output({
    this.taskId,
    this.taskStatus,
    this.results,
    this.taskMetrics,
    this.code,
    this.message,
  });

  factory Output.fromRawJson(String str) => Output.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Output.fromJson(Map<String, dynamic> json) => Output(
        taskId: json["task_id"],
        taskStatus: json["task_status"],
        results: json["results"] == null
            ? []
            : List<Result>.from(
                json["results"]!.map((x) => Result.fromJson(x))),
        taskMetrics: json["task_metrics"] == null
            ? null
            : TaskMetrics.fromJson(json["task_metrics"]),
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "task_id": taskId,
        "task_status": taskStatus,
        "results": results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
        "task_metrics": taskMetrics?.toJson(),
        "code": code,
        "message": message,
      };
}

class Result {
  String? url;
  String? code;
  String? message;

  Result({
    this.url,
    this.code,
    this.message,
  });

  factory Result.fromRawJson(String str) => Result.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        url: json["url"],
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "code": code,
        "message": message,
      };
}

class TaskMetrics {
  int? total;
  int? succeeded;
  int? failed;

  TaskMetrics({this.total, this.succeeded, this.failed});

  factory TaskMetrics.fromRawJson(String str) =>
      TaskMetrics.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TaskMetrics.fromJson(Map<String, dynamic> json) => TaskMetrics(
        total: json["TOTAL"],
        succeeded: json["SUCCEEDED"],
        failed: json["FAILED"],
      );

  Map<String, dynamic> toJson() => {
        "TOTAL": total,
        "SUCCEEDED": succeeded,
        "FAILED": failed,
      };
}

class Usage {
  // 本次请求成功生成的图片张数。
  int? imageCount;

  Usage({this.imageCount});

  factory Usage.fromRawJson(String str) => Usage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Usage.fromJson(Map<String, dynamic> json) =>
      Usage(imageCount: json["image_count"]);

  Map<String, dynamic> toJson() => {"image_count": imageCount};
}
