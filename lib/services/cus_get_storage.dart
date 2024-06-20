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
}
