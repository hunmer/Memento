import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'image_picker_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/image_utils.dart';

class AvatarPicker extends StatefulWidget {
  final double size;
  final String username;
  final String? currentAvatarPath;
  final String saveDirectory;
  final Function(String path)? onAvatarChanged;

  const AvatarPicker({
    super.key,
    this.size = 80.0,
    required this.username,
    this.currentAvatarPath,
    this.saveDirectory = 'avatars',
    this.onAvatarChanged,
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
    if (oldWidget.currentAvatarPath != widget.currentAvatarPath) {
      setState(() {
        _avatarPath = widget.currentAvatarPath;
      });
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImagePickerDialog(
        initialUrl: _avatarPath,
        saveDirectory: widget.saveDirectory,
        enableCrop: true,
        cropAspectRatio: 1.0, // 强制使用1:1的裁剪比例
      ),
    );

    if (result != null) {
      final sourcePath = result['url'] as String;
      setState(() {
        _avatarPath = sourcePath;
      });

      // 重命名文件为随机文件名
      if (_avatarPath != null) {
        try {
          // 获取源文件的绝对路径
          final sourceAbsolutePath = await PathUtils.toAbsolutePath(_avatarPath!);
          final sourceFile = File(sourceAbsolutePath);
          
          // 确保文件存在
          if (await sourceFile.exists()) {
            // 获取应用文档目录
            final appDir = await getApplicationDocumentsDirectory();
            final avatarDir = Directory(path.join(appDir.path, 'app_data', widget.saveDirectory));
            if (!await avatarDir.exists()) {
              await avatarDir.create(recursive: true);
            }
            
            // 生成随机文件名
            final random = Random();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final randomString = List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
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
            final relativePath = await PathUtils.toRelativePath(newPath);
            setState(() {
              _avatarPath = relativePath;
            });

            // 通知父组件头像已更改
            widget.onAvatarChanged?.call(relativePath);
            
            debugPrint('Avatar saved successfully to: $newPath');
          } else {
            debugPrint('Source avatar file does not exist: $sourceAbsolutePath');
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
        child: _avatarPath != null
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
                        if (existsSnapshot.hasData && existsSnapshot.data == true) {
                          return ClipOval(
                            child: Image.file(
                              file,
                              key: ValueKey(file.path), // 添加key以确保更新
                              width: widget.size,
                              height: widget.size,
                              fit: BoxFit.cover,
                              cacheWidth: (widget.size * 2).toInt(), // 添加缓存控制
                              cacheHeight: (widget.size * 2).toInt(), // 添加缓存控制
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

  // 移除旧的 _getAbsolutePath 方法，因为现在使用 PathUtils 类
}