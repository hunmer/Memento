import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../../widgets/image_picker_dialog.dart';
import '../../../../../utils/image_utils.dart';
import '../controllers/form_controller.dart';
import '../../../models/goods_item.dart';
import '../../goods_item_selector_dialog.dart';
import '../custom_fields_list.dart';

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
      padding: const EdgeInsets.all(16),
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
    return InkWell(
      onTap: () => _pickAndCropImage(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid, // Using solid as dashed border needs custom painter or package
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
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '上传物品图片', // TODO: Localize
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildItemNameCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline, size: 20, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                GoodsLocalizations.of(context).productName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.nameController,
            decoration: InputDecoration(
              hintText: GoodsLocalizations.of(context).enterProductName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return GoodsLocalizations.of(context).pleaseEnterProductName;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            context,
            '购入日期', // TODO: Localize
            Icons.calendar_today,
            controller.purchaseDate,
            (date) {
              if (date != null) {
                controller.purchaseDate = date;
                onStateChanged();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateCard(
            context,
            '过期日期 (可选)', // TODO: Localize
            Icons.event_busy,
            controller.expirationDate,
            (date) {
              controller.expirationDate = date;
              onStateChanged();
            },
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).hintColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date != null ? DateFormat('yyyy-MM-dd').format(date) : '选择日期', // TODO: Localize
                style: TextStyle(
                  color: date != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceQuantityGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInputCard(
            context,
            GoodsLocalizations.of(context).price,
            Icons.paid,
            controller.priceController,
            keyboardType: TextInputType.number,
            hintText: '¥ 0.00',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInputCard(
            context,
            '数量', // TODO: Localize
            Icons.pin_invoke, // Using approximate icon
            controller.stockController,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).hintColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      {'id': 'electronics', 'icon': Icons.devices, 'label': '电子产品'},
      {'id': 'household', 'icon': Icons.lightbulb, 'label': '生活用品'},
      {'id': 'clothing', 'icon': Icons.checkroom, 'label': '服饰'},
      {'id': 'books', 'icon': Icons.menu_book, 'label': '书籍'},
      {'id': 'other', 'icon': Icons.category, 'label': '其他'},
    ];

    // Determine selected category from tags
    String selectedCategory = 'other';
    for (var cat in categories) {
      if (controller.tags.contains(cat['id'])) {
        selectedCategory = cat['id'] as String;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, size: 20, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                '分类', // TODO: Localize
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      // Clear old category tags
                      controller.tags.removeWhere((t) => categories.any((c) => c['id'] == t));
                      // Add new category tag
                      controller.tags.add(cat['id'] as String);
                      onStateChanged();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 32,
                            color: isSelected ? Colors.white : Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final statuses = [
      {'id': 'normal', 'icon': Icons.check_circle_outline, 'label': '正常'},
      {'id': 'damaged', 'icon': Icons.broken_image, 'label': '损坏'},
      {'id': 'lent', 'icon': Icons.ios_share, 'label': '借出'},
      {'id': 'sold', 'icon': Icons.sell, 'label': '已出'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, size: 20, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                '使用状态', // TODO: Localize
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 24) / 4; // 24 = 3 gaps * 8
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((status) {
                  final isSelected = controller.status == status['id'];
                  return InkWell(
                    onTap: () {
                      controller.status = status['id'] as String;
                      onStateChanged();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            status['icon'] as IconData,
                            size: 24,
                            color: isSelected ? Colors.white : Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 20, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                GoodsLocalizations.of(context).customFields,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomFieldsList(
            fields: controller.customFields,
            onFieldsChanged: (fields) {
              controller.customFields = fields;
              onStateChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.widgets, size: 20, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                '子物品清单', // TODO: Localize
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...controller.subItems.map((subItem) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 128,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '¥${subItem.purchasePrice!.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                InkWell(
                  onTap: () => _showAddSubItemDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 128,
                    height: 134, // Match height approx
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 32, color: Theme.of(context).hintColor),
                        const SizedBox(height: 4),
                        Text(
                          '添加', // TODO: Localize
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
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
        }
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
      builder: (context) => GoodsItemSelectorDialog(
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
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(GoodsLocalizations.of(context).confirmDelete),
                content: Text(
                  GoodsLocalizations.of(context).confirmDeleteItem,
                ),
                actions: [
                  TextButton(
                    child: Text(GoodsLocalizations.of(context).cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text(
                      GoodsLocalizations.of(context).delete,
                      style: const TextStyle(color: Colors.red),
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
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      child: Text(GoodsLocalizations.of(context).deleteProduct),
    );
  }

  Widget _buildImage() {
    final displayPath = controller.thumbPath ?? controller.imagePath;
    if (displayPath == null) {
      return const Icon(Icons.broken_image);
    }

    if (displayPath.startsWith('http://') || displayPath.startsWith('https://')) {
      return Image.network(
        displayPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
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
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GoodsLocalizations.of(context).selectImageFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('选择图片时出错: $e');
    }
  }
}