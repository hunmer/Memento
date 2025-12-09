import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/nodes/models/node.dart';

class AddCustomFieldDialog extends StatefulWidget {
  final Function(CustomField) onCustomFieldAdded;

  const AddCustomFieldDialog({
    super.key,
    required this.onCustomFieldAdded,
  });

  @override
  State<AddCustomFieldDialog> createState() => AddCustomFieldDialogState();
}

class AddCustomFieldDialogState extends State<AddCustomFieldDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.addCustomField),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.key,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: l10n.value,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _addCustomField,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _addCustomField() {
    final name = _nameController.text.trim();
    final value = _valueController.text.trim();
    if (name.isNotEmpty) {
      widget.onCustomFieldAdded(CustomField(key: name, value: value));
      Navigator.pop(context);
    }
  }
}