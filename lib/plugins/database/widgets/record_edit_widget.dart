import 'package:get/get.dart';
import 'package:Memento/plugins/database/models/database_field.dart';
import 'package:Memento/plugins/database/controllers/field_controller.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import '../models/record.dart' as record_model;

class RecordEditWidget extends StatefulWidget {
  final DatabaseController controller;
  final DatabaseModel database;
  final Map<String, dynamic>? initialFields;

  const RecordEditWidget({
    super.key,
    required this.controller,
    required this.database,
    this.initialFields,
    record_model.Record? record,
  });

  @override
  State<RecordEditWidget> createState() => _RecordEditWidgetState();
}

class _RecordEditWidgetState extends State<RecordEditWidget> {
  late Map<String, dynamic> _fields;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fields = widget.initialFields ?? {};
    for (final field in widget.database.fields) {
      _fields.putIfAbsent(field.name, () {
        switch (field.type) {
          case 'Checkbox':
            return false;
          case 'Integer':
            return 0;
          case 'Date':
          case 'Time':
          case 'Date/Time':
            return DateTime.now();
          default:
            return '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('database_editRecordTitle'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRecord),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (final field in widget.database.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildFieldWidget(field),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWidget(DatabaseField field) {
    return FieldController.buildFieldWidget(
      context: context,
      field: field,
      initialValue: _fields[field.name],
      onChanged: (value) {
        setState(() {
          _fields[field.name] = value;
        });
      },
    );
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newRecord = record_model.Record(
        id: const Uuid().v4(),
        tableId: widget.database.id,
        fields: _fields,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.controller.createRecord(newRecord);
      if (mounted) {
        Navigator.of(context).pop(newRecord);
      }
    }
  }
}
