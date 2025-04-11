import 'package:flutter/material.dart';
import '../../../models/node.dart';
import '../../../l10n/nodes_localizations.dart';
import '../dialogs/add_custom_field_dialog.dart';

class CustomFieldsSection extends StatelessWidget {
  final List<CustomField> customFields;
  final Function(int, String) onCustomFieldValueChanged;
  final Function(CustomField) onCustomFieldAdded;
  final Function(int) onCustomFieldRemoved;

  const CustomFieldsSection({
    Key? key,
    required this.customFields,
    required this.onCustomFieldValueChanged,
    required this.onCustomFieldAdded,
    required this.onCustomFieldRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customFields,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...customFields.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final field = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(field.key),
                  ),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: TextEditingController(text: field.value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => onCustomFieldValueChanged(index, value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onCustomFieldRemoved(index),
                  ),
                ],
              ),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCustomField),
          onPressed: () => _showAddCustomFieldDialog(context),
        ),
      ],
    );
  }

  void _showAddCustomFieldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCustomFieldDialog(
        onCustomFieldAdded: onCustomFieldAdded,
      ),
    );
  }
}