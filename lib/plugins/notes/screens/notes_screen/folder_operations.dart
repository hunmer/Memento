import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'notes_screen_state.dart';

mixin FolderOperations on NotesMainViewState {
  Future<void> createNewFolder() async {
    final TextEditingController folderNameController = TextEditingController();

    // 获取当前文件夹名称用于提示
    final parentFolderName = currentFolder?.name ?? 'notes_root'.tr;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'notes_newFolder'.tr,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 显示将在哪个文件夹下创建
                Text(
                  '${'notes_createIn'.tr}: $parentFolderName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: folderNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        'notes_folderNameHint'.tr,
                  ),
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('notes_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  if (folderNameController.text.isNotEmpty) {
                    Navigator.pop(context, folderNameController.text);
                  }
                },
                child: Text(
                  'notes_confirm'.tr,
                ),
              ),
            ],
          ),
    );
    if (result != null && result.isNotEmpty) {
      // 使用 currentFolderId 作为父文件夹 ID
      await plugin.controller.createFolder(result, currentFolderId);
      loadCurrentFolder();
    }
  }

  Future<void> renameFolder(Folder folder) async {
    final TextEditingController renameController = TextEditingController(
      text: folder.name,
    );
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'notes_renameFolder'.tr,
            ),
            content: TextField(
              controller: renameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: '文件夹名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, renameController.text),
                child: Text('app_ok'.tr),
              ),
            ],
          ),
    );
    renameController.dispose();

    if (result != null && result.isNotEmpty) {
      await plugin.controller.renameFolder(folder.id, result);
      loadCurrentFolder();
    }
  }

  Future<void> deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'notes_deleteFolder'.tr,
            ),
            content: Text(
              'notes_deleteFolderConfirm'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'notes_delete'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await plugin.controller.deleteFolder(folder.id);
      loadCurrentFolder();
    }
  }
}
