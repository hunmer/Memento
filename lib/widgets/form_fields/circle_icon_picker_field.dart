import 'package:flutter/material.dart';
import '../picker/circle_icon_picker.dart';

/// 圆形图标选择器字段组件
///
/// 集成 CircleIconPicker，提供图标和背景色选择功能
class CircleIconPickerField extends StatelessWidget {
  /// 当前图标
  final IconData currentIcon;

  /// 当前背景色
  final Color currentBackgroundColor;

  /// 是否启用
  final bool enabled;

  /// 值变化回调（返回 Map {'icon': IconData, 'color': Color}）
  final ValueChanged<Map<String, dynamic>> onValueChanged;

  const CircleIconPickerField({
    super.key,
    required this.currentIcon,
    required this.currentBackgroundColor,
    required this.onValueChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleIconPicker(
        currentIcon: currentIcon,
        backgroundColor: currentBackgroundColor,
        onIconSelected:
            enabled
                ? (icon) {
                  onValueChanged({
                    'icon': icon,
                    'color': currentBackgroundColor,
                  });
                }
                : (icon) {},
        onColorSelected:
            enabled
                ? (color) {
                  onValueChanged({'icon': currentIcon, 'color': color});
                }
                : (color) {},
      ),
    );
  }
}
