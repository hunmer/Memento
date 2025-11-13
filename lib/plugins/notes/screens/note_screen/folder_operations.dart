import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/notes/l10n/notes_localizations.dart';
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
        title: Text(NotesLocalizations.of(context).newFolder),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, folderNameController.text);
            },
            child: Text(AppLocalizations.of(context)!.ok),
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
        title: Text(NotesLocalizations.of(context).renameFolder),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, renameController.text);
            },
            child: Text(AppLocalizations.of(context)!.ok),
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
          title: Text(NotesLocalizations.of(context).deleteFolder),
          content: Text(NotesLocalizations.of(context).deleteFolderConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.delete,
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
