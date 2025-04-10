import 'package:flutter/material.dart';

class FolderSelectionDialog extends StatefulWidget {
  final List<String> folders;

  const FolderSelectionDialog({super.key, required this.folders});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  final Set<String> _selectedFolders = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择要导入的文件夹'),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.folders.map((folder) {
                return CheckboxListTile(
                  title: Text(folder),
                  value: _selectedFolders.contains(folder),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedFolders.add(folder);
                      } else {
                        _selectedFolders.remove(folder);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () => Navigator.of(context).pop(_selectedFolders.toList()),
        ),
      ],
    );
  }
}