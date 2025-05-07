import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import '../../../utils/image_utils.dart';
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

class _ProfileEditDialogState extends State<ProfileEditDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _usernameController;
  String? _avatarPath;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _avatarPath = widget.user.iconPath;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(ProfileEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当user对象确实发生变化时才更新
    if (oldWidget.user != widget.user && _avatarPath == oldWidget.user.iconPath) {
      setState(() {
        _avatarPath = widget.user.iconPath;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onAvatarChanged(String path) async {
    // 转换为相对路径
    final relativePath = await ImageUtils.toRelativePath(path);
    
    // 如果路径没有变化，不触发更新
    if (_avatarPath == relativePath) return;
    
    setState(() {
      _avatarPath = relativePath;
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
            
            RepaintBoundary(
              child: AvatarPicker(
                key: const ValueKey('avatar_picker'),
                size: 80,
                username: widget.user.username,
                currentAvatarPath: _avatarPath,
                saveDirectory: 'chat/avatars',
                onAvatarChanged: _onAvatarChanged,
                showPickerDialog: (BuildContext context, String? initialPath) async {
                  return showDialog<Map<String, dynamic>>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext dialogContext) => ImagePickerDialog(
                      initialUrl: initialPath,
                      saveDirectory: 'chat/avatars',
                      enableCrop: true,
                      cropAspectRatio: 1.0,
                    ),
                  );
                },
              ),
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

                    try {
                      // 创建更新后的用户对象
                      final updatedUser = widget.user.copyWith(
                        username: newUsername,
                        iconPath: _avatarPath,
                      );
                      
                      // 使用 updateUser 方法更新用户信息
                      await widget.chatPlugin.userService.updateUser(updatedUser);

                      // 强制清除图片缓存
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();

                      // 通知所有监听器（包括聊天消息气泡）更新
                      widget.chatPlugin.notifyListeners();

                      if (context.mounted) {
                        // 返回更新后的用户对象
                        Navigator.of(context).pop(updatedUser);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('更新失败: $e')),
                        );
                      }
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