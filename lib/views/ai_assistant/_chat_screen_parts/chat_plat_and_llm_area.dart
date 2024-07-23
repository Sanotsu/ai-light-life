import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../common/components/tool_widget.dart';
import '../../../models/common_llm_info.dart';
import '../../../models/paid_llm/common_chat_model_spec.dart';

///
/// 构建平台和模型的下拉选择框
///
/// 因为平台可能是ApiPlatform/CloudPlatform，模型可能是CCM/PlatformLLM，所以需要泛型
/// 有的不存在流式切换，所以toggle也是可选
///
class PlatAndLlmRow<T, U> extends StatefulWidget {
  // 被选中的平台
  final T? selectedPlatform;
  // 当平台改变时触发
  final Function(T?) onCloudPlatformChanged;
  // 被选中的模型
  final U? selectedLlm;
  // 当模型改变时触发
  final Function(U?) onLlmChanged;
  // 在此组件内部构造平台下拉框和模型下拉框选项麻烦了点，直接当参数传入
  final List<DropdownMenuItem<T?>> Function() buildCloudPlatforms;
  final List<DropdownMenuItem<U?>> Function() buildPlatformLLMs;

  // 模型的说明列表
  // 不是Map<PlatformLLM, ChatLLMSpec> 就是 Map<CCM, CCMSpec>
  final Map<U, dynamic> specList;

  // 流式响应的部件不一定存在的
  // 是否显示切换按钮
  final bool showToggleSwitch;
  // 是否是流式响应
  final bool? isStream;
  // 是否流式响应切换按钮触发
  final void Function(int?)? onToggle;

  const PlatAndLlmRow({
    Key? key,
    required this.selectedPlatform,
    required this.onCloudPlatformChanged,
    required this.selectedLlm,
    required this.onLlmChanged,
    required this.buildCloudPlatforms,
    required this.buildPlatformLLMs,
    required this.specList,
    this.showToggleSwitch = false,
    this.isStream = false,
    this.onToggle,
  }) : super(key: key);

  @override
  State<PlatAndLlmRow<T, U>> createState() => _PlatAndLlmRowState<T, U>();
}

class _PlatAndLlmRowState<T, U> extends State<PlatAndLlmRow<T, U>> {
  @override
  Widget build(BuildContext context) {
    // ChatLLMSpec 就是 CCMSpec
    var tempSpec = widget.specList[widget.selectedLlm]!;

    Widget cpRow = Row(
      children: [
        const Text("平台:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<T?>(
            value: widget.selectedPlatform,
            isDense: true,
            // icon: Icon(Icons.arrow_drop_down, size: 36.sp), // 自定义图标
            underline: Container(), // 取消默认的下划线
            items: widget.buildCloudPlatforms(),
            onChanged: widget.onCloudPlatformChanged,
          ),
        ),
        if (widget.showToggleSwitch)
          ToggleSwitch(
            minHeight: 26.sp,
            minWidth: 48.sp,
            fontSize: 13.sp,
            cornerRadius: 5.sp,
            initialLabelIndex: widget.isStream == true ? 0 : 1,
            totalSwitches: 2,
            labels: const ['更快', '更省'],
            onToggle: widget.onToggle,
          ),
        if (widget.showToggleSwitch) SizedBox(width: 10.sp),
      ],
    );

    Widget modelRow = Row(
      children: [
        const Text("模型:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<U?>(
            value: widget.selectedLlm,
            isDense: true,
            underline: Container(),
            menuMaxHeight: 300.sp,
            items: widget.buildPlatformLLMs(),
            onChanged: widget.onLlmChanged,
          ),
        ),
        IconButton(
          onPressed: () {
            commonHintDialog(
              context,
              "模型说明",
              (tempSpec.runtimeType == CCMSpec)
                  ? "${(tempSpec as CCMSpec).feature ?? ""}\n\n${tempSpec.useCase ?? ""}"
                  : (tempSpec as ChatLLMSpec).spec ?? "<暂无规格说明>",
              msgFontSize: 15.sp,
            );
          },
          icon: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [cpRow, modelRow],
      ),
    );
  }
}
