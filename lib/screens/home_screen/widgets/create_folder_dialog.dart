import 'package:flutter/material.dart';
import '../managers/home_layout_manager.dart';
import '../models/home_folder_item.dart';

/// 创建文件夹对话框
class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({Key? key}) : super(key: key);

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final TextEditingController _nameController = TextEditingController();
  IconData _selectedIcon = Icons.folder;
  Color _selectedColor = Colors.blue;

  // 常用图标列表
  static const List<IconData> _folderIcons = [
    Icons.folder,
    Icons.folder_special,
    Icons.work,
    Icons.home,
    Icons.favorite,
    Icons.star,
    Icons.category,
    Icons.shopping_bag,
    Icons.school,
    Icons.sports_esports,
  ];

  // 常用颜色列表
  static const List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建文件夹'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件夹名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '文件夹名称',
                hintText: '输入文件夹名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // 图标选择
            const Text('选择图标', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _folderIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 颜色选择
            const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _createFolder,
          child: const Text('创建'),
        ),
      ],
    );
  }

  /// 创建文件夹
  void _createFolder() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文件夹名称')),
      );
      return;
    }

    final layoutManager = HomeLayoutManager();

    // 创建文件夹
    final folder = HomeFolderItem(
      id: layoutManager.generateId(),
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    // 添加到布局
    layoutManager.addItem(folder);

    // 关闭对话框
    Navigator.of(context).pop();

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已创建文件夹：$name')),
    );
  }
}
