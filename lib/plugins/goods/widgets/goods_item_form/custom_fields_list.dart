import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:Memento/core/services/toast_service.dart';

class CustomFieldsList extends StatefulWidget {
  final List<CustomField> fields;
  final Function(List<CustomField>) onFieldsChanged;

  const CustomFieldsList({
    super.key,
    required this.fields,
    required this.onFieldsChanged,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CustomFieldsListState createState() => _CustomFieldsListState();
}

class _CustomFieldsListState extends State<CustomFieldsList> {
  late List<CustomField> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List<CustomField>.from(widget.fields);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'goods_customFields'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text('goods_addField'.tr),
              onPressed: _addNewField,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_fields.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'goods_noCustomFields'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            itemBuilder: (context, index) {
              final field = _fields[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: ListTile(
                  title: Text(field.key),
                  subtitle: Text(field.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeField(index),
                  ),
                  onTap: () => _editField(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _addNewField() async {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    final theme = Theme.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'goods_addCustomField'.tr,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'goods_fieldName'.tr,
                  hintText: 'goods_enterFieldName'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'goods_fieldValue'.tr,
                  hintText: 'goods_enterFieldValue'.tr,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    'goods_fieldNameAndValueCannotBeEmpty'.tr,
                  );
                }
              },
              child: Text('goods_confirm'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _fields.add(
          CustomField(key: keyController.text, value: valueController.text),
        );
        widget.onFieldsChanged(_fields);
      });
    }
  }

  void _editField(int index) async {
    final field = _fields[index];
    final TextEditingController keyController = TextEditingController(
      text: field.key,
    );
    final TextEditingController valueController = TextEditingController(
      text: field.value,
    );
    final theme = Theme.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'goods_editCustomField'.tr,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'goods_fieldName'.tr,
                  hintText: 'goods_enterFieldName'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'goods_fieldValue'.tr,
                  hintText: 'goods_enterFieldValue'.tr,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    'goods_fieldNameAndValueCannotBeEmpty'.tr,
                  );
                }
              },
              child: Text('goods_confirm'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _fields[index] = CustomField(
          key: keyController.text,
          value: valueController.text,
        );
        widget.onFieldsChanged(_fields);
      });
    }
  }

  void _removeField(int index) {
    final theme = Theme.of(context);
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'goods_confirmDelete'.tr,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'goods_confirmDeleteCustomField'.tr,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'goods_delete'.tr,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _fields.removeAt(index);
          widget.onFieldsChanged(_fields);
        });
      }
    });
  }
}
