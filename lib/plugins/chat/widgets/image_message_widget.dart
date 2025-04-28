import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../../../../utils/image_utils.dart';

class ImageMessageWidget extends StatelessWidget {
  final Message message;
  final bool isOutgoing;

  const ImageMessageWidget({
    super.key,
    required this.message,
    this.isOutgoing = false,
  });

  Map<String, dynamic>? get fileInfo =>
      message.metadata?[Message.metadataKeyFileInfo] as Map<String, dynamic>?;

  @override
  @override
  Widget build(BuildContext context) {
    if (fileInfo == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: _buildImageWidget(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.data ?? _buildErrorWidget(context, '未命名文件');
      },
    );
  }

  Future<Widget> _buildImageWidget(BuildContext context) async {
    if (fileInfo == null) {
      return const SizedBox.shrink();
    }

    final filePath = fileInfo!['path'] as String? ?? '';
    final fileName = fileInfo!['name'] as String? ?? '未命名文件';
    
    if (filePath.isEmpty) {
      return _buildErrorWidget(context, fileName);
    }

    String absolutePath;
    try {
      absolutePath = await ImageUtils.getAbsolutePath(filePath);
    } catch (e) {
      debugPrint('获取绝对路径失败: $e');
      return _buildErrorWidget(context, fileName);
    }

    final file = File(absolutePath);
    if (!await file.exists()) {
      return _buildErrorWidget(context, fileName);
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color:
            isOutgoing
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context, fileName);
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String fileName) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            '无法加载图片\n$fileName',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
