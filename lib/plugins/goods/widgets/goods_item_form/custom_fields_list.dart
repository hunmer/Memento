import 'package:flutter/material.dart';
import '../../models/custom_field.dart';
import '../../l10n/goods_localizations.dart';
import '../../../../core/services/toast_service.dart';

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
              GoodsLocalizations.of(context).customFields,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(GoodsLocalizations.of(context).addField),
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
                GoodsLocalizations.of(context).noCustomFields,
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(GoodsLocalizations.of(context).addCustomField),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).fieldName,
                  hintText: GoodsLocalizations.of(context).enterFieldName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).fieldValue,
                  hintText: GoodsLocalizations.of(context).enterFieldValue,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(GoodsLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    GoodsLocalizations.of(
                      context,
                    ).fieldNameAndValueCannotBeEmpty,
                  );
                }
              },
              child: Text(GoodsLocalizations.of(context).confirm),
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(GoodsLocalizations.of(context).editCustomField),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).fieldName,
                  hintText: GoodsLocalizations.of(context).enterFieldName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).fieldValue,
                  hintText: GoodsLocalizations.of(context).enterFieldValue,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(GoodsLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    GoodsLocalizations.of(
                      context,
                    ).fieldNameAndValueCannotBeEmpty,
                  );
                }
              },
              child: Text(GoodsLocalizations.of(context).confirm),
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
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(GoodsLocalizations.of(context).confirmDelete),
          content: Text(
            GoodsLocalizations.of(context).confirmDeleteCustomField,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(GoodsLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(GoodsLocalizations.of(context).delete),
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
