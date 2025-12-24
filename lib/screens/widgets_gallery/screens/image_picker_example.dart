import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';

/// 图片选择器示例
class ImagePickerExample extends StatefulWidget {
  const ImagePickerExample({super.key});

  @override
  State<ImagePickerExample> createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  String? selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ImagePickerDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个图片选择器对话框，支持相册和相机。'),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: selectedImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(selectedImagePath!),
                      )
                    : _buildDefaultPreview(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImagePicker,
                icon: const Icon(Icons.image),
                label: const Text('选择图片'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ImagePickerDialog(),
    );
    if (result != null) {
      setState(() {
        selectedImagePath = result['url'] as String;
      });
    }
  }

  Widget _buildImage(String url) {
    // 网络图片
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 50),
          );
        },
      );
    }

    // 本地图片（相对路径）
    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Icon(Icons.broken_image, size: 50),
          );
        }

        final file = File(snapshot.data!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 50),
              );
            },
          );
        }

        return const Center(
          child: Icon(Icons.broken_image, size: 50),
        );
      },
    );
  }

  Widget _buildDefaultPreview() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            '未选择图片',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
