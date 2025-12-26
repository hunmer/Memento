import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/goods/models/warehouse.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/core/services/toast_service.dart';

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
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.warehouse != null;
    final theme = Theme.of(context);

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
                          ? ('goods_editWarehouseTitle'.tr)
                          : ('goods_createWarehouse'.tr),
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
                    FormBuilderWrapper(
                      config: FormConfig(
                        fields: [
                          // 图标和颜色选择器
                          FormFieldConfig(
                            name: 'iconAvatar',
                            type: FormFieldType.iconAvatarRow,
                            labelText: '选择图标和颜色',
                            initialValue: {
                              'icon':
                                  widget.warehouse?.icon ?? Icons.inventory_2,
                              'iconColor':
                                  widget.warehouse?.iconColor ?? Colors.blue,
                              'avatarUrl': widget.warehouse?.imageUrl,
                            },
                            extra: {
                              'avatarSaveDirectory': 'goods/warehouse_avatars',
                            },
                          ),
                          // 标题字段
                          FormFieldConfig(
                            name: 'title',
                            type: FormFieldType.text,
                            labelText: 'goods_warehouseName'.tr,
                            hintText: 'goods_warehouseNameHint'.tr,
                            initialValue: widget.warehouse?.title ?? '',
                            required: true,
                            validationMessage: 'goods_warehouseName'.tr,
                          ),
                        ],
                        submitButtonText: isEdit ? 'goods_save'.tr : 'goods_confirm'.tr,
                        showResetButton: false,
                        onSubmit: (values) => _handleSubmit(context, values),
                        onValidationFailed: (errors) {
                          toastService.showToast(errors.values.join(', '));
                        },
                        crossAxisAlignment: CrossAxisAlignment.center,
                        fieldSpacing: 16,
                      ),
                      buttonBuilder: (context, onSubmit, onReset) {
                        return Column(
                          children: [
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const StadiumBorder(),
                                  elevation: 4,
                                  shadowColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                ),
                                child: Text(
                                  isEdit ? ('goods_save'.tr) : ('goods_confirm'.tr),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (isEdit && widget.onDelete != null) ...[
                              const SizedBox(height: 16),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: Text('goods_deleteWarehouse'.tr),
                                onPressed: () => _handleDelete(context),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context, Map<String, dynamic> values) async {
    final title = values['title'] as String? ?? '';
    if (title.isEmpty) {
      toastService.showToast('goods_warehouseName'.tr);
      return;
    }

    final iconAvatar = values['iconAvatar'] as Map<String, dynamic>? ?? {};
    final icon = iconAvatar['icon'] as IconData? ?? Icons.inventory_2;
    final color = iconAvatar['iconColor'] as Color? ?? Colors.blue;
    final imageUrl = iconAvatar['avatarUrl'] as String?;

    final warehouseData = Warehouse(
      id: widget.warehouse?.id ?? const Uuid().v4(),
      title: title,
      icon: icon,
      iconColor: color,
      imageUrl: imageUrl,
    );

    await widget.onSave(warehouseData);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('goods_confirmDelete'.tr),
            content: Text(
              'goods_confirmDeleteWarehouseMessage'.tr.replaceFirst(
                '%s',
                widget.warehouse!.title,
              ),
            ),
            actions: [
              TextButton(
                child: Text('app_cancel'.tr),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text('app_delete'.tr),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true && widget.onDelete != null) {
      await widget.onDelete!();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
