import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';
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
    final l10n = ScreensLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.createNewFolder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件夹名称
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.folderName,
                hintText: l10n.enterFolderName,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // 图标选择
            Text(l10n.selectIcon, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(l10n.selectColor, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _createFolder,
          child: Text(l10n.create),
        ),
      ],
    );
  }

  /// 创建文件夹
  void _createFolder() {
    final name = _nameController.text.trim();
    final l10n = ScreensLocalizations.of(context)!;

    if (name.isEmpty) {
      toastService.showToast(l10n.pleaseEnterFolderName);
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
    toastService.showToast(l10n.folderCreated(name));
  }
}
