import 'package:flutter/material.dart';
import '../../controllers/notes_controller.dart';
import '../../models/folder.dart';
import '../../models/note.dart';

Future<Folder?> showFolderSelectionDialog(
  BuildContext context,
  NotesController controller,
  Note? note, {
  Folder? parentFolder,
  Folder? currentFolder,
}) async {
  final rootFolder = controller.getFolder('root')!;
  final startFolder = parentFolder ?? rootFolder;
  final currentFolderId = note?.folderId ?? currentFolder?.id;

  return showDialog<Folder>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(parentFolder != null ? '选择子文件夹' : '选择目标文件夹'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFolderTree(
              context,
              startFolder,
              controller,
              isRoot: startFolder.id == 'root',
              currentFolderId: currentFolderId,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (parentFolder != null && parentFolder.id != currentFolderId)
          TextButton(
            onPressed: () => Navigator.pop(context, parentFolder),
            child: const Text('选择当前文件夹'),
          ),
      ],
    ),
  );
}

Widget _buildFolderTree(
  BuildContext context,
  Folder folder,
  NotesController controller, {
  bool isRoot = false,
  String? currentFolderId,
}) {
  final children = controller.getFolderChildren(folder.id);

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!isRoot)
        ListTile(
          leading: Icon(folder.icon),
          title: Text(folder.name),
          trailing: children.isNotEmpty ? const Icon(Icons.arrow_right) : null,
          onTap: () async {
            if (children.isEmpty) {
              Navigator.pop(context, folder);
            } else {
              final selectedFolder = await showFolderSelectionDialog(
                context,
                controller,
                null,
                parentFolder: folder,
              );
              if (selectedFolder != null && context.mounted) {
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
            children: children
                .map((child) => _buildFolderTree(
                      context,
                      child,
                      controller,
                      currentFolderId: currentFolderId,
                    ))
                .toList(),
          ),
        ),
    ],
  );
}