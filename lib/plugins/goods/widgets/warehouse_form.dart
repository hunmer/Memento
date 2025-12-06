import 'dart:io';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import '../models/warehouse.dart';
import '../../../widgets/icon_picker_dialog.dart';
import '../../../widgets/image_picker_dialog.dart';
import '../../../utils/image_utils.dart';
import '../../../core/services/toast_service.dart';

class WarehouseForm extends StatefulWidget {
  final Warehouse? warehouse;
  final Future<void> Function(Warehouse) onSave;
  final Future<void> Function()? onDelete;

  const WarehouseForm({
    super.key,
    this.warehouse,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<WarehouseForm> createState() => _WarehouseFormState();
}

class _WarehouseFormState extends State<WarehouseForm> {
  late TextEditingController _titleController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.warehouse?.title ?? '',
    );
    _selectedIcon = widget.warehouse?.icon ?? Icons.inventory_2;
    _selectedColor = widget.warehouse?.iconColor ?? Colors.blue;
    _imageUrl = widget.warehouse?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final IconData? result = await showIconPickerDialog(context, _selectedIcon);
    if (result != null) {
      setState(() {
        _selectedIcon = result;
      });
    }
  }

  Future<void> _pickColor() async {
    Color newColor = _selectedColor;
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectBackgroundColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) => newColor = color,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop(newColor);
              },
            ),
          ],
        );
      },
    );
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => ImagePickerDialog(
            initialUrl: _imageUrl,
            saveDirectory: 'goods/warehouse_images',
            enableCrop: true,
            cropAspectRatio: 1 / 1,
          ),
    );
    if (result != null) {
      setState(() {
        _imageUrl = result['url'] as String;
      });
    }
  }

  Widget _buildWarehouseImage() {
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return Icon(Icons.image, size: 24, color: _selectedColor);
    }

    if (_imageUrl!.startsWith('http://') || _imageUrl!.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.broken_image, size: 24, color: _selectedColor),
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(_imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Icon(
                      Icons.broken_image,
                      size: 24,
                      color: _selectedColor,
                    ),
              ),
            );
          }
        }
        return Icon(Icons.broken_image, size: 24, color: _selectedColor);
      },
    );
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      toastService.showToast(GoodsLocalizations.of(context).warehouseName);
      return;
    }

    final warehouse = Warehouse(
      id: widget.warehouse?.id ?? const Uuid().v4(),
      title: title,
      icon: _selectedIcon,
      iconColor: _selectedColor,
      imageUrl: _imageUrl,
    );

    await widget.onSave(warehouse);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _delete() async {
    final l10n = GoodsLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(
              l10n.confirmDeleteWarehouseMessage.replaceFirst(
                '%s',
                widget.warehouse!.title,
              ),
            ),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true && widget.onDelete != null) {
      await widget.onDelete!();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.warehouse != null;
    final theme = Theme.of(context);
    final l10n = GoodsLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEdit
                          ? (l10n.editWarehouseTitle)
                          : (l10n.createWarehouse ?? '新建仓库'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Icon Display
                    GestureDetector(
                      onTap: _pickIcon,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          _selectedIcon,
                          size: 48,
                          color: _selectedColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Actions Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _pickIcon,
                          child: Text(
                            '选择图标', // TODO: Localize
                            style: TextStyle(
                              color: _selectedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickColor,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedColor,
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Image Picker Trigger
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: _buildWarehouseImage(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Input Field
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              l10n.warehouseName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextField(
                            controller: _titleController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: l10n.warehouseNameHint,
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _selectedColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEdit && widget.onDelete != null) ...[
                      const SizedBox(height: 32),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.deleteWarehouse),
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 4,
                    shadowColor: _selectedColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    isEdit ? (l10n.save) : (l10n.confirm),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
