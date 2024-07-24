import 'package:flutter/material.dart';

import '../../../../common/constants.dart';

class CusMultiSelectDialog extends StatefulWidget {
  // 被选中的条目
  final List<CusLabel> selectedItems;
  // 所有的待选条目
  final List<CusLabel> items;
  const CusMultiSelectDialog({
    super.key,
    required this.selectedItems,
    required this.items,
  });

  @override
  State createState() => _CusMultiSelectDialogState();
}

class _CusMultiSelectDialogState extends State<CusMultiSelectDialog> {
  late List<CusLabel> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  void _onItemCheckedChange(CusLabel item, bool checked) {
    setState(() {
      if (checked) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  void _onSubmit() {
    Navigator.of(context).pop(_selectedItems);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('多选'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (BuildContext context, int index) {
            return CheckboxListTile(
              title: Text(widget.items[index].cnLabel),
              value: _selectedItems.contains(widget.items[index]),
              onChanged: (bool? value) {
                _onItemCheckedChange(widget.items[index], value!);
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _onCancel,
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _onSubmit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
