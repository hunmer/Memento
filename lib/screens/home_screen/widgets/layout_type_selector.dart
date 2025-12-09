import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 布局类型选择器组件
class LayoutTypeSelector extends StatefulWidget {
  final String? initialType;
  final ValueChanged<String> onTypeChanged;
  final String? title;

  const LayoutTypeSelector({
    super.key,
    this.initialType,
    required this.onTypeChanged,
    this.title = '布局类型',
  });

  @override
  State<LayoutTypeSelector> createState() => _LayoutTypeSelectorState();
}

class _LayoutTypeSelectorState extends State<LayoutTypeSelector> {
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'empty';
  }

  @override
  Widget build(BuildContext context) {    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String>(
          title: Text('screens_emptyLayout'.tr),
          subtitle: Text('screens_emptyLayoutDescription'.tr),
          value: 'empty',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
        RadioListTile<String>(
          title: Text('screens_all1x1Widgets'.tr),
          subtitle: Text('screens_all1x1WidgetsDescription'.tr),
          value: '1x1',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
        RadioListTile<String>(
          title: Text('screens_all2x2Widgets'.tr),
          subtitle: Text('screens_all2x2WidgetsDescription'.tr),
          value: '2x2',
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              widget.onTypeChanged(_selectedType);
            });
          },
        ),
      ],
    );
  }
}
