import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';

/// 头像名称区域组件
///
/// 功能特性：
/// - 头像选择和显示
/// - 名字和姓氏输入框
/// - 统一的 Material Design 3 样式
class AvatarNameSection extends StatelessWidget {
  /// 头像 URL（相对路径）
  final String? avatarUrl;

  /// 名字
  final String firstName;

  /// 姓氏
  final String lastName;

  /// 头像变更回调
  final Function(String?) onAvatarChanged;

  /// 名字变更回调
  final Function(String) onFirstNameChanged;

  /// 姓氏变更回调
  final Function(String) onLastNameChanged;

  /// 是否启用
  final bool enabled;

  const AvatarNameSection({
    super.key,
    this.avatarUrl,
    required this.firstName,
    required this.lastName,
    required this.onAvatarChanged,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _buildAvatarSection(context, theme),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildNameInput(
                firstName,
                'First Name',
                (value) => onFirstNameChanged(value),
                theme,
              ),
              _buildNameInput(
                lastName,
                'Last Name',
                (value) => onLastNameChanged(value),
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, ThemeData theme) {
    return Stack(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: ClipOval(
            child: avatarUrl != null
                ? FutureBuilder<String>(
                    future: ImageUtils.getAbsolutePath(avatarUrl!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  )
                : Container(
                    color: theme.cardColor,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.hintColor,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: enabled ? _pickAvatar : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor,
                border: Border.all(color: theme.cardColor, width: 2),
              ),
              child: const Icon(
                Icons.photo_camera,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput(
    String value,
    String placeholder,
    Function(String) onChanged,
    ThemeData theme,
  ) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  Future<void> _pickAvatar() async {
    final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    if (context == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ImagePickerDialog(
        saveDirectory: 'contacts/images',
        enableCrop: true,
        cropAspectRatio: 1 / 1,
      ),
    );

    if (result != null && result['url'] != null) {
      onAvatarChanged(result['url']);
    }
  }
}
