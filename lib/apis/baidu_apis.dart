// ignore_for_file: avoid_print

import '../../dio_client/cus_http_client.dart';
import '../../dio_client/cus_http_request.dart';
import '../dio_client/interceptor_error.dart';
import '../models/ai_interface_state/baidu_fuyu8b_state.dart';
import '../services/cus_get_storage.dart';
import '_self_keys.dart';

/// 百度平台大模型API的前缀地址
const baiduAigcUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/";
// 百度的token请求地址
const baiduAigcAuthUrl = "https://aip.baidubce.com/oauth/2.0/token";

// 百度平台下第三方的fuyu图像理解模型API接口
const baiduFuyu8BUrl =
    "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/image2text/fuyu_8b";

///
/// 注意，这里没有处理报错，请求过程中的错误在cus_client中集中处理的；
/// 但请求结果处理的报错，就应该补上？？？
///

///
///-----------------------------------------------------------------------------
/// 百度的请求方法
///
/// 使用 AK，SK 生成鉴权签名（Access Token）
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了

  try {
    var respData = await HttpUtils.post(
      path: baiduAigcAuthUrl,
      method: HttpMethod.post,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      data: {
        "grant_type": "client_credentials",
        // 如果是用户自行配置，使用自行配置的key；否则检查用户通用配置；最后才是自己的账号key
        "client_id": MyGetStorage().getBaiduCommonAppId() ?? BAIDU_API_KEY,
        "client_secret":
            MyGetStorage().getBaiduCommonAppKey() ?? BAIDU_SECRET_KEY,
      },
    );

    // 响应是json格式
    return respData['access_token'];
  } on HttpException catch (e) {
    return e.msg;
  } catch (e) {
    print("bbbbbbbbbbbbbbbb ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return e.toString();
  }
}

/// 获取Fuyu-8B图像理解的响应结果
Future<BaiduFuyu8BResp> getBaiduFuyu8BResp(String prompt, String image) async {
  // 每次请求都要实时获取最小的token
  String token = await getAccessToken();

  var body = BaiduFuyu8BReq(prompt: prompt, image: image);

  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: "$baiduFuyu8BUrl?access_token=$token",
      method: HttpMethod.post,
      headers: {"Content-Type": "application/json"},
      data: body,
    );

    var end = DateTime.now().millisecondsSinceEpoch;

    print("百度图生文-------耗时${(end - start) / 1000} 秒");
    print("百度图生文-------$respData");

    // 响应是json格式
    return BaiduFuyu8BResp.fromJson(respData);
  } on HttpException catch (e) {
    return BaiduFuyu8BResp(
      // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
      errorCode: e.code.toString(),
      errorMsg: e.msg,
    );
  } catch (e) {
    print("vvvvvvvvvvvvvvvvvvl ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    return BaiduFuyu8BResp(
      // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
      errorCode: "10000",
      errorMsg: e.toString(),
    );
  }
}
