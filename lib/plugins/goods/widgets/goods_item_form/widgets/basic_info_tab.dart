import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'package:intl/intl.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/controllers/form_controller.dart';
import 'package:Memento/plugins/goods/widgets/goods_sub_items_field.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 物品基本信息标签页
///
/// 使用 FormBuilderWrapper 进行声明式表单管理
class BasicInfoTab extends StatelessWidget {
  final GoodsItemFormController controller;
  final Function() onStateChanged;

  const BasicInfoTab({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 分类选项
    final categories = [
      OptionItem(id: 'electronics', icon: Icons.devices, label: 'goods_categoryElectronics'.tr),
      OptionItem(id: 'household', icon: Icons.lightbulb, label: 'goods_categoryHousehold'.tr),
      OptionItem(id: 'clothing', icon: Icons.checkroom, label: 'goods_categoryClothing'.tr),
      OptionItem(id: 'books', icon: Icons.menu_book, label: 'goods_categoryBooks'.tr),
      OptionItem(id: 'other', icon: Icons.category, label: 'goods_categoryOther'.tr),
    ];

    // 状态选项
    final statuses = [
      OptionItem(id: 'normal', icon: Icons.check_circle_outline, label: 'goods_statusNormal'.tr),
      OptionItem(id: 'damaged', icon: Icons.broken_image, label: 'goods_statusDamaged'.tr),
      OptionItem(id: 'lent', icon: Icons.ios_share, label: 'goods_statusLent'.tr),
      OptionItem(id: 'sold', icon: Icons.sell, label: 'goods_statusSold'.tr),
    ];

    // 确定当前选中的分类
    String selectedCategory = 'other';
    for (var cat in categories) {
      if (controller.tags.contains(cat.id)) {
        selectedCategory = cat.id;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 图片上传部分 - 保持自定义 UI
        _buildImageUploadSection(context),
        const SizedBox(height: 24),

        // 物品名称
        FormFieldGroup(
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
        ),

        const SizedBox(height: 16),

        // 购买日期和到期日期
        FormFieldGroup(
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
        ),

        const SizedBox(height: 16),

        // 价格和数量
        Row(
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
        ),

        const SizedBox(height: 16),

        // 分类选择器
        OptionSelectorField(
          options: categories,
          selectedId: selectedCategory,
          labelText: 'goods_category'.tr,
          onSelectionChanged: (optionId) {
            // 清除旧分类标签
            controller.tags.removeWhere(
              (t) => categories.any((c) => c.id == t),
            );
            // 添加新分类标签
            controller.tags.add(optionId);
            onStateChanged();
          },
        ),

        const SizedBox(height: 16),

        // 状态选择器
        OptionSelectorField(
          options: statuses,
          selectedId: controller.status,
          labelText: 'goods_usageStatus'.tr,
          useHorizontalScroll: false,
          gridColumns: 4,
          onSelectionChanged: (optionId) {
            controller.status = optionId;
            onStateChanged();
          },
        ),

        const SizedBox(height: 16),

        // 自定义字段
        CustomFieldsField(
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
        ),

        const SizedBox(height: 16),

        // 子物品列表
        GoodsSubItemsField(
          subItems: controller.subItems,
          excludeItemId: controller.initialData?.id,
          onSubItemsChanged: (items) {
            controller.subItems.clear();
            controller.subItems.addAll(items);
            onStateChanged();
          },
        ),

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
