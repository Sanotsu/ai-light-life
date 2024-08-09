// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/utils/tools.dart';
import '../../../models/llm_spec/cc_llm_spec_free.dart';
import '../../../services/cus_get_storage.dart';
import 'aliyun_qwenvl_screen.dart';
import 'baidu_image2text_screen.dart';
import 'aliyun_text2image_screen.dart';

class AgiLlmSample extends StatefulWidget {
  const AgiLlmSample({super.key});

  @override
  State createState() => _AgiLlmSampleState();
}

class _AgiLlmSampleState extends State<AgiLlmSample> {
  // 表单的全局key
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  // 是否用户有配置通用平台的appid和key
  bool isBaiduConfigured = false;
  bool isAliyunConfigured = false;
  bool isTencentConfigured = false;

  // 不明说的东西：长按“智能助手”这标题，使用我自己的三个平台的应用id和key
  bool isAuthorsAppInfo = false;

  String note = """暂仅使用百度千帆、阿里百炼、腾讯混元3个平台。  
  以免费和测试为目的，支持使用的大模型数量有限。

---

**文本对话(官方免费)**  
文本翻译、百科问答、情感分析、FAQ、阅读理解、内容创作、代码编写……。

---*以下需要配置对应平台自己的应用ID和KEY*---    

**文本对话(单个配置)**    
使用更加高级的对话模型，需要用户自己的ID和KEY。  
**文本生图** *(阿里百炼：通义万相)*  
简单的几句话，就能帮你生成各种风格的图片。  
**图像理解** *(百度千帆第三方：Fuyu-8B)*    
给它一张图，它能回答你关于该图片的相关问题。  

---

**点击**下面指定功能，快来试一试吧！""";

  @override
  initState() {
    super.initState();
    checkPlatformConfig();
  }

