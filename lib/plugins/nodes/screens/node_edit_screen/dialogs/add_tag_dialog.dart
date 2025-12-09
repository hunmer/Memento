import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AddTagDialog extends StatefulWidget {
  final Function(String) onTagAdded;

  const AddTagDialog({
    super.key,
    required this.onTagAdded,
  });

  @override
  State<AddTagDialog> createState() => AddTagDialogState();
}

class AddTagDialogState extends State<AddTagDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.tags),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: l10n.tags,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => _addTag(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _addTag,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _controller.text.trim();
    if (tag.isNotEmpty) {
      widget.onTagAdded(tag);
      Navigator.pop(context);
    }
  }
}