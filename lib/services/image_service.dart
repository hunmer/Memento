import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../core/storage/storage_manager.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  // 检查当前平台是否是移动平台
  bool get isMobilePlatform =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  // 从相册选择图片
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // 使用相机拍照
  Future<File?> takePhoto() async {
    if (!isMobilePlatform) {
      return null; // 非移动平台不支持拍照
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (photo != null) {
      return File(photo.path);
    }
    return null;
  }

  // 保存图片到应用目录
  Future<String> saveImage(File imageFile) async {
    final directory = await StorageManager.getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/chat_images');

    // 确保目录存在
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // 生成唯一文件名
    final uuid = Uuid();
    final fileName = '${uuid.v4()}${path.extension(imageFile.path)}';

    // 保存文件
    await imageFile.copy('${imagesDir.path}/$fileName');

    // 返回相对路径，可用于存储在消息中
    return 'chat_images/$fileName';
  }

  // 获取图片的完整路径
  Future<String> getImageFullPath(String relativePath) async {
    final directory = await StorageManager.getApplicationDocumentsDirectory();
    return '${directory.path}/$relativePath';
  }

  // 显示图片选择对话框
  Future<File?> showImagePickerDialog(BuildContext context) async {
    File? imageFile;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择图片'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () async {
                    Navigator.pop(context);
                    imageFile = await pickImageFromGallery();
                  },
                ),
                if (isMobilePlatform)
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('拍照'),
                    onTap: () async {
                      Navigator.pop(context);
                      imageFile = await takePhoto();
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
    );

    return imageFile;
  }
}