  checkPlatformConfig() {
    // 是否使用作者的应用配置
    setState(() {
      isAuthorsAppInfo = MyGetStorage().getIsAuthorsAppInfo();
    });

    if (MyGetStorage().getBaiduCommonAppId() != null &&
        MyGetStorage().getBaiduCommonAppKey() != null) {
      setState(() {
        isBaiduConfigured = true;
      });
    } else {
      setState(() {
        isBaiduConfigured = false;
      });
    }

    if (MyGetStorage().getAliyunCommonAppId() != null &&
        MyGetStorage().getAliyunCommonAppKey() != null) {
      setState(() {
        isAliyunConfigured = true;
      });
    } else {
      setState(() {
        isAliyunConfigured = false;
      });
    }

    if (MyGetStorage().getTencentCommonAppId() != null &&
        MyGetStorage().getTencentCommonAppKey() != null) {
      setState(() {
        isTencentConfigured = true;
      });
    } else {
      setState(() {
        isTencentConfigured = false;
      });
    }

    print(
        "检查后的bat配置与否:$isBaiduConfigured $isAliyunConfigured $isTencentConfigured");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () async {
            // 长按之后，先改变是否使用作者应用的标志
            setState(() {
              isAuthorsAppInfo = !isAuthorsAppInfo;
            });

            // 改变后是true，则需要使用作者的平台应用配置
            if (isAuthorsAppInfo) {
              await setDefaultAppIdAndKey();

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              showSnackMessage(context, "你将使用作者的应用ID和KEY，请谨慎！");
            } else {
              //  不然就是清除使用作者的平台应用配置
              await clearAllAppIdAndKey();

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              showSnackMessage(context, "你将不再使用作者的平台应用配置，感谢！");
            }

            // 配置完成，需要检查当前的应用配置，并切换是否使用为相反的值
            await MyGetStorage().setIsAuthorsAppInfo(isAuthorsAppInfo);
            setState(() {
              checkPlatformConfig();
            });
          },
          child: RichText(
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            text: TextSpan(
              children: [
                // 为了分类占的宽度一致才用的，只是显示的话可不必
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 50.sp),
                    child: const Text('智能助手'),
                  ),
                ),
                // TextSpan(
                //   text: "  (Simple AGI LLMs)",
                //   style: TextStyle(color: Colors.black, fontSize: 15.sp),
                // ),
              ],
            ),
          ),
        ),
        // title: const Text('智能对话'),
        actions: [
          TextButton(
            // 如果在缓存中存在配置，则跳到到对话页面，如果没有，进入配置页面
            onPressed: () {
              buildUserAppInfoDialog();
            },
            child: const Text("应用配置"),
          ),
          TextButton(
            // 如果在缓存中存在配置，则跳到到对话页面，如果没有，进入配置页面
            onPressed: () async {
              // 清除配置，且不管如何都重置是否使用作者配置为false
              await clearAllAppIdAndKey();
              MyGetStorage().setIsAuthorsAppInfo(false);

              setState(() {
                checkPlatformConfig();
              });

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              commonHintDialog(context, "清除配置", "平台应用配置已全部清除");
            },
            child: const Text("清除配置"),
          ),
          // TextButton(
          //   // 如果在缓存中存在配置，则跳到到对话页面，如果没有，进入配置页面
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const UserCusModelStepper(),
          //       ),
          //     );
          //   },
          //   child: const Text("自行配置"),
          // ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 显示说明
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(10.sp),
                  child: MarkdownBody(data: note),
                ),
              ),
            ),
          ),
          Divider(height: 50.sp),
          // 入口按钮
          SizedBox(
            height: 0.32.sh,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              crossAxisCount: 2,
              childAspectRatio: 5 / 2,
              children: <Widget>[
                buildAIToolEntrance(0, "文本对话", "通用—官方免费",
                    color: Colors.blue[100]),
                // 2024-06-24 如果使用作者的平台应用配置，那可以使用作者的限量测试的api
                isAuthorsAppInfo
                    ? buildAIToolEntrance(1, "文本对话", "阿里—限量测试",
                        color: Colors.blue[100])
                    : buildAIToolEntrance(5, "文本对话", "通用—单个配置",
                        color: Colors.blue[100]),
                // Container(),
                buildAIToolEntrance(2, "文本生图", "阿里—通义万相",
                    color: Colors.grey[100]),
                buildAIToolEntrance(3, "图像理解", "百度—Fuyu-8B",
                    color: Colors.green[100]),
                // 2024-06-24 这个API调用不符合文档的设定？？？
                // buildAIToolEntrance(4, "视觉模型", "阿里—通义千问",
                //     color: Colors.green[100]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户自己的应用信息
  buildUserAppInfoDialog() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("平台应用配置", style: TextStyle(fontSize: 18.sp)),
          content: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(0.sp),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FormBuilderDropdown<FreeCP>(
                      name: 'platform',
                      validator: FormBuilderValidators.compose(
                          [FormBuilderValidators.required()]),
                      decoration: const InputDecoration(
                        labelText: '平台',
                        // 设置透明底色
                        filled: true,
                        fillColor: Colors.transparent,
                        // 输入框添加边框
                        border: OutlineInputBorder(
                          // 设置边框圆角
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          // 设置边框颜色和宽度
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                      items: FreeCP.values
                          .where((e) => !e.name.startsWith("limited"))
                          .map((platform) => DropdownMenuItem(
                                alignment: AlignmentDirectional.center,
                                value: platform,
                                child: Text(platform.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        // 找到还没超时的大模型，取第一个作为预设的
                        setState(() {
                          // 找到对应的平台和模型(因为配置的时候是用户下拉选择的，理论上这里一定存在，且只应该有一个)

                          if (val == FreeCP.baidu) {
                            // 初始化id或者key
                            _formKey.currentState?.fields['id']?.didChange(
                                MyGetStorage().getBaiduCommonAppId());
                            _formKey.currentState?.fields['key']?.didChange(
                                MyGetStorage().getBaiduCommonAppKey());
                          }
                          if (val == FreeCP.aliyun) {
                            // 初始化id或者key
                            _formKey.currentState?.fields['id']?.didChange(
                                MyGetStorage().getAliyunCommonAppId());
                            _formKey.currentState?.fields['key']?.didChange(
                                MyGetStorage().getAliyunCommonAppKey());
                          }
                          if (val == FreeCP.tencent) {
                            // 初始化id或者key
                            _formKey.currentState?.fields['id']?.didChange(
                                MyGetStorage().getTencentCommonAppId());
                            _formKey.currentState?.fields['key']?.didChange(
                                MyGetStorage().getTencentCommonAppKey());
                          }
                        });
                      },
                      valueTransformer: (val) => val?.toString(),
                    ),
                    SizedBox(height: 10.sp),
                    FormBuilderTextField(
                      name: 'id',
                      decoration: const InputDecoration(
                        labelText: '应用ID',
                        // 设置透明底色
                        filled: true,
                        fillColor: Colors.transparent,
                        // 输入框添加边框
                        border: OutlineInputBorder(
                          // 设置边框圆角
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          // 设置边框颜色和宽度
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          print("输入的id---$val");
                        });
                      },
                      enableSuggestions: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                      // textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 10.sp),
                    FormBuilderTextField(
                      name: 'key',
                      decoration: const InputDecoration(
                        labelText: '应用KEY',
                        // 设置透明底色
                        filled: true,
                        fillColor: Colors.transparent,
                        // 输入框添加边框
                        border: OutlineInputBorder(
                          // 设置边框圆角
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          // 设置边框颜色和宽度
                          borderSide:
                              BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          print("输入的key---$val");
                        });
                      },
                      enableSuggestions: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        if (_formKey.currentState!.saveAndValidate()) {
          var temp = _formKey.currentState;

          FreeCP cp = temp?.fields['platform']?.value;
          String id = temp?.fields['id']?.value;
          String key = temp?.fields['key']?.value;

          await setIdAndKeyFromPlatform(cp, id, key);

          print("cp---------------$cp");

          setState(() {
            checkPlatformConfig();
          });
        }
      }
    });
  }

  /// 构建AI对话云平台入口按钮
  buildAIToolEntrance(int type, String label, String subtitle, {Color? color}) {
    return InkWell(
      onTap: () {
        // 0, "智能对话-免费"
        // 1, "智能对话-限量
        // 2, "文本生图
        // 3, "图像理解
        // 4, "千问视觉
        // 5, 自行配置单个付费对话模型
        if (type == 2) {
          if (isAliyunConfigured) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AliyunText2ImageScreen(),
              ),
            );
          } else {
            commonHintDialog(context, "配置错误", "未配置阿里云平台的应用ID和KEY");
          }
        } else if (type == 3) {
          if (isBaiduConfigured) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BaiduImage2TextScreen(),
              ),
            );
          } else {
            commonHintDialog(context, "配置错误", "未配置百度云平台的应用ID和KEY");
          }
        } else if (type == 4) {
          if (isAliyunConfigured) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AliyunQwenVLScreen(),
              ),
            );
          } else {
            commonHintDialog(context, "配置错误", "未配置阿里云平台的应用ID和KEY");
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          // 设置圆角半径为10
          borderRadius: BorderRadius.all(Radius.circular(15.sp)),
          color: color ?? Colors.teal[200],
          // 添加阴影效果
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // 阴影颜色
              spreadRadius: 2, // 阴影的大小
              blurRadius: 5, // 阴影的模糊程度
              offset: Offset(0, 2.sp), // 阴影的偏移量
            ),
          ],
        ),
        child: Center(
          child: RichText(
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                // 为了分类占的宽度一致才用的，只是显示的话可不必
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 50.sp),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: "\n$subtitle",
                  style: TextStyle(color: Colors.black, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          //  Text(
          //   label,
          //   style: TextStyle(
          //     fontSize: 15.sp,
          //     fontWeight: FontWeight.bold,
          //     color: Theme.of(context).primaryColor,
          //   ),
          // ),
        ),
      ),
    );
  }
}
