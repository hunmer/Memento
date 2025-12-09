import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'notes_screen_state.dart';
import '../../../../../../core/services/toast_service.dart';

mixin FolderSelectionDialog on NotesMainViewState {
  // 递归构建文件夹树形结构
  Widget _buildFolderTree(Folder folder, {bool isRoot = false}) {
    final children = plugin.controller.getFolderChildren(folder.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRoot) // 根文件夹不显示自身
          ListTile(
            leading: Icon(folder.icon),
            title: Text(folder.name),
            trailing:
                children.isNotEmpty ? const Icon(Icons.arrow_right) : null,
            onTap: () async {
              if (children.isEmpty) {
                // 如果没有子文件夹，直接选择当前文件夹
                Navigator.pop(context, folder);
              } else {
                // 如果有子文件夹，显示子文件夹选择对话框
                final selectedFolder = await showFolderSelectionDialog(
                  null,
                  parentFolder: folder,
                );
                if (selectedFolder != null && mounted) {
                  Navigator.pop(context, selectedFolder);
                }
              }
            },
          ),
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  children.map((child) => _buildFolderTree(child)).toList(),
            ),
          ),
      ],
    );
  }

  // 显示文件夹选择对话框
  Future<Folder?> showFolderSelectionDialog(
    Note? note, {
    Folder? parentFolder,
  }) async {
    final rootFolder = plugin.controller.getFolder('root')!;

    // 如果指定了父文件夹，则只显示该文件夹的子文件夹
    final startFolder = parentFolder ?? rootFolder;

    // 获取当前笔记所在的文件夹ID
    final currentFolderId = note?.folderId ?? currentFolder?.id;

    return showDialog<Folder>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              parentFolder != null
                  ? 'notes_selectSubfolder'.tr
                  : 'notes_moveTo'.tr,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFolderTree(
                    startFolder,
                    isRoot: startFolder.id == 'root',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              if (parentFolder != null && parentFolder.id != currentFolderId)
                TextButton(
                  onPressed: () => Navigator.pop(context, parentFolder),
                  child: Text(
                    .selectCurrentFolder,
                  ),
                ),
            ],
          ),
    );
  }

  Future<void> moveNote(Note note) async {
    final targetFolder = await showFolderSelectionDialog(note);
    if (targetFolder != null) {
      await plugin.controller.moveNote(note.id, targetFolder.id);
      loadCurrentFolder(); // 刷新当前文件夹视图
      toastService.showToast(
        'notes_movedToFolder'.trParams({'folderName': targetFolder.name}),
      );
    }
  }
}
