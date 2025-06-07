import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/database_model.dart';
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
    // Initialize empty values for all database fields
    for (final field in widget.database.fields) {
      _fields.putIfAbsent(field.name, () => '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Record'),
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
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: field.name,
                      border: const OutlineInputBorder(),
                    ),
                    initialValue: _fields[field.name]?.toString(),
                    onSaved: (value) {
                      _fields[field.name] = value;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newRecord = record_model.Record(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
