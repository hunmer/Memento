import 'package:flutter/material.dart';
import 'package:Memento/plugins/nodes/screens/node_edit_screen/dialogs/add_tag_dialog.dart';

class TagsSection extends StatelessWidget {
  final List<String> tags;
  final Function(String) onTagRemoved;
  final Function(String) onTagAdded;

  const TagsSection({
    super.key,
    required this.tags,
    required this.onTagRemoved,
    required this.onTagAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ...tags.map(
          (tag) => Chip(label: Text(tag), onDeleted: () => onTagRemoved(tag)),
        ),
        ActionChip(
          label: const Icon(Icons.add, size: 20),
          onPressed: () => _showAddTagDialog(context),
        ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTagDialog(onTagAdded: onTagAdded),
    );
  }
}
