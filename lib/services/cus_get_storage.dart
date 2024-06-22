import 'package:get_storage/get_storage.dart';

final box = GetStorage();

class MyGetStorage {
  /// 将使用者自己输入的平台、模型名、应用ID和Key存入缓存
  Future<void> setCusPlatform(String platform) async {
    await box.write("cus_platform", platform);
  }

  String? getCusPlatform() => box.read("cus_platform");

  Future<void> setCusLlmName(String llmName) async {
    await box.write("cus_llm_name", llmName);
  }

  String? getCusLlmName() => box.read("cus_llm_name");

  Future<void> setCusAppId(String appId) async {
    await box.write("cus_app_id", appId);
  }

  String? getCusAppId() => box.read("cus_app_id");

  Future<void> setCusAppKey(String appKey) async {
    await box.write("cus_app_key", appKey);
  }

  String? getCusAppKey() => box.read("cus_app_key");

  /// 2024-06-22平台应用通用配置，就是配这平台一个应用，不指定模型都可以用
  /// set id或key可以指定null，用于清空(是否配置的判断也是用非空判断的)

  /// 阿里云的id和key
  Future<void> setAliyunCommonAppId(String? appId) async {
    await box.write("cus_aliyun_app_id", appId);
  }

  String? getAliyunCommonAppId() => box.read("cus_aliyun_app_id");

  Future<void> setAliyunCommonAppKey(String? appKey) async {
    await box.write("cus_aliyun_app_key", appKey);
  }

  String? getAliyunCommonAppKey() => box.read("cus_aliyun_app_key");

  /// 百度的id和key
  Future<void> setBaiduCommonAppId(String? appId) async {
    await box.write("cus_baidu_app_id", appId);
  }

  String? getBaiduCommonAppId() => box.read("cus_baidu_app_id");

  Future<void> setBaiduCommonAppKey(String? appKey) async {
    await box.write("cus_baidu_app_key", appKey);
  }

  String? getBaiduCommonAppKey() => box.read("cus_baidu_app_key");

  /// 腾讯的id和key
  Future<void> setTencentCommonAppId(String? appId) async {
    await box.write("cus_tencent_app_id", appId);
  }

  String? getTencentCommonAppId() => box.read("cus_tencent_app_id");

  Future<void> setTencentCommonAppKey(String? appKey) async {
    await box.write("cus_tencent_app_key", appKey);
  }

  String? getTencentCommonAppKey() => box.read("cus_tencent_app_key");
}
