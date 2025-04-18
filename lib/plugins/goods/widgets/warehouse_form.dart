import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/warehouse.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../../../widgets/image_picker_dialog.dart';

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

  Widget _buildWarehouseImage() {
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return const Icon(Icons.image, size: 40);
    }

    if (_imageUrl!.startsWith('file://')) {
      final path = _imageUrl!.replaceFirst('file://', '');
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40),
        );
      } else {
        return const Icon(Icons.broken_image, size: 40);
      }
    } else if (_imageUrl!.startsWith('http://') ||
        _imageUrl!.startsWith('https://')) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40),
      );
    } else {
      // 尝试作为本地路径处理
      final file = File(_imageUrl!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40),
        );
      } else {
        return const Icon(Icons.broken_image, size: 40);
      }
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
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder:
                            (context) => ImagePickerDialog(
                              initialUrl: _imageUrl,
                              saveDirectory: 'warehouse_images',
                              enableCrop: true, // 启用裁切功能
                              cropAspectRatio: 16 / 9, // 设置裁切比例为16:9，适合仓库展示
                            ),
                      );
                      if (result != null) {
                        setState(() {
                          _imageUrl = result['url'] as String;
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
                                child: _buildWarehouseImage(),
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
