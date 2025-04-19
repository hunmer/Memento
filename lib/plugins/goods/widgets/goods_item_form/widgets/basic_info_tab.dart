import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../../widgets/circle_icon_picker.dart';
import '../../../../../widgets/image_picker_dialog.dart';
import '../tag_input_field.dart';
import '../custom_fields_list.dart';
import '../controllers/form_controller.dart';
import '../utils/image_utils.dart';

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
        _buildPriceStockCard(),
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
              decoration: const InputDecoration(
                labelText: '商品名称',
                hintText: '输入商品名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入商品名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: '商品描述',
                hintText: '输入商品描述',
                border: OutlineInputBorder(),
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

  Widget _buildPriceStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.priceController,
                decoration: const InputDecoration(
                  labelText: '价格',
                  hintText: '输入价格',
                  prefixText: '¥',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: '库存',
                  hintText: '输入库存',
                  border: OutlineInputBorder(),
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
                title: const Text('确认删除'),
                content: const Text('确定要删除这个物品吗？此操作不可恢复。'),
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
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
      child: const Text('删除商品'),
    );
  }

  Widget _buildImage() {
    if (controller.imagePath == null) return const SizedBox();

    if (controller.imagePath!.startsWith('http://') ||
        controller.imagePath!.startsWith('https://')) {
      // 网络图片
      return Image.network(
        controller.imagePath!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image,
            size: 30,
            color: Colors.grey.shade600,
          );
        },
      );
    } else {
      // 本地图片：移除 file:// 前缀（如果存在）
      final path =
          controller.imagePath!.startsWith('file://')
              ? controller.imagePath!.replaceFirst('file://', '')
              : controller.imagePath!;
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: 60, height: 60, fit: BoxFit.cover);
      }
    }

    return Icon(Icons.broken_image, size: 30, color: Colors.grey.shade600);
  }

  Future<void> _pickAndCropImage(BuildContext context) async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (context) => ImagePickerDialog(
              initialUrl: controller.imagePath,
              saveDirectory: 'goods_images',
              enableCrop: true, // 启用裁剪功能
              cropAspectRatio: 1, // 设置裁剪比例为1:1
            ),
      );

      if (result != null && result['url'] != null) {
        final path = result['url'];
        if (path.isNotEmpty) {
          // 删除旧图片（移除 file:// 前缀后再删除）
          if (controller.imagePath != null) {
            final oldPath =
                controller.imagePath!.startsWith('file://')
                    ? controller.imagePath!.replaceFirst('file://', '')
                    : controller.imagePath!;
            await ImageUtils.deleteImage(oldPath);
          }

          // 更新图片路径（保留 file:// 前缀）
          controller.imagePath =
              path.startsWith('file://') ? path : 'file://$path';
          onStateChanged();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('选择图片时出错: $e');
    }
  }
}
