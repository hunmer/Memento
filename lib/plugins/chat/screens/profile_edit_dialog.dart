import 'package:flutter/material.dart';
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
      _avatarPath = path;
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
              size: 80,
              username: widget.user.username,
              currentAvatarPath: widget.user.iconPath,
              saveDirectory: 'chat/avatars',
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

                    // 更新用户信息
                    await widget.chatPlugin.userService.updateCurrentUser(
                      username: newUsername,
                      avatarPath: _avatarPath,
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