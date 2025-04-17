import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/warehouse.dart';
import '../../../widgets/circle_icon_picker.dart';
import 'image_picker_dialog.dart';

class WarehouseForm extends StatefulWidget {
  final Warehouse? warehouse;
  final Function(Warehouse) onSave;

  const WarehouseForm({super.key, this.warehouse, required this.onSave});

  @override
  State<WarehouseForm> createState() => _WarehouseFormState();
}

class _WarehouseFormState extends State<WarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late IconData _icon;
  late Color _iconColor;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _title = widget.warehouse!.title;
      _icon = widget.warehouse!.icon;
      _iconColor = widget.warehouse!.iconColor;
      _imageUrl = widget.warehouse!.imageUrl;
    } else {
      _title = '';
      _icon = Icons.inventory_2;
      _iconColor = Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.warehouse == null ? '新建仓库' : '编辑仓库',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CircleIconPicker(
                    currentIcon: _icon,
                    backgroundColor: _iconColor,
                    onIconSelected: (icon) {
                      setState(() {
                        _icon = icon;
                      });
                    },
                    onColorSelected: (color) {
                      setState(() {
                        _iconColor = color;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder:
                            (context) =>
                                ImagePickerDialog(initialUrl: _imageUrl),
                      );
                      if (result != null) {
                        setState(() {
                          _imageUrl = result;
                        });
                      }
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          _imageUrl != null && _imageUrl!.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    _imageUrl!.startsWith('file://')
                                        ? Image.file(
                                          File(
                                            _imageUrl!.replaceFirst(
                                              'file://',
                                              '',
                                            ),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                  ),
                                        ),
                              )
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  SizedBox(height: 8),
                                  Text('选择图片'),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: '仓库名称',
                hintText: '输入仓库名称',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入仓库名称';
                }
                return null;
              },
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final warehouse = Warehouse(
                        id: widget.warehouse?.id ?? const Uuid().v4(),
                        title: _title,
                        icon: _icon,
                        iconColor: _iconColor,
                        imageUrl: _imageUrl,
                        items: widget.warehouse?.items ?? [],
                      );
                      widget.onSave(warehouse);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
