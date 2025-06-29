import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/widgets/file_preview/l10n/file_preview_localizations.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'video_preview.dart';

class FilePreviewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final bool isVideo;

  const FilePreviewScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.isVideo = false,
  });

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
    _isVideo = widget.isVideo || widget.mimeType.startsWith('video/');
    _resolveFilePath();
  }

  Future<void> _resolveFilePath() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 解码 URI 编码的路径
      String resolvedPath = Uri.decodeFull(widget.filePath);

      // 统一路径分隔符为系统分隔符
      resolvedPath = resolvedPath
          .replaceAll('/', path.separator)
          .replaceAll(r'\\', path.separator);

      // 如果是相对路径（不是以系统分隔符开头），则转换为绝对路径
      if (!path.isAbsolute(resolvedPath)) {
        // 移除可能的 './' 前缀
        if (resolvedPath.startsWith('./') ||
            resolvedPath.startsWith('.${path.separator}')) {
          resolvedPath = resolvedPath.substring(2);
        }

        // 获取应用文档目录作为基础路径
        final appDocDir =
            await StorageManager.getApplicationDocumentsDirectory();
        String appDirPath = appDocDir.path;

        // 如果路径包含 app_data，确保正确处理
        if (!resolvedPath.contains('app_data')) {
          appDirPath = path.join(appDirPath, 'app_data');
        }

        resolvedPath = path.join(appDirPath, resolvedPath);
      }

      // 规范化路径（处理 .. 和 . 等特殊路径）
      _absoluteFilePath = path.normalize(resolvedPath);

      // 验证文件是否存在
      final file = File(_absoluteFilePath);
      final fileExists = await file.exists();
      debugPrint('文件路径: $_absoluteFilePath');
      if (!fileExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(FilePreviewLocalizations.of(context)!.fileNotExist),
            ),
          );
          // 清空文件路径，这样 _buildPreviewContent 会显示错误界面
          setState(() {
            _absoluteFilePath = '';
          });
        }
      } else {
        // 文件存在，更新状态
        setState(() {
          _absoluteFilePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FilePreviewLocalizations.of(context)!.errorFilePreviewFailed +
                  e.toString(),
            ),
          ),
        );
        // 出错时也清空文件路径
        setState(() {
          _absoluteFilePath = '';
        });
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
      final file = File(_absoluteFilePath);
      if (await file.exists()) {
        // 使用绝对路径而不是相对路径来分享文件
        await Share.shareXFiles([
          XFile(_absoluteFilePath),
        ], text: '分享文件：${widget.fileName}');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(FilePreviewLocalizations.of(context)!.fileNotExist),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FilePreviewLocalizations.of(context)!.errorFilePreviewFailed +
                  e.toString(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showInFolder() async {
    try {
      final file = File(_absoluteFilePath);
      if (await file.exists()) {
        if (Platform.isAndroid || Platform.isIOS) {
          // 移动端显示文件信息
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(FilePreviewLocalizations.of(context)!.name),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FilePreviewLocalizations.of(context)!.name +
                            ': ' +
                            widget.fileName,
                      ),
                      Text(_absoluteFilePath),
                      Text(
                        FilePreviewLocalizations.of(context)!.fileSize +
                            ': ' +
                            _formatFileSize(widget.fileSize),
                      ),
                      Text(
                        FilePreviewLocalizations.of(context)!.fileType +
                            ': ' +
                            widget.mimeType,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.ok),
                    ),
                  ],
                ),
          );
        } else {
          // TODO: 桌面端打开文件所在文件夹
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(FilePreviewLocalizations.of(context)!.fileNotExist),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_absoluteFilePath.isEmpty || !File(_absoluteFilePath).existsSync()) {
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
            Text(
              FilePreviewLocalizations.of(context)!.errorFilePreviewFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              FilePreviewLocalizations.of(context)!.fileNotExist,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '文件路径: ${_absoluteFilePath.isEmpty ? "未设置" : _absoluteFilePath}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
                  Text(
                    FilePreviewLocalizations.of(
                      context,
                    )!.errorFilePreviewFailed,
                  ),
                ],
              ),
            ),
      );
    } else if (_isVideo) {
      try {
        return VideoPreview(filePath: _absoluteFilePath);
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                FilePreviewLocalizations.of(context)!.errorFilePreviewFailed,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                FilePreviewLocalizations.of(context)!.previewNotAvailable,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _shareFile,
                child: Text(
                  FilePreviewLocalizations.of(context)!.openWithOtherApp,
                ),
              ),
            ],
          ),
        );
      }
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
