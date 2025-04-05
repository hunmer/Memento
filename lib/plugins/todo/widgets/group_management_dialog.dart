import 'package:flutter/material.dart';

class GroupManagementDialog extends StatefulWidget {
  final List<String> groups;
  final Function(String) onGroupAdded;
  final Function(String) onGroupDeleted;

  const GroupManagementDialog({
    super.key,
    required this.groups,
    required this.onGroupAdded,
    required this.onGroupDeleted,
  });

  @override
  _GroupManagementDialogState createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<GroupManagementDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addGroup() {
    final name = _textController.text.trim();
    if (name.isNotEmpty) {
      widget.onGroupAdded(name);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('管理分组'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入分组名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _addGroup, child: Text('添加')),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.groups.length,
                itemBuilder: (context, index) {
                  final group = widget.groups[index];
                  return ListTile(
                    title: Text(group),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => widget.onGroupDeleted(group),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('关闭'),
        ),
      ],
    );
  }
}
