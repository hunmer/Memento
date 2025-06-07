import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/database_model.dart';

class DatabaseEditWidget extends StatefulWidget {
  final DatabaseController controller;
  final DatabaseModel database;

  const DatabaseEditWidget({
    super.key,
    required this.controller,
    required this.database,
  });

  @override
  State<DatabaseEditWidget> createState() => _DatabaseEditWidgetState();
}

class _DatabaseEditWidgetState extends State<DatabaseEditWidget>
    with SingleTickerProviderStateMixin {
  late DatabaseModel _editedDatabase;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _editedDatabase = widget.database;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Database'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _editedDatabase.name,
                decoration: const InputDecoration(labelText: 'Database Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _editedDatabase = _editedDatabase.copyWith(name: value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _editedDatabase.description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) {
                  _editedDatabase = _editedDatabase.copyWith(
                    description: value,
                  );
                },
              ),
              // TODO: Add image picker for cover image
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await widget.controller.updateDatabase(_editedDatabase);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}
