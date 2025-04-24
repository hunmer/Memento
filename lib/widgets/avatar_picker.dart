import 'dart:io';
import 'package:flutter/material.dart';
import 'image_picker_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      setState(() {
        _avatarPath = result['url'] as String;
      });

      // 重命名文件为用户名.jpg
      if (_avatarPath != null) {
        try {
          // 确保目录存在
          final appDir = await getApplicationDocumentsDirectory();
          final avatarDir = Directory(path.join(appDir.path, 'app_data', widget.saveDirectory));
          if (!await avatarDir.exists()) {
            await avatarDir.create(recursive: true);
          }
          
          // 获取当前文件的绝对路径
          final currentFilePath = await _getAbsolutePath(_avatarPath!);
          final currentFile = File(currentFilePath);
          
          // 确保文件存在
          if (await currentFile.exists()) {
            final newFileName = '${widget.username}.jpg';
            final newPath = path.join(
              avatarDir.path,
              newFileName,
            );
            
            // 如果目标文件已存在，先删除
            final newFile = File(newPath);
            if (await newFile.exists()) {
              await newFile.delete();
            }
            
            // 复制而不是重命名，确保文件存在
            await currentFile.copy(newPath);
            
            // 更新头像路径
            final relativePath = './${widget.saveDirectory}/$newFileName';
            setState(() {
              _avatarPath = relativePath;
            });

            // 通知父组件头像已更改
            widget.onAvatarChanged?.call(relativePath);
            
            debugPrint('Avatar saved successfully to: $newPath');
          } else {
            debugPrint('Source avatar file does not exist: $currentFilePath');
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
                future: _getAbsolutePath(_avatarPath!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final file = File(snapshot.data!);
                    return FutureBuilder<bool>(
                      future: file.exists(),
                      builder: (context, existsSnapshot) {
                        if (existsSnapshot.hasData && existsSnapshot.data == true) {
                          return ClipOval(
                            child: Image.file(
                              file,
                              width: widget.size,
                              height: widget.size,
                              fit: BoxFit.cover,
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

  Future<String> _getAbsolutePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    
    // 规范化路径，确保使用正确的路径分隔符
    String normalizedPath = relativePath.replaceFirst('./', '');
    normalizedPath = normalizedPath.replaceAll('/', path.separator);
    
    // 检查是否需要添加app_data前缀
    if (!normalizedPath.startsWith('app_data${path.separator}')) {
      return path.join(appDir.path, 'app_data', normalizedPath);
    }
    
    return path.join(appDir.path, normalizedPath);
  }
}