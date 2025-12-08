import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Column(
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
          title: const Text('空白布局'),
          subtitle: const Text('不包含任何小组件的空白布局'),
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
          title: const Text('所有 1x1 小组件'),
          subtitle: const Text('添加所有支持 1x1 尺寸的小组件'),
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
          title: const Text('所有 2x2 小组件'),
          subtitle: const Text('添加所有支持 2x2 尺寸的小组件'),
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
