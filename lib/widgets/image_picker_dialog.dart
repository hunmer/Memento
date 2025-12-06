import 'dart:async';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/widgets/l10n/image_picker_localizations.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../utils/image_utils.dart';
import '../core/services/image_compression_service.dart';

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

  /// 是否启用图片压缩（默认关闭）
  final bool enableCompression;

  /// 缩略图保存路径（如果不指定则是保存的文件名+.thumb）
  final String? thumbnailPath;

  /// 压缩质量 0-100（默认 85）
  final int compressionQuality;

  const ImagePickerDialog({
    super.key,
    this.initialUrl,
    this.saveDirectory = 'app_images',
    this.enableCrop = false,
    this.cropAspectRatio,
    this.multiple = false,
    this.enableCompression = false,
    this.thumbnailPath,
    this.compressionQuality = 85,
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

  /// 处理图片压缩和缩略图生成
  ///
  /// [savedImagePath] 保存后的图片绝对路径
  /// [relativePath] 相对路径
  /// 返回包含原图和缩略图信息的 Map
  Future<Map<String, dynamic>> _processImageCompression(
    String savedImagePath,
    String relativePath,
  ) async {
    if (!widget.enableCompression) {
      // 不压缩，直接返回原图
      return {'url': relativePath, 'thumbUrl': null};
    }

    try {
      // 生成缩略图路径
      String thumbPath;
      if (widget.thumbnailPath != null && widget.thumbnailPath!.isNotEmpty) {
        thumbPath = widget.thumbnailPath!;
      } else {
        // 默认在原文件名后加 .thumb
        final dir = path.dirname(savedImagePath);
        final filename = path.basenameWithoutExtension(savedImagePath);
        final ext = path.extension(savedImagePath);
        thumbPath = path.join(dir, '$filename.thumb$ext');
      }

      // 使用压缩服务生成缩略图
      final compressionService = ImageCompressionService();
      final compressedPath = await compressionService.compressImage(
        sourcePath: savedImagePath,
        targetPath: thumbPath,
        quality: widget.compressionQuality,
      );

      debugPrint('缩略图已生成: $compressedPath');

      // 计算缩略图的相对路径
      final thumbRelativePath = await ImageUtils.toRelativePath(thumbPath);

      return {
        'url': relativePath,
        'thumbUrl': thumbRelativePath,
      };
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      // 失败时返回原图
      return {'url': relativePath, 'thumbUrl': null};
    }
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
            decoration: InputDecoration(
              labelText: ImagePickerLocalizations.of(context)!.selectImage,
              hintText: ImagePickerLocalizations.of(context)!.chooseFromGallery,
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
                      debugPrint('开始选择图片...');
                      final List<XFile> images =
                          widget.multiple
                              ? (await _picker.pickMultiImage())
                              : [
                                await _picker.pickImage(
                                  source: ImageSource.gallery,
                                ),
                              ].whereType<XFile>().toList();

                      debugPrint('图片选择完成，数量: ${images.length}');

                      if (images.isNotEmpty) {
                        final results = <Map<String, dynamic>>[];

                        for (final image in images) {
                          try {
                            debugPrint('处理图片: ${image.path}');

                            // 保存图片并获取相对路径
                            final relativePath = await ImageUtils.saveImage(
                              File(image.path),
                              widget.saveDirectory,
                            );
                            debugPrint('图片保存完成，相对路径: $relativePath');

                            // 获取保存后的文件路径
                            final savedImagePath =
                                await ImageUtils.getAbsolutePath(relativePath);
                            final savedImage = File(savedImagePath);

                            // 确认文件是否成功保存
                            final fileExists = await savedImage.exists();
                            debugPrint(
                              '图片保存路径: $savedImagePath, 文件是否存在: $fileExists',
                            );

                            if (!fileExists) {
                              throw Exception('文件保存后检查不存在: $savedImagePath');
                            }

                            // 读取图片字节数据
                            final bytes = await File(image.path).readAsBytes();
                            debugPrint('图片字节大小: ${bytes.length}');

                            // 如果启用了裁剪功能，显示裁剪对话框
                            if (widget.enableCrop && context.mounted) {
                              debugPrint('启用裁剪，显示裁剪对话框...');
                              final result = await _showCropDialog(
                                context,
                                bytes,
                                savedImage.path,
                                relativePath,
                              );
                              if (result != null) {
                                debugPrint('裁剪完成');
                                results.add(result);
                              } else {
                                debugPrint('裁剪被取消');
                              }
                            } else {
                              debugPrint('处理压缩和缩略图...');
                              // 处理压缩和缩略图
                              final compressionResult = await _processImageCompression(
                                savedImagePath,
                                relativePath,
                              );
                              debugPrint('压缩结果: ${compressionResult.keys}');
                              results.add({
                                ...compressionResult,
                                'bytes': bytes,
                              });
                            }
                          } catch (e) {
                            debugPrint('处理单张图片时发生错误: $e');
                            rethrow;
                          }
                        }

                        debugPrint('所有图片处理完成，结果数量: ${results.length}');
                        if (results.isNotEmpty && context.mounted) {
                          final result = widget.multiple ? results : results.first;
                          debugPrint('返回结果，类型: ${widget.multiple ? "多张" : "单张"}');
                          Navigator.of(
                            context,
                          ).pop(result);
                        } else {
                          debugPrint('警告: 结果为空或上下文未挂载');
                        }
                      } else {
                        debugPrint('用户未选择图片');
                      }
                    } catch (e, stackTrace) {
                      debugPrint('选择图片发生异常: $e');
                      debugPrint('异常堆栈: $stackTrace');
                      if (context.mounted) {
                        Toast.error(
                          '${ImagePickerLocalizations.of(context)!.selectImageFailed}: $e',
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
                      debugPrint('开始调用相机...');
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      debugPrint('相机调用完成: ${photo != null}');

                      if (photo != null) {
                        final results = <Map<String, dynamic>>[];
                        try {
                          debugPrint('开始保存图片...');

                          // 保存图片并获取相对路径
                          final relativePath = await ImageUtils.saveImage(
                            File(photo.path),
                            widget.saveDirectory,
                          );
                          debugPrint('图片保存完成，相对路径: $relativePath');

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

                          if (!fileExists) {
                            throw Exception('文件保存后检查不存在: $savedImagePath');
                          }

                          // 读取图片字节数据
                          final bytes = await File(photo.path).readAsBytes();
                          debugPrint('原始图片字节大小: ${bytes.length}');

                          // 如果启用了裁剪功能，显示裁剪对话框
                          if (widget.enableCrop && context.mounted) {
                            debugPrint('启用裁剪，显示裁剪对话框...');
                            final result = await _showCropDialog(
                              context,
                              bytes,
                              savedImage.path,
                              relativePath,
                            );
                            if (result != null) {
                              debugPrint('裁剪完成，结果: ${result.keys}');
                              results.add(result);
                            } else {
                              debugPrint('裁剪被取消');
                            }
                          } else {
                            debugPrint('处理压缩和缩略图...');
                            // 处理压缩和缩略图
                            final compressionResult = await _processImageCompression(
                              savedImagePath,
                              relativePath,
                            );
                            debugPrint('压缩结果: ${compressionResult.keys}');
                            results.add({
                              ...compressionResult,
                              'bytes': bytes,
                            });
                          }

                          if (results.isNotEmpty) {
                            debugPrint('准备返回结果，results数量: ${results.length}');
                            if (context.mounted) {
                              debugPrint('上下文已挂载，关闭对话框');
                              // 单张图片时返回单个结果，与相册选择一致
                              final result = results.first;
                              debugPrint('返回单个结果: ${result.keys}');
                              Navigator.of(context).pop(result);
                            } else {
                              debugPrint('警告: 上下文未挂载，无法关闭对话框');
                            }
                          } else {
                            debugPrint('错误: 结果为空');
                          }
                        } catch (e) {
                          debugPrint('处理图片时发生错误: $e');
                          rethrow;
                        }
                      } else {
                        debugPrint('用户取消拍照');
                      }
                    } catch (e, stackTrace) {
                      debugPrint('拍照过程发生异常: $e');
                      debugPrint('异常堆栈: $stackTrace');
                      if (context.mounted) {
                        Toast.error(
                          '${ImagePickerLocalizations.of(context)!.takePhotoFailed}: $e',
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
    String originalRelativePath,
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

                                // 处理压缩和缩略图
                                final savedImagePath = await ImageUtils.getAbsolutePath(
                                  relativePath,
                                );
                                final compressionResult = await _processImageCompression(
                                  savedImagePath,
                                  relativePath,
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  completer.complete({
                                    ...compressionResult,
                                    'bytes': croppedImage,
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Toast.error(
                                    ImagePickerLocalizations.of(
                                      context,
                                    )!.saveCroppedImageFailed,
                                  );
                                }
                                completer.complete(null);
                              }
                            case CropFailure():
                              if (context.mounted) {
                                Toast.error(
                                  ImagePickerLocalizations.of(
                                    context,
                                  )!.cropFailed,
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
