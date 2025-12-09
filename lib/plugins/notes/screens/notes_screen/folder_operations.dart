import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'notes_screen_state.dart';

mixin FolderOperations on NotesMainViewState {
  Future<void> createNewFolder() async {
    final TextEditingController folderNameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'notes_newFolder'.tr,
            ),
            content: TextField(
              controller: folderNameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'notes_folderNameHint'.tr,
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
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
                  .delete,
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
