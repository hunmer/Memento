import 'package:flutter/material.dart';
import 'dart:io';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/picker/circle_icon_picker.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';
import 'form_field_wrapper.dart';

/// 图标头像行字段
///
/// 支持并排显示图标选择器和头像选择器
class IconAvatarRowField extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始图标
  final IconData? initialIcon;

  /// 初始图标背景色
  final Color? initialIconColor;

  /// 初始头像 URL
  final String? initialAvatarUrl;

  /// 是否启用
  final bool enabled;

  /// 头像保存目录
  final String avatarSaveDirectory;

  /// 值变化回调 - 返回 Map {'icon': IconData, 'iconColor': Color, 'avatarUrl': String?}
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const IconAvatarRowField({
    super.key,
    required this.name,
    this.initialIcon,
    this.initialIconColor,
    this.initialAvatarUrl,
    this.enabled = true,
    this.avatarSaveDirectory = 'openai/agent_avatars',
    this.onChanged,
  });

  @override
  State<IconAvatarRowField> createState() => _IconAvatarRowFieldState();
}

class _IconAvatarRowFieldState extends State<IconAvatarRowField> {
  late IconData _selectedIcon;
  late Color _selectedIconColor;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon ?? Icons.smart_toy;
    _selectedIconColor = widget.initialIconColor ?? Colors.blue;
    _avatarUrl = widget.initialAvatarUrl;
  }

  /// 获取当前值
  Map<String, dynamic> getValue() {
    return {
      'icon': _selectedIcon,
      'iconColor': _selectedIconColor,
      'avatarUrl': _avatarUrl,
    };
  }

  /// 重置为初始值
  void reset() {
    setState(() {
      _selectedIcon = widget.initialIcon ?? Icons.smart_toy;
      _selectedIconColor = widget.initialIconColor ?? Colors.blue;
      _avatarUrl = widget.initialAvatarUrl;
    });
  }

  void _notifyChanged() {
    widget.onChanged?.call(getValue());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 图标选择器
        Expanded(
          child: CircleIconPicker(
            currentIcon: _selectedIcon,
            backgroundColor: _selectedIconColor,
            onIconSelected:
                widget.enabled
                    ? (icon) {
                      setState(() {
                        _selectedIcon = icon;
                      });
                      _notifyChanged();
                    }
                    : (_) {},
            onColorSelected:
                widget.enabled
                    ? (color) {
                      setState(() {
                        _selectedIconColor = color;
                      });
                      _notifyChanged();
                    }
                    : (_) {},
          ),
        ),
        const SizedBox(width: 16),
        // 头像选择器
        Expanded(
          child: GestureDetector(
            onTap:
                widget.enabled
                    ? () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder:
                            (context) => ImagePickerDialog(
                              initialUrl: _avatarUrl,
                              saveDirectory: widget.avatarSaveDirectory,
                              enableCrop: true,
                              cropAspectRatio: 1.0,
                            ),
                      );
                      if (result != null && result['url'] != null) {
                        setState(() {
                          _avatarUrl = result['url'] as String;
                        });
                        _notifyChanged();
                      }
                    }
                    : null,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child:
                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? FutureBuilder<String>(
                          future:
                              _avatarUrl!.startsWith('http')
                                  ? Future.value(_avatarUrl!)
                                  : ImageUtils.getAbsolutePath(_avatarUrl),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Center(
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: ClipOval(
                                    child:
                                        _avatarUrl!.startsWith('http')
                                            ? Image.network(
                                              snapshot.data!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            )
                                            : Image.file(
                                              File(snapshot.data!),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Icon(Icons.broken_image);
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text('头像', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// WrappedFormField 版本的图标头像行字段
class WrappedIconAvatarRowField extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始值
  final Map<String, dynamic>? initialValue;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<Map<String, dynamic>>? onChanged;

  /// 头像保存目录
  final String avatarSaveDirectory;

  const WrappedIconAvatarRowField({
    super.key,
    required this.name,
    this.initialValue,
    this.enabled = true,
    this.onChanged,
    this.avatarSaveDirectory = 'openai/agent_avatars',
  });

  @override
  State<WrappedIconAvatarRowField> createState() =>
      _WrappedIconAvatarRowFieldState();
}

class _WrappedIconAvatarRowFieldState extends State<WrappedIconAvatarRowField> {
  final GlobalKey<_IconAvatarRowFieldState> _fieldKey =
      GlobalKey<_IconAvatarRowFieldState>();

  @override
  Widget build(BuildContext context) {
    final initialValue =
        widget.initialValue ??
        {'icon': Icons.smart_toy, 'iconColor': Colors.blue, 'avatarUrl': null};

    return WrappedFormField(
      name: widget.name,
      initialValue: initialValue,
      enabled: widget.enabled,
      onReset: () => _fieldKey.currentState?.reset(),
      onChanged: (v) => widget.onChanged?.call(v as Map<String, dynamic>),
      builder: (context, value, setValue) {
        return IconAvatarRowField(
          key: _fieldKey,
          name: widget.name,
          initialIcon: value['icon'] as IconData?,
          initialIconColor: value['iconColor'] as Color?,
          initialAvatarUrl: value['avatarUrl'] as String?,
          enabled: widget.enabled,
          avatarSaveDirectory: widget.avatarSaveDirectory,
          onChanged: (v) => setValue(v),
        );
      },
    );
  }
}
