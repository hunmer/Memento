import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
            ?.map(
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
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Database'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Information'), Tab(text: 'Fields')],
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
              decoration: const InputDecoration(labelText: 'Database Name'),
              onChanged: (value) {
                _editedDatabase = _editedDatabase.copyWith(name: value);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickImage,
              child: const Text('Upload Cover Image'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _editedDatabase.description,
              decoration: const InputDecoration(labelText: 'Description'),
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
            child: const Icon(Icons.add),
            onPressed: _showAddFieldDialog,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _editedDatabase = _editedDatabase.copyWith(coverImage: pickedFile.path);
      });
    }
  }

  Future<void> _editField(FieldModel field) async {
    final result = await showDialog<FieldModel>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Edit ${field.type} Field'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: field.name,
                      decoration: const InputDecoration(
                        labelText: 'Field Name',
                      ),
                      onChanged: (value) => field = field.copyWith(name: value),
                    ),
                    if (field.type == 'Text' ||
                        field.type == 'Long Text' ||
                        field.type == 'Password')
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Default Value',
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
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, field),
                    child: const Text('Save'),
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
            title: const Text('Select Field Type'),
            children: [
              _buildFieldTypeTile('Text', Icons.text_fields),
              _buildFieldTypeTile('Long Text', Icons.notes),
              _buildFieldTypeTile('Integer', Icons.numbers),
              _buildFieldTypeTile('Checkbox', Icons.check_box),
              _buildFieldTypeTile('Dropdown', Icons.arrow_drop_down),
              _buildFieldTypeTile('Date', Icons.calendar_today),
              _buildFieldTypeTile('Time', Icons.access_time),
              _buildFieldTypeTile('Date/Time', Icons.date_range),
              _buildFieldTypeTile('Image', Icons.image),
              _buildFieldTypeTile('URL', Icons.link),
              _buildFieldTypeTile('Rating', Icons.star),
              _buildFieldTypeTile('Password', Icons.lock),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedFieldType),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
    );

    if (fieldType != null) {
      final newField = FieldModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New $fieldType Field',
        type: fieldType,
      );
      await _editField(newField);
    }
  }

  ListTile _buildFieldTypeTile(String type, IconData icon) {
    return ListTile(
      title: Text(type),
      leading: Icon(icon),
      onTap: () {
        setState(() {
          _selectedFieldType = type;
        });
        Navigator.pop(context, type);
      },
    );
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

      await widget.controller.updateDatabase(_editedDatabase);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('Save failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${e.toString()}')));
      }
    }
  }
}
