import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'add_tag_dialog.dart';

class TagInputField extends StatelessWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagInputField({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('goods_tag'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => _buildTag(context, tag)),
            _buildAddButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Chip(
      label: Text(tag),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () {
        final newTags = List<String>.from(tags);
        newTags.remove(tag);
        onTagsChanged(newTags);
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.add),
      label: Text('goods_addTag'.tr),
      onPressed: () async {
        final newTag = await showDialog<String>(
          context: context,
          builder: (context) => AddTagDialog(),
        );
        if (newTag != null && !tags.contains(newTag)) {
          final newTags = List<String>.from(tags);
          newTags.add(newTag);
          onTagsChanged(newTags);
        }
      },
    );
  }
}
