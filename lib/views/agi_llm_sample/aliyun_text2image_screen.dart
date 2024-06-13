// ignore_for_file: avoid_print

import 'dart:async';
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
import 'package:toggle_switch/toggle_switch.dart';

import '../../apis/aliyun_apis.dart';
import '../../models/ai_interface_state/aliyun_text2image_state.dart';

class AliyunText2ImageScreen extends StatefulWidget {
  const AliyunText2ImageScreen({super.key});

  @override
  State createState() => _AliyunText2ImageScreenState();
}

class _AliyunText2ImageScreenState extends State<AliyunText2ImageScreen>
    with WidgetsBindingObserver {
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String prompt = "";
  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String negativePrompt = "";

  // 可选的图片风格
  Map<String, String> styles = {
    "默认": 'auto',
    "3D卡通": '3d cartoon',
    "动画": 'anime',
    "油画": 'oil painting',
    "水彩": 'watercolor',
    "素描": 'sketch',
    "中国画": 'chinese painting',
    "扁平插画": 'flat illustration',
  };
  // 选定的风格对应的预览本地图片
  List<String> styleImages = [
    'assets/text2image_styles/默认.jpg',
    'assets/text2image_styles/3D卡通.jpg',
    'assets/text2image_styles/动画.jpg',
    'assets/text2image_styles/油画.jpg',
    'assets/text2image_styles/水彩.jpg',
    'assets/text2image_styles/素描.jpg',
    'assets/text2image_styles/中国画.jpg',
    'assets/text2image_styles/扁平插画.jpg',
  ];

// 初始化为0，表示第一个样式被选中
  int _selectedStyleIndex = 0;
  // 预设的尺寸列表
  final sizeList = ['1024*1024', '720*1280', '1280*720'];
  // 被选中的尺寸索引
  int selectedSizeIndex = 0;
  // 预设的张数列表
  final numSize = [1, 2, 3, 4];
  // 被选中生成的图片张数索引
  int selectedNumIndex = 0;

  // 是否正在生成图片
  bool isGenImage = false;

  // 最后生成的图片地址
  List<String> rstImageUrls = [];

  // 添加一个overlay，在生成图片时，禁止用户的其他操作
  OverlayEntry? _overlayEntry;

  // 控制ExpansionTile是否展开的控制器
  final _expansionTileController = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _removeLoadingOverlay();
    }
  }

  /// 添加遮罩
  void _showLoadingOverlay() {
    OverlayState? overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text("图片生成中……"),
              ],
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  /// 移除遮罩
  void _removeLoadingOverlay() {
    _overlayEntry?.remove();
    setState(() {
      _overlayEntry = null;
    });
  }

  /// 获取文生图的数据
  getText2ImageData() async {
    // 如果在生成中，就不要继续生成了
    if (isGenImage) {
      return;
    }

    setState(() {
      isGenImage = true;
      _showLoadingOverlay();
    });

    // 查看现在读取的内容
    print("xxxxxxxxxxxxxxxxxxxxxxxx");

    print("正向词 $prompt");
    print("消极词 $negativePrompt");
    print("样式 <${styles.values.toList()[_selectedStyleIndex]}>");
    print("尺寸 ${sizeList[selectedSizeIndex]}");
    print("张数 ${numSize[selectedNumIndex]}");

    var input = Input(
      prompt: prompt,
      negativePrompt: negativePrompt,
    );

    var parameters = Parameters(
      style: "<${styles.values.toList()[_selectedStyleIndex]}>",
      size: sizeList[selectedSizeIndex],
      n: numSize[selectedNumIndex],
    );

    // 提交生成任务
    var jobResp = await commitAliyunText2ImgJob(input, parameters);
    print("t提交的结果--------------------------");
    print(jobResp);

    // 得到任务编号之后，查询状态
    var taskId = jobResp.output?.taskId;

    if (taskId != null) {
      // 获取到任务编号之后，定时查看任务进行状态
      AliyunTextToImgResp? rst = await timedText2ImageJobStatus(taskId);

      print("最后的结果--------------------------");
      print(rst);

      // 任务处理完成之后，放到结果列表中显示
      var a = rst?.output?.results;
      List<String> imageUrls = [];

      if (a != null && a.isNotEmpty) {
        for (var e in a) {
          if (e.url != null) imageUrls.add(e.url!);
        }
      }

      setState(() {
        rstImageUrls = imageUrls;
        isGenImage = false;
        _removeLoadingOverlay();
      });
    } else {
      // ？？？没有任务编号，应该是哪里报错了，应该要处理！！！
      setState(() {
        isGenImage = false;
        _removeLoadingOverlay();
      });
    }
  }

  // 定时检查文生图任务的状态
  Future<AliyunTextToImgResp?> timedText2ImageJobStatus(String taskId) async {
    // 是否超时了
    bool isMaxWaitTimeExceeded = false;

    const maxWaitDuration = Duration(minutes: 10); // 设置最大等待时间为10分钟

    // 超时之后会报错，所以就会跳出下面的while循环
    Timer timer = Timer(maxWaitDuration, () {
      print('Max wait time exceeded. Stopping requests.');
      // 在这里可以执行一些清理工作，比如取消其他请求
      // 10分钟还没有得到结果，取消遮罩，弹窗报错
      setState(() {
        isGenImage = false;
        _removeLoadingOverlay();
      });

      EasyLoading.showError(
        "生成图片超时，请稍候重试！",
        duration: const Duration(seconds: 10),
      );

      // 超时了要修改超时标识，以便退出while循环
      isMaxWaitTimeExceeded = true;

      print('Job wait time exceeded. Terminated...');
    });

    // 10分钟定时内，循环获取文生图任务的状态；超过10分钟则超时跳出循环
    bool isRequestSuccessful = false;
    while (!isRequestSuccessful && !isMaxWaitTimeExceeded) {
      try {
        var result = await getAliyunText2ImgJobResult(taskId);

        var boolFlag = result.output?.taskStatus == "SUCCEEDED" ||
            result.output?.taskStatus == "FAILED";

        if (boolFlag) {
          isRequestSuccessful = true;
          print('Request successful!');
          timer.cancel(); // 请求成功，取消定时器

          return result;
        } else {
          print('Job still running. Retrying...');
          // 如果请求失败，等待一段时间后重试
          await Future.delayed(const Duration(seconds: 5)); // 这里设置重试间隔为5秒
        }
      } catch (e) {
        // 处理其他可能的异常
        print('An error occurred: $e');
        await Future.delayed(const Duration(seconds: 5)); // 发生异常时也等待一段时间再重试
      }
    }
    return null;
  }

  /// 节约请求资源，测试就模拟加载图片
  mockGetUrl() async {
    print('mockGetUrl $isGenImage');

    // 如果在生成中，就不要继续生成了
    if (isGenImage) {
      return;
    }

    setState(() {
      isGenImage = true;
      _showLoadingOverlay();
    });

    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      // 过期时间可能是一天
      rstImageUrls = [
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/3b/20240612/522176a8/7d14f071-f31c-4085-ad77-db60b1307282-1.png?Expires=1718247586&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=5n8biAg1alMrRR0JemdxeHhrN8w%3D",
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/8b/20240612/522176a8/0c8973ed-3865-4628-b55d-71c838e51092-1.png?Expires=1718247586&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=IYwwkPED3XeYm%2FHLQP3dsKRc448%3D",
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/94/20240612/522176a8/871d4009-24cd-490f-802f-17326f4fc774-1.png?Expires=1718263056&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=xFVg%2BFhgIom74JvxQ6h6SLtKqzs%3D",
        "https://dashscope-result-sh.oss-cn-shanghai.aliyuncs.com/1d/96/20240612/1b61f1c0/90ca6b45-6e70-4755-8ab1-3b9f298a29e6-1.png?Expires=1718263794&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=XgLfyZWcO8hKG%2BgOHPajTo%2B17hU%3D",
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/85/20240612/522176a8/b0056938-0aef-451e-871e-efcbf900e741-1.png?Expires=1718263794&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=H2Q34TYygkkmAoxmutnNpuGU0mg%3D",
        "https://dashscope-result-sh.oss-cn-shanghai.aliyuncs.com/1d/87/20240612/1b61f1c0/18ded425-eba6-477a-9141-bf6e263cd355-1.png?Expires=1718263794&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=vrpEVY6eChP8M3DS9NSauC4USWU%3D",
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/81/20240612/522176a8/236ad21f-8e2b-435b-b488-9377615f2da3-1.png?Expires=1718280633&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=t4mITLm169UWvxWa6acWLEBjbgs%3D",
        "https://dashscope-result-sh.oss-cn-shanghai.aliyuncs.com/1d/e9/20240613/1b61f1c0/38439ec0-cc66-42a8-a2c6-45a3d3ba7162-1.png?Expires=1718332753&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=9WoaCavRSvctaQc7uO1pZIgPJJ4%3D",
        "https://dashscope-result-sh.oss-cn-shanghai.aliyuncs.com/1d/eb/20240613/1b61f1c0/134c1b5b-09ea-40f2-9464-bb705e25b0fd-1.png?Expires=1718333128&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=4sCQJSs0RIf8hZsNEcOa5zGkw8c%3D",
        "https://dashscope-result-hz.oss-cn-hangzhou.aliyuncs.com/1d/51/20240613/522176a8/11a9d0b3-3c76-4d5f-91c9-b3f6d9087bd5-1.png?Expires=1718334452&OSSAccessKeyId=LTAI5tQZd8AEcZX6KZV4G8qL&Signature=IPXbq2FnFhzPts8s%2FZFgDYbAjZg%3D",
      ];
      isGenImage = false;
      _removeLoadingOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI文本生成图像'),
        actions: [
          TextButton(
            onPressed: () {
              var taskId = "4975f6a4-373d-4996-bbd8-e0cbc57dd89a";

              getAliyunText2ImgJobResult(taskId);
            },
            child: const Text("测试任务"),
          )
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// 执行按钮
          // buildText2ImageButtonArea(),
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "文生图配置",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                buildText2ImageButtonArea(),
              ],
            ),
          ),

          /// 文生图配置折叠栏
          Expanded(flex: 2, child: buildConfigArea()),

          const Divider(),
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Text(
              "生成的图片(点击查看、长按保存)",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),

          /// 文生图的结果
          buildImageResult(),
          SizedBox(height: 10.sp),
        ],
      ),
    );
  }

  /// 构建文生图配置和执行按钮
  buildText2ImageButtonArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            // 处理编辑按钮的点击事件
            setState(() {
              prompt = "";
              negativePrompt = "";
              _promptController.text = "";
              _negativePromptController.text = "";
              _selectedStyleIndex = 0;
              selectedSizeIndex = 0;
              selectedNumIndex = 0;
            });
          },
          child: const Text("清空配置"),
        ),
        TextButton(
          onPressed: prompt.isNotEmpty
              ? () async {
                  FocusScope.of(context).unfocus();

                  // 实际请求
                  await getText2ImageData();

                  // 如果配置栏是展开的，就折叠起来
                  // setState(() {
                  //   if (_expansionTileController.isExpanded) {
                  //     _expansionTileController.collapse();
                  //   }
                  // });

                  // 模拟请求
                  // await mockGetUrl();
                }
              : null,
          child: const Text("生成图片"),
        ),
      ],
    );
  }

  /// 构建文生图的配置折叠栏
  buildConfigArea() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 画风、尺寸、张数选择
          _buildStyleAndNumberSizeArea(),
          // ...buildStyleNumSizeToggleSwitchs(),

          /// 正向提示词
          _buildPromptHint(),

          /// 消极提示词
          _buildNegativePromptHint(),
        ],
      ),
    );
  }

  buildConfigAreaBak() {
    return SingleChildScrollView(
      child: ExpansionTile(
        controller: _expansionTileController,
        initiallyExpanded: true,
        title: const Text('文生图配置'),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 画风、尺寸、张数选择
              _buildStyleAndNumberSizeArea(),
              // ...buildStyleNumSizeToggleSwitchs(),

              /// 正向提示词
              _buildPromptHint(),

              /// 消极提示词
              _buildNegativePromptHint(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建生成的图片区域
  buildImageResult() {
    return SizedBox(
      // 最多4张图片，每张占0.24宽度，高度就预留0.5宽度。在外层Column最下面留点空即可
      height: 0.5.sw,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (rstImageUrls.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.25.sw),
                child: _buildRstImageGrid(
                  styles.keys.toList()[_selectedStyleIndex],
                  rstImageUrls,
                  context,
                ),
              ),
          ],
        ),
      ),
    );
  }
  // buildImageResult() {
  //   return SingleChildScrollView(
  //     child: Column(
  //       children: [
  //         if (rstImageUrls.isNotEmpty)
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 0.25.sw),
  //             child: _buildRstImageGrid(rstImageUrls, context),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  /// 构建画风、尺寸、张数选择区域
  _buildStyleAndNumberSizeArea() {
    return Row(
      children: [
        SizedBox(width: 5.sp),
        SizedBox(width: 0.48.sw, child: _buildImageGrid()),
        SizedBox(width: 5.sp),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("尺寸："),
            Center(
              child: ToggleSwitch(
                minHeight: 32.sp,
                minWidth: 0.47.sw,
                fontSize: 12.sp,
                cornerRadius: 5.sp,
                dividerMargin: 10.sp,
                initialLabelIndex: selectedSizeIndex,
                totalSwitches: 3,
                isVertical: true,
                labels: sizeList,
                // radiusStyle: true,
                onToggle: (index) {
                  setState(() {
                    selectedSizeIndex = index ?? 0;
                  });
                },
              ),
            ),
            SizedBox(height: 2.sp),
            const Text("张数(2毛一张)："),
            Center(
              child: ToggleSwitch(
                minHeight: 32.sp,
                minWidth: 0.115.sw,
                fontSize: 12.sp,
                cornerRadius: 5.sp,
                dividerMargin: 0.sp,
                initialLabelIndex: selectedNumIndex,
                totalSwitches: 4,
                radiusStyle: true,
                multiLineText: true,
                centerText: true,
                labels: numSize.map((e) => "$e张").toList(),
                onToggle: (index) {
                  setState(() {
                    selectedNumIndex = index ?? 0;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 正向提示词输入框
  _buildPromptHint() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("正向提示词(不可为空)", style: TextStyle(color: Colors.green)),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: '描述画面的提示词信息。支持中英文，长度不超过500个字符。',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: const OutlineInputBorder(), // 添加边框
            ),
            maxLines: 5,
            minLines: 3,
            onChanged: (String? text) {
              if (text != null) {
                setState(() {
                  prompt = text.trim();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// 反向提示词输入框
  _buildNegativePromptHint() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("反向提示词(可以不填)"),
          TextField(
            controller: _negativePromptController,
            decoration: InputDecoration(
              hintText:
                  '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化模型输出，使模型产生更有针对性和理想的结果。',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: const OutlineInputBorder(), // 添加边框
            ),
            maxLines: 5,
            minLines: 3,
            onChanged: (String? text) {
              if (text != null) {
                setState(() {
                  negativePrompt = text.trim();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // 全是切换选择框，不好看
  buildStyleNumSizeToggleSwitchs() {
    return [
      // const Text("风格"),
      Center(
        child: ToggleSwitch(
          minHeight: 48.sp,
          minWidth: 45.sp,
          cornerRadius: 5.sp,
          dividerMargin: 0.sp,
          initialLabelIndex: 0,
          totalSwitches: styles.entries.length,
          // radiusStyle: true,
          onToggle: (index) {
            print('switched to: $index');
          },
          // multiLineText: true,
          // centerText: true,
          customWidgets: styles.entries
              .map((e) => Text(
                    e.key,
                    style: TextStyle(fontSize: 10.sp),
                  ))
              .toList(),
        ),
      ),

      /// 大小
      // const Text("size"),
      Divider(height: 5.sp),

      Center(
        child: ToggleSwitch(
          minHeight: 20.sp,
          minWidth: 120.sp,
          fontSize: 10.sp,
          cornerRadius: 5.sp,
          dividerMargin: 0.sp,
          initialLabelIndex: 0,
          totalSwitches: 3,
          labels: const ['1024*1024', '720*1280', '1280*720'],
          // radiusStyle: true,
          onToggle: (index) {
            print('switched to: $index');
          },
        ),
      ),

      /// 张数
      // const Text("张数"),
      Divider(height: 5.sp),

      Center(
        child: ToggleSwitch(
          minHeight: 24.sp,
          minWidth: 90.sp,
          fontSize: 12.sp,
          cornerRadius: 5.sp,
          dividerMargin: 0.sp,
          initialLabelIndex: 0,
          totalSwitches: 4,
          // radiusStyle: true,
          onToggle: (index) {
            print('switched to: $index');
          },
          multiLineText: true,
          centerText: true,
          labels: const ['1张', '2张', '3张', '4张'],
        ),
      ),
    ];
  }

  /// 预设的8种文生图的画风
  _buildImageGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(8, (index) {
        return GridTile(
          child: GestureDetector(
            onTap: () {
              // 切换选中状态
              setState(() {
                _selectedStyleIndex = _selectedStyleIndex == index ? -1 : index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                // 选中的边框为蓝色，没选中则为透明
                border: Border.all(
                  color: _selectedStyleIndex == index
                      ? Colors.blue
                      : Colors.transparent,
                  width: 3.sp,
                ),
                borderRadius: BorderRadius.circular(5.0), // 可选，为图片添加圆角
              ),
              child: _buildImageStack(
                styleImages[index],
                styles.keys.toList()[index],
                styles.values.toList()[index],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 构建图片上显示文本的组件
_buildImageStack(String url, String label, String label1) {
  return Stack(
    fit: StackFit.expand, // 使Stack填满父Widget的空间
    children: [
      // 图片作为背景
      Positioned.fill(
        child: Image.asset(
          url, // 请替换为你的图片路径
          fit: BoxFit.cover, // 使图片覆盖并保持宽高比填充Stack
        ),
      ),
      // Positioned.fill(
      //   child: Image.network(
      //     url,
      //     fit: BoxFit.cover, // 保持图片宽高比并填充Stack
      //     errorBuilder:
      //         (BuildContext context, Object exception, StackTrace? stackTrace) {
      //       // 图片加载失败时的回退处理
      //       return Container(color: Colors.grey.shade300);
      //     },
      //   ),
      // ),
      // 文字覆盖在图片上
      // 文字覆盖在图片上并居中
      Align(
        alignment: Alignment.bottomCenter, // 这里使文字靠底居中
        child: RichText(
          softWrap: true,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  // color: Colors.orange,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: "\n$label1",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),
              ),
            ],
          ),
        ),
        // Text(
        //   label,
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 10.sp,
        //     // fontWeight: FontWeight.bold,
        //   ),
        // ),
      ),
      // Positioned(
      //   bottom: 5.sp, // 文字距离底部的距离
      //   child: Center(
      //     child: Text(
      //       label, // 显示的文本
      //       style: TextStyle(
      //         color: Colors.white, // 文字颜色
      //         fontSize: 10.sp, // 文字大小
      //         fontWeight: FontWeight.bold, // 文字粗细
      //       ),
      //     ),
      //   ),
      // ),
    ],
  );
}

/// 构建生成的图片结果
_buildRstImageGrid(String style, List<String> urls, BuildContext context) {
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
                EasyLoading.showToast("Android9 及以下版本无法长按保存到相册！");
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

          // Image.network(
          //   urls[index],
          //   fit: BoxFit.cover,
          // ),
        ),
      );
    }),
  );
}
