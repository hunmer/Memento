import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import '../../../../core/services/toast_service.dart';

/// 创建文件夹对话框
class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});

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
      title: Text('screens_createNewFolder'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件夹名称
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'screens_folderName'.tr,
                hintText: 'screens_enterFolderName'.tr,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // 图标选择
            Text('screens_selectIcon'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text('screens_selectColor'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text('screens_cancel'.tr),
        ),
        FilledButton(
          onPressed: _createFolder,
          child: Text('screens_create'.tr),
        ),
      ],
    );
  }

  /// 创建文件夹
  void _createFolder() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      toastService.showToast('screens_pleaseEnterFolderName'.tr);
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
    await layoutManager.saveLayout();

    // 关闭对话框
    Navigator.of(context).pop();

    // 显示提示
    toastService.showToast('screens_folderCreated'.trParams({'name': name}));
  }
}
