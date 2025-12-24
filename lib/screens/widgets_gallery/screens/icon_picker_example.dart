import 'package:flutter/material.dart';
import 'package:Memento/widgets/picker/icon_picker_dialog.dart';

/// 图标选择器示例
class IconPickerExample extends StatefulWidget {
  const IconPickerExample({super.key});

  @override
  State<IconPickerExample> createState() => _IconPickerExampleState();
}

class _IconPickerExampleState extends State<IconPickerExample> {
  IconData selectedIcon = Icons.help_outline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图标选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IconPickerDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个图标选择器对话框，支持选择 Material Icons 图标。'),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Icon(
                  selectedIcon,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showIconPicker,
                icon: Icon(selectedIcon),
                label: const Text('选择图标'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() async {
    final icon = await showIconPickerDialog(
      context,
      selectedIcon,
    );
    if (icon != null) {
      setState(() {
        selectedIcon = icon;
      });
    }
  }
}
