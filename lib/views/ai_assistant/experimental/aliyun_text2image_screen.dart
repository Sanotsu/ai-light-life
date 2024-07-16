// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../apis/aliyun_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/db_tools/db_helper.dart';
import '../../../models/ai_interface_state/aliyun_text2image_state.dart';
import '../../../models/llm_text2image_state.dart';
import '../../accounting/mock_data/index.dart';

class AliyunText2ImageScreen extends StatefulWidget {
  const AliyunText2ImageScreen({super.key});

  @override
  State createState() => _AliyunText2ImageScreenState();
}

class _AliyunText2ImageScreenState extends State<AliyunText2ImageScreen>
    with WidgetsBindingObserver {
  final DBHelper _dbHelper = DBHelper();

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

  // 最近对话需要的记录历史对话的变量
  List<TextToImageResult> text2ImageHsitory = [];

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
          color: Colors.black.withOpacity(0.8),
          child: const Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text("图片生成中……"),
                Text("请勿退出当前页面"),
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

    print("job报错:$jobResp");

    // 构建文生图任务报错
    if (jobResp.code != null) {
      setState(() {
        isGenImage = false;
        _removeLoadingOverlay();
      });
      return commonExceptionDialog(
        // ignore: use_build_context_synchronously
        context,
        "发生异常",
        "生成图片出错:${jobResp.message}\n可以检查一下应用ID和KEY是否正确。",
      );
    }

    // 得到任务编号之后，查询状态
    var taskId = jobResp.output?.taskId;

    if (taskId != null) {
      // 获取到任务编号之后，定时查看任务进行状态
      AliyunTextToImgResp? rst = await timedText2ImageJobStatus(taskId);

      // 查询文生图任务进度报错
      if (rst?.code != null) {
        setState(() {
          isGenImage = false;
          _removeLoadingOverlay();
        });
        return commonExceptionDialog(
          // ignore: use_build_context_synchronously
          context,
          "发生异常",
          "查询文本生图任务进度报错:${jobResp.message}\n可以检查一下应用ID和KEY是否正确。",
        );
      }

      // 任务处理完成之后，放到结果列表中显示
      var a = rst?.output?.results;
      List<String> imageUrls = [];

      if (a != null && a.isNotEmpty) {
        for (var e in a) {
          if (e.url != null) imageUrls.add(e.url!);
        }
      }

      // 将任务结果存入数据库中
      await _dbHelper.insertTextToImageResultList([
        TextToImageResult(
          requestId: jobResp.requestId ?? "无",
          prompt: prompt,
          negativePrompt: negativePrompt,
          style: "<${styles.values.toList()[_selectedStyleIndex]}>",
          imageUrls: imageUrls,
          gmtCreate: DateTime.now(),
        )
      ]);

      // 移除遮罩
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
      rstImageUrls = aliyunText2ImageUrls;
      isGenImage = false;
      _removeLoadingOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '文本生图(通义万相)',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.history, size: 24.sp),
                onPressed: () async {
                  // 获取历史记录
                  var a = await _dbHelper.queryTextToImageResultList();

                  setState(() {
                    text2ImageHsitory = a;
                  });

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 执行按钮
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
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            SizedBox(
              // 调整DrawerHeader的高度
              height: 60.sp,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.lightGreen[100]),
                child: const Center(child: Text('文本生成图片记录')),
              ),
            ),
            ...(text2ImageHsitory.map((e) => buildGestureItems(e)).toList()),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  /// 构建在对话历史中的对话标题列表
  buildGestureItems(TextToImageResult e) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();

        // 点击了指定文生图记录，弹窗显示缩略图
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("文本生成图片信息", style: TextStyle(fontSize: 18.sp)),
              content: SizedBox(
                height: 300.sp,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "正向提示词:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.prompt,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      const Text(
                        "反向提示词:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.negativePrompt ?? "无",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      Divider(height: 5.sp),

                      /// 点击按钮去浏览器下载查看
                      Wrap(
                        children: List.generate(
                          e.imageUrls?.length ?? 0,
                          (index) => ElevatedButton(
                            // 假设url一定存在的
                            onPressed: () => _launchUrl(e.imageUrls![index]),
                            child: Text('图片${index + 1}'),
                          ),
                        ).toList(),
                      ),

                      /// 图片预览，点击可放大，长按保存到相册
                      /// 2024-06-27 ??? 为什么Z60U上不行？？
                      if (e.imageUrls != null && e.imageUrls!.isNotEmpty)
                        Wrap(
                          children: buildImageList(
                            e.style,
                            e.imageUrls!,
                            context,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 5.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${e.requestId.substring(0, 6)} ${e.prompt.length > 10 ? e.prompt.substring(0, 10) : e.prompt}",
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "创建时间:${e.gmtCreate} \n过期时间:${e.gmtCreate.add(const Duration(days: 1))}",
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
            _buildDeleteBotton(e),
          ],
        ),
      ),
    );
  }

  _buildDeleteBotton(TextToImageResult e) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("确认删除文生图记录:", style: TextStyle(fontSize: 18.sp)),
                content: Text("记录请求编号：\n${e.requestId}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              // 先删除
              await _dbHelper.deleteTextToImageResultById(e.requestId);

              // 然后重新查询并更新
              var b = await _dbHelper.queryTextToImageResultList();
              setState(() {
                text2ImageHsitory = b;
              });
            }
          });
        },
        icon: Icon(
          Icons.delete,
          size: 16.sp,
          color: Theme.of(context).primaryColor,
        ),
        iconSize: 18.sp,
        padding: EdgeInsets.all(0.sp),
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
          child: const Text("还原配置"),
        ),
        ElevatedButton(
          onPressed: prompt.isNotEmpty
              ? () async {
                  FocusScope.of(context).unfocus();

                  // 实际请求
                  await getText2ImageData();

                  // 模拟请求
                  // await mockGetUrl();
                }
              : null,
          child: const Text(
            "生成图片",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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

          /// 正向提示词
          _buildPromptHint(),

          /// 消极提示词
          _buildNegativePromptHint(),
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
                child: buildNetworkImageViewGrid(
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
              hintText: '描述画面的提示词信息。支持中英文，不超过500个字符。\n比如：“一只展翅翱翔的狸花猫”',
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
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            // 图片加载失败时的回退处理
            return Container(color: Colors.grey.shade300);
          },
        ),
      ),
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
      ),
    ],
  );
}
