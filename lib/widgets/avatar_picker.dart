import 'dart:io';
import 'dart:math';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'image_picker_dialog.dart';
import 'package:path/path.dart' as path;
import '../utils/image_utils.dart';

class AvatarPicker extends StatefulWidget {
  final double size;
  final String username;
  final String? currentAvatarPath;
  final String saveDirectory;
  final Function(String path)? onAvatarChanged;
  final Future<Map<String, dynamic>?> Function(
    BuildContext context,
    String? initialPath,
  )?
  showPickerDialog;

  const AvatarPicker({
    super.key,
    this.size = 80.0,
    required this.username,
    this.currentAvatarPath,
    this.saveDirectory = 'avatars',
    this.onAvatarChanged,
    this.showPickerDialog,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.currentAvatarPath;
  }

  @override
  void didUpdateWidget(AvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在路径确实发生变化，且不是当前选择的路径时更新
    if (oldWidget.currentAvatarPath != widget.currentAvatarPath &&
        _avatarPath != widget.currentAvatarPath) {
      // 清除可能的缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _avatarPath = widget.currentAvatarPath;
      });
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    // 使用外部提供的对话框打开方法或默认方法
    final result =
        widget.showPickerDialog != null
            ? await widget.showPickerDialog!(context, _avatarPath)
            : await showDialog<Map<String, dynamic>>(
              context: context,
              builder:
                  (context) => ImagePickerDialog(
                    initialUrl: _avatarPath,
                    saveDirectory: widget.saveDirectory,
                    enableCrop: true,
                    cropAspectRatio: 1.0, // 强制使用1:1的裁剪比例
                  ),
            );

    if (result != null) {
      final sourcePath = result['url'] as String;

      // 清除图片缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _avatarPath = sourcePath;
      });

      // 重命名文件为随机文件名
      if (_avatarPath != null) {
        try {
          // 获取源文件的绝对路径
          final sourceAbsolutePath = await ImageUtils.getAbsolutePath(
            _avatarPath!,
          );
          final sourceFile = File(sourceAbsolutePath);

          // 确保文件存在
          if (await sourceFile.exists()) {
            // 获取应用文档目录
            final appDir =
                await StorageManager.getApplicationDocumentsDirectory();
            final avatarDir = Directory(
              path.join(appDir.path, 'app_data', widget.saveDirectory),
            );
            if (!await avatarDir.exists()) {
              await avatarDir.create(recursive: true);
            }

            // 生成随机文件名
            final random = Random();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final randomString =
                List.generate(
                  8,
                  (_) => random.nextInt(16).toRadixString(16),
                ).join();
            final newFileName = '$timestamp-$randomString.jpg';
            final newPath = path.join(avatarDir.path, newFileName);

            // 如果目标文件已存在，先删除
            final newFile = File(newPath);
            if (await newFile.exists()) {
              await newFile.delete();
            }

            // 复制文件到新位置
            await sourceFile.copy(newPath);

            // 转换为相对路径并更新状态
            final relativePath = await ImageUtils.toRelativePath(newPath);
            setState(() {
              _avatarPath = relativePath;
            });

            // 通知父组件头像已更新
            widget.onAvatarChanged?.call(relativePath);

            debugPrint('Avatar saved successfully to: $newPath');
          } else {
            debugPrint(
              'Source avatar file does not exist: $sourceAbsolutePath',
            );
          }
        } catch (e) {
          debugPrint('Error processing avatar file: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child:
            _avatarPath != null
                ? FutureBuilder<String>(
                  key: ValueKey(_avatarPath), // 添加key以确保更新
                  future: ImageUtils.getAbsolutePath(_avatarPath!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final file = File(snapshot.data!);
                      return FutureBuilder<bool>(
                        key: ValueKey(snapshot.data), // 添加key以确保更新
                        future: file.exists(),
                        builder: (context, existsSnapshot) {
                          if (existsSnapshot.hasData &&
                              existsSnapshot.data == true) {
                            return ClipOval(
                              child: Image.file(
                                file,
                                key: ValueKey(
                                  '${file.path}?ts=${DateTime.now().millisecondsSinceEpoch}',
                                ), // 添加时间戳确保更新
                                width: widget.size,
                                height: widget.size,
                                fit: BoxFit.cover,
                                cacheWidth: (widget.size * 2).toInt(),
                                cacheHeight: (widget.size * 2).toInt(),
                                gaplessPlayback: true, // 无缝播放，避免闪烁
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading avatar: $error');
                                  return _buildDefaultAvatar();
                                },
                              ),
                            );
                          }
                          return _buildDefaultAvatar();
                        },
                      );
                    }
                    return _buildDefaultAvatar();
                  },
                )
                : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: widget.size * 0.5,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
