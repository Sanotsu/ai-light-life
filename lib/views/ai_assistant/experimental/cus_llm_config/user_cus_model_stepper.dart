// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/common_llm_info.dart';
import '../../../../services/cus_get_storage.dart';
import '../one_chat_screen.dart';

///
/// 用户自定义模型配置的平台、模型名、appid、appkey
///
class UserCusModelStepper extends StatefulWidget {
  const UserCusModelStepper({super.key});

  @override
  State<UserCusModelStepper> createState() => _UserCusModelStepperState();
}

class _UserCusModelStepperState extends State<UserCusModelStepper> {
  int _index = 0;
  CloudPlatform selectedPlatform = CloudPlatform.baidu;
  PlatformLLM? selectedLLM;

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  initState() {
    super.initState();

    // 因为要在表单渲染成功之后再初始化值
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initUserCOnfigration();
    });
  }

// 如果缓存中已经存在了用户的配置，直接读取出来显示
  initUserCOnfigration() {
    var name = MyGetStorage().getCusLlmName();
    var pf = MyGetStorage().getCusPlatform();

    if (name == null || pf == null) {
      return;
    }
    // 找到还没超时的大模型，取第一个作为预设的
    setState(() {
      // 找到对应的平台和模型(因为配置的时候是用户下拉选择的，理论上这里一定存在，且只应该有一个)
      selectedPlatform =
          CloudPlatform.values.where((e) => e.name == pf).toList().first;

      // 找到平台之后，也要找到对应选中的模型
      selectedLLM = PlatformLLM.values.where((m) => m.name == name).first;

      var map = getIdAndKeyFromPlatform(selectedPlatform);

      // 初始化id或者key
      _formKey.currentState?.fields['id']?.didChange(map['id']);
      _formKey.currentState?.fields['key']?.didChange(map['key']);
    });
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(CloudPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedPlatform = value ?? CloudPlatform.baidu;

      // 找到符合平台的模型（？？？理论上一定不为空，为空了就是有问题的数据）
      // 注意，免费的就不让配置了
      var temp = PlatformLLM.values
          .where((e) =>
              e.name.startsWith(selectedPlatform.name) &&
              !e.name.endsWith("FREE"))
          .toList();

      setState(() {
        selectedLLM = temp.first;
        // 切换平台之后，如果有全局配置的应用id和key，也跟着切换
        var map = getIdAndKeyFromPlatform(selectedPlatform);
        _formKey.currentState?.fields['id']?.didChange(map['id']);
        _formKey.currentState?.fields['key']?.didChange(map['key']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 100.sp,
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text("自行配置平台对话模型", style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          Stepper(
            currentStep: _index,
            onStepCancel: () {
              if (_index > 0) {
                setState(() {
                  _index -= 1;
                });
              }
            },
            onStepContinue: () {
              if (_index <= 0) {
                setState(() {
                  _index += 1;
                });
              }
            },
            onStepTapped: (int index) {
              setState(() {
                _index = index;
              });
            },
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    // 当处于最后一个步骤时，执行自定义操作，否则继续下一步
                    onPressed: (_index == getStepList().length - 1)
                        ? () async {
                            print("这是最后一步，就不会触发上面的onStepContinue定义了");

                            if (_formKey.currentState!.saveAndValidate()) {
                              if (selectedLLM?.name == null) {
                                return commonExceptionDialog(
                                    context, "数据异常", "请选择平台和模型，不可为空");
                              }

                              await MyGetStorage()
                                  .setCusPlatform(selectedPlatform.name);
                              await MyGetStorage()
                                  .setCusLlmName(selectedLLM!.name);

                              var temp = _formKey.currentState;

                              await setIdAndKeyFromPlatform(
                                selectedPlatform,
                                temp?.fields['id']?.value,
                                temp?.fields['key']?.value,
                              );

                              if (!mounted) return;
                              Navigator.pushReplacement(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OneChatScreen(
                                    isUserConfig: true,
                                  ),
                                ),
                              );
                            } else {
                              return commonExceptionDialog(
                                  context, "数据异常", "请检查应用id和key是否输入");
                            }
                          }
                        : details.onStepContinue,

                    // 修改最后一个步骤的按钮文字为 "完成"
                    child: Text(
                      (_index == getStepList().length - 1) ? '完成' : '继续',
                    ),
                  ),
                  TextButton(
                    // 如果是第一步的取消，就返回上一页了(push过来的，pop过去就好)
                    onPressed: (_index == 0)
                        ? () {
                            Navigator.pop(context);
                          }
                        : details.onStepCancel,
                    child: Text((_index == 0) ? '取消' : '上一步'),
                  ),
                ],
              );
            },
            steps: getStepList(),
          )
        ],
      ),
    );
  }

  List<Step> getStepList() {
    return <Step>[
      Step(
        state: (selectedLLM != null) ? StepState.complete : StepState.indexed,
        isActive: _index >= 0,
        title: const Text('选择平台和模型'),
        content: Row(
          children: [
            Expanded(
              flex: 1,
              // 下拉框有个边框，需要放在容器中
              child: Container(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 100.sp,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<CloudPlatform?>(
                      value: selectedPlatform,
                      isDense: true,
                      alignment: AlignmentDirectional.center,
                      items: CloudPlatform.values
                          .where((e) => !e.name.startsWith("limited"))
                          .map((e) {
                        return DropdownMenuItem<CloudPlatform?>(
                          value: e,
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            e.name,
                            style:
                                TextStyle(fontSize: 12.sp, color: Colors.blue),
                          ),
                        );
                      }).toList(),
                      onChanged: onCloudPlatformChanged,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              flex: 2,
              // 下拉框有个边框，需要放在容器中
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<PlatformLLM?>(
                  value: selectedLLM,
                  isDense: true,
                  alignment: AlignmentDirectional.centerEnd,
                  items: PlatformLLM.values
                      .where((m) =>
                          m.name.startsWith(selectedPlatform.name) &&
                          !m.name.endsWith("FREE"))
                      .map((e) => DropdownMenuItem<PlatformLLM>(
                            value: e,
                            alignment: AlignmentDirectional.center,
                            child: Text(
                              newLLMSpecs[e]!.name,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.blue,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedLLM = val!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      Step(
        state: _formKey.currentState?.saveAndValidate() != true
            ? StepState.complete
            : StepState.indexed,
        isActive: _index >= 1,
        title: const Text('输入平台应用ID和KEY'),
        content: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FormBuilderTextField(
                name: 'id',
                decoration: const InputDecoration(
                  labelText: '应用ID',
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onChanged: (val) {
                  setState(() {});
                },
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                // initialValue: '12',
                // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
                // 2024-05-27 9.3.0 版本了还没修
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              FormBuilderTextField(
                name: 'key',
                decoration: const InputDecoration(
                  labelText: '应用KEY',
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onChanged: (val) {
                  setState(() {});
                },
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                // initialValue: '12',
                // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
                // 2024-05-27 9.3.0 版本了还没修
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

// /// 如果是用户自行输入的话，不关心其他限制，就只看平台、模型参数即可
// ///
// enum CusPlatform { baidu, tencent, aliyun }

// class CusChatLLMSpec {
//   // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，到期时间、限量数值，
//   final String name;
//   final String model;
//   // 3个平台开通服务都需要绑定应用，然后都需要提供key和id类似物，叫法可能不太一样
//   // 阿里是APP_ID、API_KEY；百度是API_KEY、SECRET_KEY；腾讯是SECRET_ID、SECRET_KEY
//   // final String secretId;
//   // final String secretKey;

//   CusChatLLMSpec(this.name, this.model);
// }

// Map<CusPlatform, List<CusChatLLMSpec>> supportedCusLLMs = {
//   CusPlatform.baidu: [
//     CusChatLLMSpec("ErnieLite8K", "ernie_speed"),
//     CusChatLLMSpec("ErnieSpeed128K", "ernie-speed-128k"),
//     CusChatLLMSpec("ErnieLite8K", "ernie-lite-8k"),
//     CusChatLLMSpec("ErnieTiny8K", "ernie-tiny-8k"),
//   ],
//   CusPlatform.aliyun: [
//     CusChatLLMSpec("QwenTurbo", "qwen-turbo"),
//     CusChatLLMSpec("QwenPlus", "qwen-plus"),
//     CusChatLLMSpec("QwenLong", "qwen-long"),
//     CusChatLLMSpec("QwenMax", "qwen-max"),
//     CusChatLLMSpec("QwenMaxLongContext", "qwen-max-longcontext"),
//   ],
//   CusPlatform.tencent: [
//     CusChatLLMSpec("HunyuanLite", "hunyuan-lite"),
//   ],
// };
