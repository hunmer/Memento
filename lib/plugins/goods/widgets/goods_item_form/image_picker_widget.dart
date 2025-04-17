import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// 条件导入，只在Web平台导入dart:html
import 'image_picker_web.dart' if (dart.library.io) 'image_picker_mobile.dart';

class ImagePickerWidget extends StatelessWidget {
  final String? imagePath;
  final Function(String) onImageSelected;

  const ImagePickerWidget({
    Key? key,
    this.imagePath,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _pickImage(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child:
                imagePath != null
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
    );
  }

  Widget _buildImage() {
    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imagePath!,
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
      // 本地图片
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(file, width: 60, height: 60, fit: BoxFit.cover);
      } else {
        return Icon(Icons.broken_image, size: 30, color: Colors.grey.shade600);
      }
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final imageUrl = await handlePickedImage(pickedFile);
        if (imageUrl != null) {
          onImageSelected(imageUrl);
        }
      }
    } catch (e) {
      // 显示错误提示
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
