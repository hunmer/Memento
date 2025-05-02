import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/image_utils.dart';

class ImagePickerDialog extends StatefulWidget {
  final String? initialUrl;

  /// 图片保存的目录名称，默认为 'app_images'
  final String saveDirectory;

  /// 是否启用图片裁剪功能
  final bool enableCrop;

  /// 裁剪比例，仅在 enableCrop 为 true 时生效
  final double? cropAspectRatio;

  const ImagePickerDialog({
    super.key,
    this.initialUrl,
    this.saveDirectory = 'app_images',
    this.enableCrop = false,
    this.cropAspectRatio,
  });

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
                        // 保存图片并获取相对路径
                        final relativePath =
                            await ImageUtils.saveImageToAppDirectory(
                              File(image.path),
                              widget.saveDirectory,
                            );

                        // 获取保存后的文件路径
                        final savedImagePath = await ImageUtils.getAbsolutePath(
                          relativePath,
                        );
                        final savedImage = File(savedImagePath);

                        // 确认文件是否成功保存
                        final fileExists = await savedImage.exists();
                        debugPrint(
                          '图片保存路径: $savedImagePath, 文件是否存在: $fileExists',
                        );

                        // 读取图片字节数据
                        final bytes = await File(image.path).readAsBytes();

                        // 如果启用了裁剪功能，显示裁剪对话框
                        if (widget.enableCrop && context.mounted) {
                          await _showCropDialog(
                            context,
                            bytes,
                            savedImage.path,
                          );
                        } else {
                          // 返回相对路径和字节数据
                          Navigator.of(
                            context,
                          ).pop({'url': relativePath, 'bytes': bytes});
                        }
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
                        // 保存图片并获取相对路径
                        final relativePath =
                            await ImageUtils.saveImageToAppDirectory(
                              File(photo.path),
                              widget.saveDirectory,
                            );

                        // 获取保存后的文件路径
                        final savedImagePath = await ImageUtils.getAbsolutePath(
                          relativePath,
                        );
                        final savedImage = File(savedImagePath);

                        // 确认文件是否成功保存
                        final fileExists = await savedImage.exists();
                        debugPrint(
                          '图片保存路径: $savedImagePath, 文件是否存在: $fileExists',
                        );

                        // 读取图片字节数据
                        final bytes = await File(photo.path).readAsBytes();

                        // 如果启用了裁剪功能，显示裁剪对话框
                        if (widget.enableCrop && context.mounted) {
                          await _showCropDialog(
                            context,
                            bytes,
                            savedImage.path,
                          );
                        } else {
                          // 返回相对路径和字节数据
                          Navigator.of(
                            context,
                          ).pop({'url': relativePath, 'bytes': bytes});
                        }
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

  Future<void> _showCropDialog(
    BuildContext context,
    Uint8List imageBytes,
    String originalImagePath,
  ) async {
    final cropController = CropController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '裁剪图片',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Crop(
                        controller: cropController,
                        image: imageBytes,
                        aspectRatio: widget.cropAspectRatio,
                        onCropped: (result) async {
                          switch (result) {
                            case CropSuccess(:final croppedImage):
                              try {
                                // 删除原始图片
                                final originalFile = File(originalImagePath);
                                if (await originalFile.exists()) {
                                  await originalFile.delete();
                                }

                                // 保存裁剪后的图片并获取相对路径
                                final relativePath =
                                    await ImageUtils.saveBytesToAppDirectory(
                                      croppedImage,
                                      widget.saveDirectory,
                                    );

                                // 返回新的文件路径和字节数据
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop({
                                    'url': relativePath,
                                    'bytes': croppedImage,
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('保存裁剪图片失败: $e')),
                                  );
                                }
                              }
                            case CropFailure(:final cause):
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('裁剪失败: $cause')),
                                );
                              }
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              // 获取原始图片的相对路径
                              final relativePath = await ImageUtils.getAbsolutePath(originalImagePath);

                              Navigator.of(
                                context,
                              ).pop({'url': relativePath, 'bytes': imageBytes});
                            },
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => cropController.crop(),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
