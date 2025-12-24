import 'package:flutter/material.dart';
import '../picker/avatar_picker.dart';

/// 头像选择器字段组件
///
/// 集成 AvatarPicker，提供头像选择功能
class AvatarPickerField extends StatelessWidget {
  /// 用户名（用于默认头像显示）
  final String username;

  /// 当前头像路径
  final String? currentAvatarPath;

  /// 头像大小
  final double size;

  /// 保存目录
  final String saveDirectory;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<String?> onAvatarChanged;

  const AvatarPickerField({
    super.key,
    required this.username,
    required this.onAvatarChanged,
    this.currentAvatarPath,
    this.size = 80.0,
    this.saveDirectory = 'avatars',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (username.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('头像', style: Theme.of(context).textTheme.bodyMedium),
          ),
        Center(
          child: AvatarPicker(
            username: username,
            size: size,
            currentAvatarPath: currentAvatarPath,
            saveDirectory: saveDirectory,
            onAvatarChanged: enabled ? onAvatarChanged : null,
          ),
        ),
      ],
    );
  }
}
