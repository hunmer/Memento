import 'dart:io';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/warehouse.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../../../widgets/image_picker_dialog.dart';
import '../../../utils/image_utils.dart';

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

    if (_imageUrl!.startsWith('http://') || _imageUrl!.startsWith('https://')) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(_imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
            );
          }
        }
        return const Icon(Icons.broken_image, size: 40);
      },
    );
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
                              saveDirectory: 'goods/warehouse_images',
                              enableCrop: true, // 启用裁切功能
                              cropAspectRatio: 1 / 1,
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
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  SizedBox(height: 8),
                                  Text(
                                    GoodsLocalizations.of(context).selectImage,
                                  ),
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
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context).warehouseName,
                hintText: GoodsLocalizations.of(context).warehouseNameHint,
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
                  child: Text(AppLocalizations.of(context)!.cancel),
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
                      );
                      widget.onSave(warehouse);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
