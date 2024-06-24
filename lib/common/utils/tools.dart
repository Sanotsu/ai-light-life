import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/common_llm_info.dart';
import '../../services/cus_get_storage.dart';
import '../constants.dart';

/// 获取设备的图片访问请求
requestPhotoPermission() async {
  bool isPermissionGranted = false;

  /// 2024-01-12 直接询问存储权限，不给就直接显示退出就好
  // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
  // Permission.photos, Permission.videos or Permission.audio等
  // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
  if (Platform.isAndroid) {
    // 获取设备sdk版本
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt <= 32) {
      PermissionStatus storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        isPermissionGranted = true;
      } else {
        isPermissionGranted = false;
      }
    } else {
      PermissionStatus status = await Permission.photos.request();

      if (status.isGranted) {
        isPermissionGranted = true;
      } else {
        isPermissionGranted = false;
      }
    }
  }
  // ??? 还差其他平台的

  return isPermissionGranted;
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

List<String> mealCates = ["早餐", "早茶", "午餐", "下午茶", "晚餐", "夜宵", "甜点", "主食"];

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
