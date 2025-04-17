import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImagePickerDialog extends StatefulWidget {
  final String? initialUrl;

  const ImagePickerDialog({super.key, this.initialUrl});

  @override
  State<ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<ImagePickerDialog> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _urlController;
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _validateUrl(_urlController.text);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl(String url) {
    setState(() {
      _isValidUrl =
          url.isNotEmpty &&
          (url.startsWith('http://') || url.startsWith('https://'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择图片'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 在线URL输入
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: '图片URL',
              hintText: '输入在线图片地址',
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: _validateUrl,
          ),
          const SizedBox(height: 16),
          // 本地图片选择按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('从相册选择'),
                  onPressed: () async {
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        // 获取应用文档目录
                        final appDir = await getApplicationDocumentsDirectory();
                        final goodsImagesDir = Directory(
                          path.join(appDir.path, 'goods_images'),
                        );
                        if (!await goodsImagesDir.exists()) {
                          await goodsImagesDir.create(recursive: true);
                        }

                        // 生成唯一文件名
                        final fileName =
                            '${const Uuid().v4()}${path.extension(image.path)}';
                        final savedImage = File(
                          path.join(goodsImagesDir.path, fileName),
                        );

                        // 复制图片到应用目录
                        await File(image.path).copy(savedImage.path);

                        // 读取图片字节数据
                        final bytes = await File(image.path).readAsBytes();

                        // 返回本地文件路径和字节数据
                        Navigator.of(context).pop({
                          'url': 'file://${savedImage.path}',
                          'bytes': bytes,
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍摄照片'),
                  onPressed: () async {
                    try {
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (photo != null) {
                        // 获取应用文档目录
                        final appDir = await getApplicationDocumentsDirectory();
                        final goodsImagesDir = Directory(
                          path.join(appDir.path, 'goods_images'),
                        );
                        if (!await goodsImagesDir.exists()) {
                          await goodsImagesDir.create(recursive: true);
                        }

                        // 生成唯一文件名
                        final fileName =
                            '${const Uuid().v4()}${path.extension(photo.path)}';
                        final savedImage = File(
                          path.join(goodsImagesDir.path, fileName),
                        );

                        // 复制图片到应用目录
                        await File(photo.path).copy(savedImage.path);

                        // 读取图片字节数据
                        final bytes = await File(photo.path).readAsBytes();

                        // 返回本地文件路径和字节数据
                        Navigator.of(context).pop({
                          'url': 'file://${savedImage.path}',
                          'bytes': bytes,
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('拍摄照片失败: $e')));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed:
              _isValidUrl
                  ? () => Navigator.of(
                    context,
                  ).pop({'url': _urlController.text, 'bytes': null})
                  : null,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
