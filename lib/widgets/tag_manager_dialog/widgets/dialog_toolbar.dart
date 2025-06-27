import 'package:flutter/material.dart';
import '../models/tag_manager_config.dart';

class DialogToolbar extends StatelessWidget {
  final String selectedGroup;
  final List<String> groups;
  final TagManagerConfig config;
  final bool enableEditing;
  final Function(String?) onGroupChanged;
  final VoidCallback onEditGroup;
  final VoidCallback onDeleteTags;
  final VoidCallback onAddTag;
  final VoidCallback onCreateGroup;

  const DialogToolbar({
    super.key,
    required this.selectedGroup,
    required this.groups,
    required this.config,
    required this.enableEditing,
    required this.onGroupChanged,
    required this.onEditGroup,
    required this.onDeleteTags,
    required this.onAddTag,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: selectedGroup,
          items: [
            DropdownMenuItem(
              value: config.allTagsLabel,
              child: Text(config.allTagsLabel),
            ),
            ...groups
                .where((group) => group != config.allTagsLabel)
                .map(
                  (group) => DropdownMenuItem(value: group, child: Text(group)),
                ),
          ],
          onChanged: onGroupChanged,
        ),
        if (enableEditing)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed:
                    selectedGroup == config.allTagsLabel ? null : onEditGroup,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed:
                    selectedGroup == config.allTagsLabel ? null : onDeleteTags,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed:
                    selectedGroup == config.allTagsLabel ? null : onAddTag,
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder),
                onPressed: onCreateGroup,
              ),
            ],
          ),
      ],
    );
  }
}
