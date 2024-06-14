// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photo_view/photo_view.dart';

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  } else {
    return Container();
  }
}

commonHintDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// 构建文本生成的图片结果列表
/// 点击预览，长按下载
buildNetworkImageViewGrid(
  String style,
  List<String> urls,
  BuildContext context,
) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    mainAxisSpacing: 5.sp,
    crossAxisSpacing: 5.sp,
    physics: const NeverScrollableScrollPhysics(),
    children: List.generate(urls.length, (index) {
      return GridTile(
        child: GestureDetector(
          // 单击预览
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.transparent, // 设置背景透明
                  child: PhotoView(
                    imageProvider: NetworkImage(urls[index]),
                    // 设置图片背景为透明
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    // 可以旋转
                    // enableRotation: true,
                    // 缩放的最大最小限制
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  ),
                );
              },
            );
          },
          // 长按保存到相册
          onLongPress: () async {
            if (Platform.isAndroid) {
              final deviceInfoPlugin = DeviceInfoPlugin();
              final deviceInfo = await deviceInfoPlugin.androidInfo;
              final sdkInt = deviceInfo.version.sdkInt;

              // Android9对应sdk是28,<=28就不显示保存按钮
              if (sdkInt > 28) {
                // 点击预览或者下载
                var response = await Dio().get(urls[index],
                    options: Options(responseType: ResponseType.bytes));

                print(response.data);

                // 安卓9及以下好像无法保存
                final result = await ImageGallerySaver.saveImage(
                  Uint8List.fromList(response.data),
                  quality: 100,
                  name: "${style}_${DateTime.now().millisecondsSinceEpoch}",
                );
                if (result["isSuccess"] == true) {
                  EasyLoading.showToast("图片已保存到相册！");
                } else {
                  EasyLoading.showToast("无法保存图片！");
                }
              } else {
                EasyLoading.showToast("Android 9 及以下版本无法长按保存到相册！");
              }
            }
          },
          // 默认缓存展示
          child: CachedNetworkImage(
            imageUrl: urls[index],
            fit: BoxFit.cover,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
              child: SizedBox(
                height: 50.sp,
                width: 50.sp,
                child: CircularProgressIndicator(
                  value: downloadProgress.progress,
                ),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      );
    }),
  );
}

/// 构建图片预览，可点击放大
/// 注意限定传入的图片类型，要在这些条件之中
Widget buildImageView(dynamic image, BuildContext context) {
  // 如果没有图片数据，直接返回文提示
  if (image == null) {
    return const Center(
      child: Text(
        '请选择图片',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  print("显示的图片类型---${image.runtimeType == File}-${image.runtimeType} -$image");

  ImageProvider imageProvider;
  // 只有base64的字符串或者文件格式
  if (image.runtimeType == String) {
    imageProvider = MemoryImage(base64Decode(image));
  } else {
    // 如果直接传文件，那就是文件
    imageProvider = FileImage(image);
  }

  return GridTile(
    child: GestureDetector(
      // 单击预览
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: imageProvider,
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                // enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                errorBuilder: (context, url, error) => const Icon(Icons.error),
              ),
            );
          },
        );
      },
      // 默认显示文件图片
      child: RepaintBoundary(
        child: Center(
          child: Image(image: imageProvider, fit: BoxFit.scaleDown),
        ),
      ),
    ),
  );
}
