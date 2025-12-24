import 'package:flutter/material.dart';
import 'package:Memento/widgets/picker/circle_icon_picker.dart';

/// 圆形图标选择器示例
class CircleIconPickerExample extends StatefulWidget {
  const CircleIconPickerExample({super.key});

  @override
  State<CircleIconPickerExample> createState() => _CircleIconPickerExampleState();
}

class _CircleIconPickerExampleState extends State<CircleIconPickerExample> {
  IconData selectedIcon = Icons.help_outline;
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('圆形图标选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CircleIconPicker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个圆形图标选择器，支持选择图标和颜色组合。'),
            const SizedBox(height: 32),
            Center(
              child: CircleIconPicker(
                currentIcon: selectedIcon,
                backgroundColor: selectedColor,
                onIconSelected: (icon) {
                  setState(() {
                    selectedIcon = icon;
                  });
                },
                onColorSelected: (color) {
                  setState(() {
                    selectedColor = color;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '当前配置: 图标 + 颜色 ${selectedColor.value.toRadixString(16).toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
