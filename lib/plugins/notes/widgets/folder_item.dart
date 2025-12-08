import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';

class FolderItem extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;

  const FolderItem({
    super.key,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: folder.color,
        child: Icon(
          folder.icon,
          color: Colors.white,
        ),
      ),
      title: Text(folder.name),
      onTap: onTap,
    );
  }
}