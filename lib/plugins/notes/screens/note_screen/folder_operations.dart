import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';

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
        title: Text('notes_newFolder'.tr),
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
            child: Text('app_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, folderNameController.text);
            },
            child: Text('app_ok'.tr),
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
        title: Text('notes_renameFolder'.tr),
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
            child: Text('app_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, renameController.text);
            },
            child: Text('app_ok'.tr),
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
          title: Text('notes_deleteFolder'.tr),
          content: Text('notes_deleteFolderConfirm'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('app_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'app_delete'.tr,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
  );

  if (confirmed == true) {
    await controller.deleteFolder(folder.id);
    onReload();
  }
}
