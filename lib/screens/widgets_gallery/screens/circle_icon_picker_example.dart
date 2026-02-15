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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('圆形图标选择器'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
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
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
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
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
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
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '当前配置: 图标 + 颜色 ${selectedColor.value.toRadixString(16).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
