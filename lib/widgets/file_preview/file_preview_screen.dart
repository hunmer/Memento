import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'video_preview.dart';

class FilePreviewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;

  const FilePreviewScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  }) : super(key: key);

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  late bool _isImage;
  late bool _isVideo;
  String _absoluteFilePath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isImage = widget.mimeType.startsWith('image/');
    _isVideo = widget.mimeType.startsWith('video/');
    _resolveFilePath();
  }

  Future<void> _resolveFilePath() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 检查路径是否为相对路径（以./开头）
      if (widget.filePath.startsWith('./')) {
        // 使用 path_provider 获取应用文档目录作为基础路径
        final appDocDir = await getApplicationDocumentsDirectory();
        // 移除相对路径的 './' 前缀，然后拼接到应用文档目录
        final relativePath = widget.filePath.substring(2); // 去掉 './'
        _absoluteFilePath = path.join(appDocDir.path, relativePath);
      } else {
        _absoluteFilePath = widget.filePath;
      }

      // 验证文件是否存在
      final file = File(_absoluteFilePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('文件不存在或无法访问')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('文件路径解析错误: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _shareFile() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(widget.filePath),
        ], text: '分享文件：${widget.fileName}');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('文件不存在')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    }
  }

  Future<void> _showInFolder() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        if (Platform.isAndroid || Platform.isIOS) {
          // 移动端显示文件信息
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('文件信息'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('文件名：${widget.fileName}'),
                      Text('路径：${widget.filePath}'),
                      Text('大小：${_formatFileSize(widget.fileSize)}'),
                      Text('类型：${widget.mimeType}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确定'),
                    ),
                  ],
                ),
          );
        } else {
          // TODO: 桌面端打开文件所在文件夹
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('文件不存在')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    }
  }

  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_absoluteFilePath.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('无法加载文件', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '文件路径解析失败或文件不存在',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_isImage) {
      return PhotoView(
        imageProvider: FileImage(File(_absoluteFilePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        loadingBuilder:
            (context, event) => Center(
              child: CircularProgressIndicator(
                value:
                    event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
              ),
            ),
        errorBuilder:
            (context, error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 72,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('图片加载失败'),
                ],
              ),
            ),
      );
    } else if (_isVideo) {
      return VideoPreview(filePath: _absoluteFilePath);
    } else {
      // 普通文件预览
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 72,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                widget.fileName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatFileSize(widget.fileSize),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.mimeType,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '打开文件位置',
            onPressed: _showInFolder,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享文件',
            onPressed: _shareFile,
          ),
        ],
      ),
      body: _buildPreviewContent(),
    );
  }
}
