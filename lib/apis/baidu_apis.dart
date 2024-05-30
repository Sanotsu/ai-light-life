// ignore_for_file: avoid_print, constant_identifier_names

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/baidu_ernie_state.dart';
import '_self_keys.dart';

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///
///

const baiduERNIEOAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";
const baiduERNIESpeedUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/ernie-speed-128k";

/// 使用 AK，SK 生成鉴权签名（Access Token）
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了
  var respData = await HttpUtils.post(
    path: baiduERNIEOAuthUrl,
    method: HttpMethod.post,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    data: {
      "grant_type": "client_credentials",
      "client_id": BAIDU_API_KEY,
      "client_secret": BAIDU_SECRET_KEY
    },
  );

  // 响应是json格式
  return respData['access_token'];
}

/// 获取指定设备类型(产品)包含的功能列表
Future<BaiduErnieResponseBody> getErnieSpeedResponse({
  List<Message>? messages,
}) async {
  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  // var t = BaiduErnieRequestBody(
  //   userId: "dev_test", // 避免滥用，这里取设备唯一标识之类的
  //   messages: [],
  // );

  var body = BaiduErnieRequestBody.fromJson({
    "user_id": "david",
    "messages": [
      {"role": "user", "content": "写一个python3的快速排序"}
    ],
    "temperature": 0.95,
    "top_p": 0.7,
    "penalty_score": 1,
    "system": "你是小公司制作的AI助手",
    "max_output_tokens": 1024
  });

  // body.toRawJson();

  var respData = await HttpUtils.post(
    path: "$baiduERNIESpeedUrl?access_token=$token",
    method: HttpMethod.post,
    headers: {"Content-Type": "application/json"},
    data: body,
  );

  // 响应是json格式
  return BaiduErnieResponseBody.fromJson(respData);
}
