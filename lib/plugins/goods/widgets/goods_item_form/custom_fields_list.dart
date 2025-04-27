import 'package:flutter/material.dart';
import '../../models/custom_field.dart';

class CustomFieldsList extends StatefulWidget {
  final List<CustomField> fields;
  final Function(List<CustomField>) onFieldsChanged;

  const CustomFieldsList({
    super.key,
    required this.fields,
    required this.onFieldsChanged,
  });

  @override
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
            const Text(
              '自定义字段',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加字段'),
              onPressed: _addNewField,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_fields.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('暂无自定义字段', style: TextStyle(color: Colors.grey)),
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
          title: const Text('添加自定义字段'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: '字段名',
                  hintText: '输入字段名',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: '字段值',
                  hintText: '输入字段值',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('字段名和字段值不能为空')));
                }
              },
              child: const Text('确认'),
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
          title: const Text('编辑自定义字段'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: '字段名',
                  hintText: '输入字段名',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: '字段值',
                  hintText: '输入字段值',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('字段名和字段值不能为空')));
                }
              },
              child: const Text('确认'),
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
          title: const Text('确认删除'),
          content: const Text('确定要删除这个自定义字段吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
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
