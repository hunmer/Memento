import 'package:flutter/material.dart';
import '../../controllers/notes_controller.dart';
import '../../models/folder.dart';

// 创建新文件夹
Future<void> createNewFolder(
  BuildContext context,
  NotesController controller,
  String currentFolderId,
  VoidCallback onReload,
) async {
  String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController folderNameController =
          TextEditingController();

      return AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: folderNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '文件夹名称'),
          onSubmitted: (value) {
            Navigator.pop(context, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, folderNameController.text);
            },
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    await controller.createFolder(result, currentFolderId);
    onReload();
  }
}

// 重命名文件夹
Future<void> renameFolderDialog(
  BuildContext context,
  NotesController controller,
  Folder folder,
  VoidCallback onReload,
) async {
  String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController renameController = TextEditingController(
        text: folder.name,
      );

      return AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '文件夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, renameController.text);
            },
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    await controller.renameFolder(folder.id, result);
    onReload();
  }
}

// 删除文件夹
Future<void> deleteFolderDialog(
  BuildContext context,
  NotesController controller,
  Folder folder,
  VoidCallback onReload,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('删除文件夹'),
          content: const Text('确定要删除此文件夹吗？此操作将删除文件夹中的所有内容，且不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );

  if (confirmed == true) {
    await controller.deleteFolder(folder.id);
    onReload();
  }
}
