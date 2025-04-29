import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../widgets/avatar_picker.dart';
import '../chat_plugin.dart';
import '../models/user.dart';

class ProfileEditDialog extends StatefulWidget {
  final User user;
  final ChatPlugin chatPlugin;

  const ProfileEditDialog({
    super.key,
    required this.user,
    required this.chatPlugin,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController _usernameController;
  String? _avatarPath;
  String? _tempAvatarPath; // 临时头像路径

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _avatarPath = widget.user.iconPath;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _onAvatarChanged(String path) {
    setState(() {
      _tempAvatarPath = path; // 保存临时路径
      _avatarPath = path; // 更新显示
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '编辑个人信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 头像选择器
            AvatarPicker(
              key: ValueKey(_avatarPath ?? 'default'), // 添加key确保更新
              size: 80,
              username: widget.user.username,
              currentAvatarPath: _avatarPath, // 使用状态中的路径
              saveDirectory: 'chat/temp_avatars', // 使用临时目录
              onAvatarChanged: _onAvatarChanged,
            ),
            const SizedBox(height: 16),
            
            // 用户名输入框
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newUsername = _usernameController.text.trim();
                    if (newUsername.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('用户名不能为空')),
                      );
                      return;
                    }

                    String? finalAvatarPath = _avatarPath;
                    
                    // 如果有新的头像，将其从临时目录移动到最终目录
                    if (_tempAvatarPath != null && _tempAvatarPath != widget.user.iconPath) {
                      try {
                        final appDir = await getApplicationDocumentsDirectory();
                        
                        // 获取临时文件的绝对路径
                        final tempAbsPath = path.join(appDir.path, 'app_data', _tempAvatarPath!);
                        final tempFile = File(tempAbsPath);
                        
                        if (await tempFile.exists()) {
                          // 创建最终目录
                          final avatarDir = Directory(path.join(appDir.path, 'app_data', 'chat/avatars'));
                          if (!await avatarDir.exists()) {
                            await avatarDir.create(recursive: true);
                          }
                          
                          // 构建最终文件路径
                          final finalFileName = '${widget.user.username}.jpg';
                          final finalAbsPath = path.join(avatarDir.path, finalFileName);
                          final finalFile = File(finalAbsPath);
                          
                          // 如果目标文件已存在，先删除
                          if (await finalFile.exists()) {
                            await finalFile.delete();
                          }
                          
                          // 移动文件到最终位置
                          await tempFile.copy(finalAbsPath);
                          await tempFile.delete(); // 删除临时文件
                          
                          // 更新最终路径
                          finalAvatarPath = './chat/avatars/$finalFileName';
                        }
                      } catch (e) {
                        debugPrint('Error moving avatar file: $e');
                        // 如果移动失败，继续使用临时路径
                        finalAvatarPath = _tempAvatarPath;
                      }
                    }

                    // 更新用户信息
                    await widget.chatPlugin.userService.updateCurrentUser(
                      username: newUsername,
                      avatarPath: finalAvatarPath,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}