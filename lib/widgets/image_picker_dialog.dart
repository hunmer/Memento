import 'dart:async';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/widgets/l10n/image_picker_localizations.dart';
import 'package:Memento/widgets/l10n/image_picker_localizations_en.dart';
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

  /// 是否允许多图片选择
  final bool multiple;

  const ImagePickerDialog({
    super.key,
    this.initialUrl,
    this.saveDirectory = 'app_images',
    this.enableCrop = false,
    this.cropAspectRatio,
    this.multiple = false,
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
      title: Text(
        widget.multiple
            ? ImagePickerLocalizations.of(context)!.selectMultipleImages
            : ImagePickerLocalizations.of(context)!.selectImage,
      ),
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
                  label: Text(
                    ImagePickerLocalizations.of(context)!.selectFromGallery,
                  ),
                  onPressed: () async {
                    try {
                      final List<XFile> images =
                          widget.multiple
                              ? (await _picker.pickMultiImage())
                              : [
                                await _picker.pickImage(
                                  source: ImageSource.gallery,
                                ),
                              ].whereType<XFile>().toList();

                      if (images.isNotEmpty) {
                        final results = <Map<String, dynamic>>[];

                        for (final image in images) {
                          // 保存图片并获取相对路径
                          final relativePath = await ImageUtils.saveImage(
                            File(image.path),
                            widget.saveDirectory,
                          );

                          // 获取保存后的文件路径
                          final savedImagePath =
                              await ImageUtils.getAbsolutePath(relativePath);
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
                            final result = await _showCropDialog(
                              context,
                              bytes,
                              savedImage.path,
                            );
                            if (result != null) {
                              results.add(result);
                            }
                          } else {
                            results.add({'url': relativePath, 'bytes': bytes});
                          }
                        }

                        if (results.isNotEmpty && context.mounted) {
                          Navigator.of(
                            context,
                          ).pop(widget.multiple ? results : results.first);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ImagePickerLocalizations.of(
                                context,
                              )!.selectImageFailed,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(ImagePickerLocalizations.of(context)!.takePhoto),
                  onPressed: () async {
                    try {
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (photo != null) {
                        final results = <Map<String, dynamic>>[];

                        // 保存图片并获取相对路径
                        final relativePath = await ImageUtils.saveImage(
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
                          final result = await _showCropDialog(
                            context,
                            bytes,
                            savedImage.path,
                          );
                          if (result != null) {
                            results.add(result);
                          }
                        } else {
                          results.add({'url': relativePath, 'bytes': bytes});
                        }

                        if (results.isNotEmpty && context.mounted) {
                          Navigator.of(context).pop(results);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ImagePickerLocalizations.of(
                                context,
                              )!.takePhotoFailed,
                            ),
                          ),
                        );
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed:
              _isValidUrl
                  ? () => Navigator.of(
                    context,
                  ).pop({'url': _urlController.text, 'bytes': null})
                  : null,
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _showCropDialog(
    BuildContext context,
    Uint8List imageBytes,
    String originalImagePath,
  ) async {
    final cropController = CropController();
    final completer = Completer<Map<String, dynamic>?>();

    if (!context.mounted) {
      return null;
    }

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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        ImagePickerLocalizations.of(context)!.cropImage,
                        style: const TextStyle(
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
                                final originalFile = File(originalImagePath);
                                if (await originalFile.exists()) {
                                  await originalFile.delete();
                                }

                                final relativePath =
                                    await ImageUtils.saveBytesToAppDirectory(
                                      croppedImage,
                                      widget.saveDirectory,
                                    );

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  completer.complete({
                                    'url': relativePath,
                                    'bytes': croppedImage,
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ImagePickerLocalizations.of(
                                          context,
                                        )!.saveCroppedImageFailed,
                                      ),
                                    ),
                                  );
                                }
                                completer.complete(null);
                              }
                            case CropFailure(:final cause):
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ImagePickerLocalizations.of(
                                        context,
                                      )!.cropFailed,
                                    ),
                                  ),
                                );
                              }
                              completer.complete(null);
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
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              final relativePath =
                                  await ImageUtils.getAbsolutePath(
                                    originalImagePath,
                                  );
                              completer.complete({
                                'url': relativePath,
                                'bytes': imageBytes,
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => cropController.crop(),
                            child: Text(AppLocalizations.of(context)!.confirm),
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

    return completer.future;
  }
}
