import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/database_field.dart';

class FieldController {
  static const Map<String, IconData> fieldTypes = {
    'Text': Icons.text_fields,
    'Long Text': Icons.notes,
    'Integer': Icons.numbers,
    'Checkbox': Icons.check_box,
    'Dropdown': Icons.arrow_drop_down,
    'Date': Icons.calendar_today,
    'Time': Icons.access_time,
    'Date/Time': Icons.date_range,
    'Image': Icons.image,
    'URL': Icons.link,
    'Rating': Icons.star,
    'Password': Icons.lock,
  };

  static List<String> getFieldTypes() {
    return fieldTypes.keys.toList();
  }

  static Widget buildFieldWidget({
    required BuildContext context,
    required DatabaseField field,
    required dynamic initialValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    switch (field.type) {
      case 'Text':
      case 'Long Text':
      case 'Password':
        return TextFormField(
          initialValue: initialValue?.toString(),
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          maxLines: field.type == 'Long Text' ? 3 : 1,
          obscureText: field.type == 'Password',
          onChanged: (value) => onChanged(value),
        );
      case 'Integer':
        return TextFormField(
          initialValue: initialValue?.toString(),
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
        );
      case 'Checkbox':
        return CheckboxListTile(
          title: Text(field.name),
          value: initialValue ?? false,
          onChanged: (value) => onChanged(value),
        );
      case 'Date':
        return ListTile(
          title: Text(field.name),
          subtitle: Text(initialValue?.toString() ?? 'Select date'),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) onChanged(date);
          },
        );
      case 'Image':
        return Column(
          children: [
            if (initialValue != null && initialValue is String)
              Image.file(File(initialValue)),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  onChanged(pickedFile.path);
                }
              },
              child: const Text('Select Image'),
            ),
          ],
        );
      default:
        return TextFormField(
          initialValue: initialValue?.toString(),
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => onChanged(value),
        );
    }
  }

  static Widget buildFieldTypeTile({
    required String type,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(type),
      leading: Icon(fieldTypes[type]),
      onTap: onTap,
    );
  }
}
