import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/controllers/form_controller.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_selector_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';

class BasicInfoTab extends StatelessWidget {
  final GoodsItemFormController controller;
  final Function() onStateChanged;
  final Function()? onDelete;
  final bool showDeleteButton;

  const BasicInfoTab({
    super.key,
    required this.controller,
    required this.onStateChanged,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildImageUploadSection(context),
        const SizedBox(height: 24),
        _buildItemNameCard(context),
        const SizedBox(height: 16),
        _buildDateGrid(context),
        const SizedBox(height: 16),
        _buildPriceQuantityGrid(context),
        const SizedBox(height: 16),
        _buildCategorySection(context),
        const SizedBox(height: 16),
        _buildStatusSection(context),
        const SizedBox(height: 16),
        _buildCustomFieldsSection(context),
        const SizedBox(height: 16),
        _buildSubItemsSection(context),
        if (showDeleteButton && onDelete != null) ...[
          const SizedBox(height: 24),
          _buildDeleteButton(context),
        ],
        const SizedBox(height: 80), // Space for FAB/Bottom Bar
      ],
    );
  }

  Widget _buildImageUploadSection(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _pickAndCropImage(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: controller.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImage(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'goods_uploadItemImage'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildItemNameCard(BuildContext context) {
    return FormFieldGroup(
      children: [
        TextInputField(
          controller: controller.nameController,
          labelText: 'goods_productName'.tr,
          hintText: 'goods_enterProductName'.tr,
          prefixIcon: Icon(
            Icons.label_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'goods_pleaseEnterProductName'.tr;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateGrid(BuildContext context) {
    return FormFieldGroup(
      children: [
        _buildDateCard(
          context,
          'goods_purchaseDate'.tr,
          Icons.calendar_today,
          controller.purchaseDate,
          (date) {
            if (date != null) {
              controller.purchaseDate = date;
              onStateChanged();
            }
          },
        ),
        _buildDateCard(
          context,
          'goods_expirationDate'.tr,
          Icons.event_busy,
          controller.expirationDate,
          (date) {
            controller.expirationDate = date;
            onStateChanged();
          },
        ),
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? date,
    Function(DateTime?) onDateSelected,
  ) {
    return DatePickerField(
      date: date,
      formattedDate: date != null
          ? DateFormat('yyyy-MM-dd').format(date)
          : '',
      placeholder: 'goods_selectDate'.tr,
      icon: icon,
      inline: true,
      labelText: label,
      onTap: () => _showDatePicker(
        context,
        date,
        onDateSelected,
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime?) onDateSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildPriceQuantityGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextInputField(
            controller: controller.priceController,
            labelText: 'goods_price'.tr,
            hintText: '¥ 0.00',
            keyboardType: TextInputType.number,
            prefixIcon: Icon(
              Icons.paid,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            controller: controller.stockController,
            labelText: 'goods_quantity'.tr,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(
              Icons.pin_invoke,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      OptionItem(id: 'electronics', icon: Icons.devices, label: 'goods_categoryElectronics'.tr),
      OptionItem(id: 'household', icon: Icons.lightbulb, label: 'goods_categoryHousehold'.tr),
      OptionItem(id: 'clothing', icon: Icons.checkroom, label: 'goods_categoryClothing'.tr),
      OptionItem(id: 'books', icon: Icons.menu_book, label: 'goods_categoryBooks'.tr),
      OptionItem(id: 'other', icon: Icons.category, label: 'goods_categoryOther'.tr),
    ];

    // Determine selected category from tags
    String selectedCategory = 'other';
    for (var cat in categories) {
      if (controller.tags.contains(cat.id)) {
        selectedCategory = cat.id;
        break;
      }
    }

    return OptionSelectorField(
      options: categories,
      selectedId: selectedCategory,
      labelText: 'goods_category'.tr,
      onSelectionChanged: (optionId) {
        // Clear old category tags
        controller.tags.removeWhere(
          (t) => categories.any((c) => c.id == t),
        );
        // Add new category tag
        controller.tags.add(optionId);
        onStateChanged();
      },
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final statuses = [
      OptionItem(id: 'normal', icon: Icons.check_circle_outline, label: 'goods_statusNormal'.tr),
      OptionItem(id: 'damaged', icon: Icons.broken_image, label: 'goods_statusDamaged'.tr),
      OptionItem(id: 'lent', icon: Icons.ios_share, label: 'goods_statusLent'.tr),
      OptionItem(id: 'sold', icon: Icons.sell, label: 'goods_statusSold'.tr),
    ];

    return OptionSelectorField(
      options: statuses,
      selectedId: controller.status,
      labelText: 'goods_usageStatus'.tr,
      useHorizontalScroll: false,
      gridColumns: 4,
      onSelectionChanged: (optionId) {
        controller.status = optionId;
        onStateChanged();
      },
    );
  }

  Widget _buildCustomFieldsSection(BuildContext context) {
    return CustomFieldsField(
      fields: controller.customFields,
      onFieldsChanged: (fields) {
        controller.customFields = fields;
        onStateChanged();
      },
      labelText: 'goods_customFields'.tr,
      addButtonText: 'goods_addField'.tr,
      addDialogTitle: 'goods_addCustomField'.tr,
      editDialogTitle: 'goods_editCustomField'.tr,
      fieldNameLabel: 'goods_fieldName'.tr,
      fieldNameHint: 'goods_enterFieldName'.tr,
      fieldValueLabel: 'goods_fieldValue'.tr,
      fieldValueHint: 'goods_enterFieldValue'.tr,
      deleteConfirmTitle: 'goods_confirmDelete'.tr,
      deleteConfirmContent: 'goods_confirmDeleteCustomField'.tr,
    );
  }

  Widget _buildSubItemsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.widgets,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'goods_subItemList'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...controller.subItems.map(
                  (subItem) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 128,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                height: 96,
                                width: double.infinity,
                                child: _buildSubItemImage(subItem),
                              ),
                              if (subItem.purchasePrice != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '¥${subItem.purchasePrice!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              subItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showAddSubItemDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 128,
                    height: 134, // Match height approx
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'goods_add'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemImage(GoodsItem item) {
    if (item.imageUrl != null) {
      // This is simplified; ideally use the same resolving logic as GoodsItemCard
      // But since we might not be able to async resolve here easily without state,
      // we can try to check if it's network or file.
      // However, item.imageUrl stored in DB is relative.
      // For preview here, if it's a new item, it might be absolute path.
      // If it's existing item, it's relative.
      // For simplicity, we use a FutureBuilder wrapper or just icon if complicated.
      // Let's use a simple FutureBuilder for local images.
      return FutureBuilder<String>(
        future: _getItemImageUrl(item),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final path = snapshot.data!;
            if (path.startsWith('http')) {
              return Image.network(path, fit: BoxFit.cover);
            } else {
              return Image.file(File(path), fit: BoxFit.cover);
            }
          }
          return Container(
            color: item.iconColor ?? Colors.grey[200],
            child: Icon(item.icon ?? Icons.inventory_2, color: Colors.white),
          );
        },
      );
    }
    return Container(
      color: item.iconColor ?? Colors.grey[200],
      child: Icon(item.icon ?? Icons.inventory_2, color: Colors.white),
    );
  }

  // 获取物品图片URL的工具方法
  Future<String> _getItemImageUrl(GoodsItem item) async {
    final thumbUrl = await item.getThumbUrl();
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return thumbUrl;
    }

    final imageUrl = await item.getImageUrl();
    return imageUrl ?? '';
  }

  void _showAddSubItemDialog(BuildContext context) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder:
          (context) => GoodsItemSelectorDialog(
            excludeItemId: controller.initialData?.id,
            excludeItemIds: controller.subItems.map((e) => e.id).toList(),
          ),
    );

    if (result != null) {
      if (result is GoodsItem) {
        controller.addSubItem(result);
        onStateChanged();
      } else if (result is List<GoodsItem>) {
        for (var item in result) {
          controller.addSubItem(item);
        }
        onStateChanged();
      }
    }
  }

  Widget _buildDeleteButton(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'goods_confirmDelete'.tr,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: Text(
              'goods_confirmDeleteItem'.tr,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                child: Text('goods_cancel'.tr),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  'goods_delete'.tr,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: theme.colorScheme.error,
        side: BorderSide(color: theme.colorScheme.error),
      ),
      child: Text('goods_deleteProduct'.tr),
    );
  }

  Widget _buildImage() {
    final displayPath = controller.thumbPath ?? controller.imagePath;
    if (displayPath == null) {
      return const Icon(Icons.broken_image);
    }

    if (displayPath.startsWith('http://') ||
        displayPath.startsWith('https://')) {
      return Image.network(
        displayPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(displayPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder:
                (context, error, stackTrace) => const Icon(Icons.broken_image),
          );
        }
        return const Icon(Icons.broken_image);
      },
    );
  }

  Future<void> _pickAndCropImage(BuildContext context) async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (context) => ImagePickerDialog(
              initialUrl: controller.imagePath,
              saveDirectory: 'goods/goods_images',
              enableCrop: true,
              cropAspectRatio: 1,
              enableCompression: true,
              compressionQuality: 85,
            ),
      );

      if (result != null && result['url'] != null) {
        final path = result['url'];
        final thumbPath = result['thumbUrl'] as String?;
        if (path.isNotEmpty) {
          if (controller.imagePath != null) {
            await ImageUtils.deleteImage(controller.imagePath);
          }
          if (controller.thumbPath != null) {
            await ImageUtils.deleteImage(controller.thumbPath);
          }

          controller.imagePath = path;
          controller.thumbPath = thumbPath;
          onStateChanged();
        }
      }
    } catch (e) {
      if (context.mounted) {
        toastService.showToast('goods_selectImageFailed'.tr);
      }
      debugPrint('选择图片时出错: $e');
    }
  }
}
