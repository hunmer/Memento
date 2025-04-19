import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data'; // 添加这个导入以使用 Uint8List
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  static Future<Uint8List> compressImage(
    Uint8List imageData, {
    int maxWidth = 800,
    int quality = 85,
  }) async {
    try {
      // 解码图片
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 计算新的宽度和高度，保持宽高比
      double ratio = originalImage.width / originalImage.height;
      int targetWidth = originalImage.width;

      if (targetWidth > maxWidth) {
        targetWidth = maxWidth;
        // 我们实际上并不需要存储 targetHeight，因为在这个函数中没有使用它
        // 如果将来需要使用，可以在需要时计算：(maxWidth / ratio).round()
      }

      // 创建缩放后的图片
      final ui.Image resizedImage = await originalImage
          .toByteData(format: ui.ImageByteFormat.rawRgba)
          .then((byteData) async {
            final completer = Completer<ui.Image>();
            ui.decodeImageFromPixels(
              byteData!.buffer.asUint8List(),
              originalImage.width,
              originalImage.height,
              ui.PixelFormat.rgba8888,
              completer.complete,
            );
            return completer.future;
          });

      // 将图片编码为PNG格式
      final byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final compressedData = byteData!.buffer.asUint8List();

      // 释放资源
      originalImage.dispose();
      resizedImage.dispose();

      return compressedData;
    } catch (e) {
      debugPrint('压缩图片失败: $e');
      return imageData; // 如果压缩失败，返回原图
    }
  }

  static Future<String> saveImage(Uint8List imageData) async {
    try {
      // 压缩图片
      final compressedData = await compressImage(imageData);

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();

      // 创建商品图片存储目录
      final goodsImageDir = Directory('${appDir.path}/goods_images');
      if (!await goodsImageDir.exists()) {
        await goodsImageDir.create(recursive: true);
      }

      // 生成唯一的文件名
      final fileName = 'goods_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = path.join(goodsImageDir.path, fileName);

      // 保存裁剪后的图片到永久存储
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(compressedData);

      return imageFile.path;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      // 如果永久存储失败，回退到临时存储
      final tempDir = await Directory.systemTemp.createTemp('cropped_images');
      final tempFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await tempFile.writeAsBytes(imageData);
      return tempFile.path;
    }
  }

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        imagePath.contains('goods_images')) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('删除图片失败: $e');
      }
    }
  }
}
