import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'folder_operations.dart';

class FolderListTile extends StatelessWidget {
  final Folder folder;
  final NotesController controller;
  final Function(Folder) onNavigateToFolder;
  final VoidCallback onReload;

  const FolderListTile({
    super.key,
    required this.folder,
    required this.controller,
    required this.onNavigateToFolder,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(folder.name),
      onTap: () => onNavigateToFolder(folder),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('app_rename'.tr),
                      onTap: () async {
                        Navigator.pop(context);
                        await renameFolderDialog(
                          context,
                          controller,
                          folder,
                          onReload,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        '删除',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await deleteFolderDialog(
                          context,
                          controller,
                          folder,
                          onReload,
                        );
                      },
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
