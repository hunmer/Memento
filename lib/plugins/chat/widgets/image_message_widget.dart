import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message.dart';

class ImageMessageWidget extends StatelessWidget {
  final Message message;
  final bool isOutgoing;

  const ImageMessageWidget({
    Key? key,
    required this.message,
    this.isOutgoing = false,
  }) : super(key: key);

  Map<String, dynamic>? get fileInfo =>
      message.metadata?[Message.metadataKeyFileInfo] as Map<String, dynamic>?;

  @override
  Widget build(BuildContext context) {
    if (fileInfo == null) {
      return const SizedBox.shrink();
    }

    final filePath = fileInfo!['filePath'] as String;
    final fileName = fileInfo!['fileName'] as String;
    final file = File(filePath);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: isOutgoing
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorWidget(context, fileName);
                },
              )
            : _buildErrorWidget(context, fileName),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String fileName) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            '无法加载图片\n$fileName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}