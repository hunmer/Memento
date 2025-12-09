import 'package:get/get.dart' hide Node;
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

    return AlertDialog(
      title: Text('nodes_addCustomField'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'nodes_key'.tr,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'nodes_value'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('nodes_cancel'.tr),
        ),
        TextButton(
          onPressed: _addCustomField,
          child: Text('nodes_save'.tr),
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