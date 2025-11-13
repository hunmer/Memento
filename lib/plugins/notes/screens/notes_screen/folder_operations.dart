import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:flutter/material.dart';
import '../../l10n/notes_localizations.dart';
import '../../models/folder.dart';
import 'notes_screen_state.dart';

mixin FolderOperations on NotesMainViewState {
  Future<void> createNewFolder() async {
    final TextEditingController folderNameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              NotesLocalizations.of(context).newFolder ?? 'New Folder',
            ),
            content: TextField(
              controller: folderNameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    NotesLocalizations.of(context).folderNameHint ??
                    'Folder name',
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(NotesLocalizations.of(context).cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (folderNameController.text.isNotEmpty) {
                    Navigator.pop(context, folderNameController.text);
                  }
                },
                child: Text(
                  NotesLocalizations.of(context).confirm ?? 'Confirm',
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
              NotesLocalizations.of(context).renameFolder ?? 'Rename Folder',
            ),
            content: TextField(
              controller: renameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: '文件夹名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, renameController.text),
                child: Text(AppLocalizations.of(context)!.ok),
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
              NotesLocalizations.of(context).deleteFolder ?? 'Delete Folder',
            ),
            content: Text(
              NotesLocalizations.of(context).deleteFolderConfirm ??
                  'Are you sure you want to delete this folder? All content in this folder will be deleted and cannot be recovered.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  NodesLocalizations.of(context).delete,
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
