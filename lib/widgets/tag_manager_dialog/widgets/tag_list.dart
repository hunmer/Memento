import 'package:flutter/material.dart';
import 'package:Memento/widgets/tag_manager_dialog/models/tag_manager_config.dart';

class TagList extends StatelessWidget {
  final List<String> tags;
  final List<String> selectedTags;
  final TagManagerConfig? config;
  final Function(String) onTagToggle;
  final Future<void> Function(String tag, String group)? onLongPress;
  final String selectedGroup;

  const TagList({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagToggle,
    this.config,
    this.onLongPress,
    required this.selectedGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return InkWell(
          onLongPress: onLongPress != null
              ? () async {
                  await onLongPress!(tag, selectedGroup);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) => onTagToggle(tag),
              selectedColor: config?.selectedTagColor ??
                      theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: config?.checkmarkColor ?? theme.primaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}