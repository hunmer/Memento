import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/database/controllers/field_controller.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/database_model.dart';
import '../models/field_model.dart';
import '../models/database_field.dart';

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
  List<FieldModel> _fields = [];
  String? _selectedFieldType;

  @override
  void initState() {
    super.initState();
    _editedDatabase = widget.database;
    _tabController = TabController(length: 2, vsync: this);
    _fields =
        _editedDatabase.fields
            .map(
              (field) => FieldModel(
                id: field.id,
                name: field.name,
                type: field.type,
                description:
                    field is FieldModel
                        ? (field as FieldModel).description
                        : null,
              ),
            )
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DatabaseLocalizations.of(context).editDatabaseTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: DatabaseLocalizations.of(context).informationTabTitle),
            Tab(text: DatabaseLocalizations.of(context).fieldsTabTitle),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Information Tab
          _buildInfoTab(),
          // Fields Tab
          _buildFieldsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _editedDatabase.name,
              decoration: InputDecoration(
                labelText: DatabaseLocalizations.of(context).databaseNameLabel,
              ),
              onChanged: (value) {
                _editedDatabase = _editedDatabase.copyWith(name: value);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickImage,
              child: Text(DatabaseLocalizations.of(context).uploadCoverImage),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _editedDatabase.description,
              decoration: InputDecoration(
                labelText: DatabaseLocalizations.of(context).descriptionLabel,
              ),
              maxLines: 3,
              onChanged: (value) {
                _editedDatabase = _editedDatabase.copyWith(description: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsTab() {
    return Stack(
      children: [
        ReorderableListView(
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _fields.removeAt(oldIndex);
              _fields.insert(newIndex, item);
            });
          },
          children:
              _fields
                  .map(
                    (field) => ListTile(
                      key: ValueKey(field.id),
                      title: Text(field.name),
                      subtitle: Text(field.type),
                      trailing: const Icon(Icons.drag_handle),
                      onTap: () => _editField(field),
                    ),
                  )
                  .toList(),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showAddFieldDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) =>
              ImagePickerDialog(enableCrop: true, cropAspectRatio: 1.0),
    );

    if (result != null && result['url'] != null && mounted) {
      setState(() {
        _editedDatabase = _editedDatabase.copyWith(coverImage: result['url']);
      });
    }
  }

  Future<void> _editField(FieldModel field) async {
    final result = await showDialog<FieldModel>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(
              'Edit ${field.type} ${DatabaseLocalizations.of(context).fieldsTabTitle}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: field.name,
                      decoration: InputDecoration(
                        labelText:
                            DatabaseLocalizations.of(context).fieldNameLabel,
                      ),
                      onChanged: (value) => field = field.copyWith(name: value),
                    ),
                    if (field.type == 'Text' ||
                        field.type == 'Long Text' ||
                        field.type == 'Password')
                      TextFormField(
                        decoration: InputDecoration(
                          labelText:
                              DatabaseLocalizations.of(
                                context,
                              ).defaultValueLabel,
                          hintText:
                              'Enter default ${field.type.toLowerCase()} value',
                        ),
                        maxLines: field.type == 'Long Text' ? 3 : 1,
                        onChanged:
                            (value) =>
                                field = field.copyWith(description: value),
                      ),
                  ],
                ),
              ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, field),
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              ),
            ],
          ),
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          final index = _fields.indexWhere((f) => f.id == result.id);
          if (index >= 0) {
            _fields[index] = result;
          } else {
            _fields.add(result);
          }
        });
      }
    }
  }

  Future<void> _showAddFieldDialog() async {
    final fieldType = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(DatabaseLocalizations.of(context).selectFieldTypeTitle),
            children: [
              for (final type in FieldController.getFieldTypes())
                FieldController.buildFieldTypeTile(
                  type: type,
                  onTap: () {
                    setState(() {
                      _selectedFieldType = type;
                    });
                    Navigator.pop(context, type);
                  },
                ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedFieldType),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            ],
          ),
    );

    if (fieldType != null) {
      final newField = FieldModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: DatabaseLocalizations.of(
          context,
        ).newFieldTitle.replaceFirst('%s', fieldType),
        type: fieldType,
      );
      await _editField(newField);
    }
  }

  Future<void> _saveChanges() async {
    try {
      if (!mounted) return;

      // 转换字段模型并更新数据库
      _editedDatabase = _editedDatabase.copyWith(
        fields:
            _fields
                .map(
                  (field) => DatabaseField(
                    id: field.id,
                    name: field.name,
                    type: field.type,
                    isRequired: false,
                  ),
                )
                .toList(),
      );

      if (_editedDatabase.id.isEmpty) {
        _editedDatabase = _editedDatabase.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await widget.controller.createDatabase(_editedDatabase);
      } else {
        await widget.controller.updateDatabase(_editedDatabase);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('Save failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DatabaseLocalizations.of(
                context,
              ).saveFailedMessage.replaceFirst('%s', e.toString()),
            ),
          ),
        );
      }
    }
  }
}
