import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
