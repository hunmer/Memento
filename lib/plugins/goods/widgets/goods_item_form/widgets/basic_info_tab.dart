import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../../widgets/circle_icon_picker.dart';
import '../../../../../widgets/image_picker_dialog.dart';
import '../tag_input_field.dart';
import '../custom_fields_list.dart';
import '../controllers/form_controller.dart';
import '../../../../../utils/image_utils.dart';

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
        _buildBasicInfoCard(context),
        const SizedBox(height: 16),
        _buildPriceStockCard(context),
        const SizedBox(height: 16),
        _buildTagsCard(),
        const SizedBox(height: 16),
        _buildCustomFieldsCard(),
        if (showDeleteButton && onDelete != null) ...[
          const SizedBox(height: 16),
          _buildDeleteButton(context),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageSection(context),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context)!.productName,
                hintText: GoodsLocalizations.of(context)!.enterProductName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return GoodsLocalizations.of(context)!.pleaseEnterProductName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context)!.productDescription,
                hintText:
                    GoodsLocalizations.of(context)!.enterProductDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleIconPicker(
            currentIcon: controller.icon ?? Icons.image,
            backgroundColor: controller.iconColor ?? Colors.blue,
            onIconSelected: (icon) {
              controller.icon = icon;
              onStateChanged();
            },
            onColorSelected: (color) {
              controller.iconColor = color;
              onStateChanged();
            },
          ),
          const SizedBox(width: 24),
          Card(
            elevation: 2,
            child: SizedBox(
              height: 60,
              width: 60,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _pickAndCropImage(context),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade50,
                  ),
                  child:
                      controller.imagePath != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildImage(),
                          )
                          : Center(
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 30,
                              color: Colors.grey.shade600,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStockCard(context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.priceController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).price,
                  hintText: GoodsLocalizations.of(context).priceHint,
                  prefixText: '¥',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入价格';
                  }
                  if (double.tryParse(value) == null) {
                    return '请输入有效的价格';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.stockController,
                decoration: InputDecoration(
                  labelText: GoodsLocalizations.of(context).stock,
                  hintText: GoodsLocalizations.of(context).stockHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入库存';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效的库存数量';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TagInputField(
          tags: controller.tags,
          onTagsChanged: (tags) {
            controller.tags = tags;
            onStateChanged();
          },
        ),
      ),
    );
  }

  Widget _buildCustomFieldsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomFieldsList(
          fields: controller.customFields,
          onFieldsChanged: (fields) {
            controller.customFields = fields;
            onStateChanged();
          },
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(GoodsLocalizations.of(context)!.confirmDelete),
                content: Text(
                  GoodsLocalizations.of(context)!.confirmDeleteItem,
                ),
                actions: [
                  TextButton(
                    child: Text(GoodsLocalizations.of(context)!.cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text(
                      GoodsLocalizations.of(context)!.delete,
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
      child: Text(GoodsLocalizations.of(context)!.deleteProduct),
    );
  }

  Widget _buildImage() {
    final imagePath = controller.imagePath;
    if (imagePath == null) {
      return const Icon(Icons.broken_image);
    }

    // 处理网络图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }

    // 处理本地图片，使用 ImageUtils 获取绝对路径
    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(imagePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
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
      // 弹出图片选择对话框
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (context) => ImagePickerDialog(
              initialUrl: controller.imagePath,
              saveDirectory: 'goods/goods_images', // 使用专门的目录存储商品图片
              enableCrop: true,
              cropAspectRatio: 1, // 使用1:1的裁剪比例
            ),
      );

      if (result != null && result['url'] != null) {
        final path = result['url'];
        if (path.isNotEmpty) {
          // 删除旧图片
          if (controller.imagePath != null) {
            await ImageUtils.deleteImage(controller.imagePath);
          }

          // 更新图片路径
          controller.imagePath = path;
          onStateChanged();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GoodsLocalizations.of(context)!.selectImageFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('选择图片时出错: $e');
    }
  }
}
