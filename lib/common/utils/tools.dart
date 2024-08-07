import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../apis/_self_keys.dart';
import '../../models/common_llm_info.dart';
import '../../services/cus_get_storage.dart';
import '../constants.dart';

/// 请求各种权限
/// 目前存储类的权限要分安卓版本，所以单独处理
/// 查询安卓媒体存储权限和其他权限不能同时进行
Future<bool> requestPermission({
  bool isAndroidMedia = true,
  List<Permission>? list,
}) async {
  // 如果是请求媒体权限
  if (isAndroidMedia) {
    // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
    // Permission.photos, Permission.videos or Permission.audio等
    // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
    if (Platform.isAndroid) {
      // 获取设备sdk版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        PermissionStatus storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.audio,
          Permission.photos,
          Permission.videos,
          Permission.manageExternalStorage,
        ].request();

        return (statuses[Permission.audio]!.isGranted &&
            statuses[Permission.photos]!.isGranted &&
            statuses[Permission.videos]!.isGranted &&
            statuses[Permission.manageExternalStorage]!.isGranted);
      }
    } else if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.mediaLibrary,
        Permission.storage,
      ].request();
      return (statuses[Permission.mediaLibrary]!.isGranted &&
          statuses[Permission.storage]!.isGranted);
    }
    // ??? 还差其他平台的
  }

  // 如果有其他权限需要访问，则一一处理(没有传需要请求的权限，就直接返回成功)
  list = list ?? [];
  if (list.isEmpty) {
    return true;
  }
  Map<Permission, PermissionStatus> statuses = await list.request();
  // 如果每一个都授权了，那就返回授权了
  return list.every((p) => statuses[p]!.isGranted);
}

// 根据数据库拼接的字符串值转回对应选项
List<CusLabel> genSelectedCusLabelOptions(
  String? optionsStr,
  List<CusLabel> cusLabelOptions,
) {
  // 如果为空或者空字符串，返回空列表
  if (optionsStr == null || optionsStr.isEmpty || optionsStr.trim().isEmpty) {
    return [];
  }

  List<String> selectedValues = optionsStr.split(',');
  List<CusLabel> selectedLabels = [];

  for (String selectedValue in selectedValues) {
    for (CusLabel option in cusLabelOptions) {
      if (option.value == selectedValue) {
        selectedLabels.add(option);
      }
    }
  }

  return selectedLabels;
}

String getTimePeriod() {
  DateTime now = DateTime.now();
  if (now.hour >= 0 && now.hour < 9) {
    return '早餐';
  } else if (now.hour >= 9 && now.hour < 11) {
    return '早茶';
  } else if (now.hour >= 11 && now.hour < 14) {
    return '午餐';
  } else if (now.hour >= 14 && now.hour < 16) {
    return '下午茶';
  } else if (now.hour >= 16 && now.hour < 20) {
    return '晚餐';
  } else {
    return '夜宵';
  }
}

// 保存指定平台应用配置的id和key
setIdAndKeyFromPlatform(CloudPlatform cp, String? id, String? key) async {
  if (cp == CloudPlatform.baidu) {
    await MyGetStorage().setBaiduCommonAppId(id);
    await MyGetStorage().setBaiduCommonAppKey(key);
  } else if (cp == CloudPlatform.aliyun) {
    await MyGetStorage().setAliyunCommonAppId(id);
    await MyGetStorage().setAliyunCommonAppKey(key);
  } else {
    await MyGetStorage().setTencentCommonAppId(id);
    await MyGetStorage().setTencentCommonAppKey(key);
  }
}

// 通过传入的平台，获取该平台应用配置的id和key
Map<String, String?> getIdAndKeyFromPlatform(CloudPlatform cp) {
  String? id;
  String? key;

  if (cp == CloudPlatform.baidu) {
    // 初始化id或者key
    id = MyGetStorage().getBaiduCommonAppId();
    key = MyGetStorage().getBaiduCommonAppKey();
  } else if (cp == CloudPlatform.aliyun) {
    id = MyGetStorage().getAliyunCommonAppId();
    key = MyGetStorage().getAliyunCommonAppKey();
  } else {
    id = MyGetStorage().getTencentCommonAppId();
    key = MyGetStorage().getTencentCommonAppKey();
  }
  return {"id": id, "key": key};
}

// 设置私人的平台应用id和key
setDefaultAppIdAndKey() async {
  await MyGetStorage().setBaiduCommonAppId(BAIDU_API_KEY);
  await MyGetStorage().setBaiduCommonAppKey(BAIDU_SECRET_KEY);
  await MyGetStorage().setAliyunCommonAppId(ALIYUN_APP_ID);
  await MyGetStorage().setAliyunCommonAppKey(ALIYUN_API_KEY);
  await MyGetStorage().setTencentCommonAppId(TENCENT_SECRET_ID);
  await MyGetStorage().setTencentCommonAppKey(TENCENT_SECRET_KEY);
}

// 清除设定好的平台应用id和key
clearAllAppIdAndKey() async {
  await MyGetStorage().setBaiduCommonAppId(null);
  await MyGetStorage().setBaiduCommonAppKey(null);
  await MyGetStorage().setAliyunCommonAppId(null);
  await MyGetStorage().setAliyunCommonAppKey(null);
  await MyGetStorage().setTencentCommonAppId(null);
  await MyGetStorage().setTencentCommonAppKey(null);
}
