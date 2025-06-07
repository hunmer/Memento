import 'package:flutter/material.dart';
import '../../../../widgets/tag_manager_dialog/models/tag_group.dart' as dialog;

class TagManagerDialog extends StatefulWidget {
  final List<dialog.TagGroup> groups;
  final List<String> selectedTags;
  final ValueChanged<List<dialog.TagGroup>> onGroupsChanged;

  const TagManagerDialog({
    Key? key,
    required this.groups,
    required this.selectedTags,
    required this.onGroupsChanged,
  }) : super(key: key);

  @override
  _TagManagerDialogState createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  late List<dialog.TagGroup> _groups;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _selectedTags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('标签管理'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            for (final group in _groups)
              ExpansionTile(
                title: Text(group.name),
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        for (final tag in group.tags)
                          CheckboxListTile(
                            title: Text(tag),
                            value: _selectedTags.any((t) => t == tag),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.removeWhere((t) => t == tag);
                                }
                              });
                            },
                            secondary: Icon(Icons.label),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onGroupsChanged(_groups);
            Navigator.pop(context, _selectedTags);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
