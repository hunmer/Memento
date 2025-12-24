import 'package:flutter/material.dart';
import '../picker/icon_picker_dialog.dart';

/// 图标选择器字段组件
///
/// 集成 IconPickerDialog，提供图标选择功能
class IconPickerField extends StatelessWidget {
  /// 当前选中的图标
  final IconData currentIcon;

  /// 字段标签
  final String? labelText;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<IconData> onIconChanged;

  /// 是否启用图标转图片功能
  final bool enableIconToImage;

  const IconPickerField({
    super.key,
    required this.currentIcon,
    required this.onIconChanged,
    this.labelText,
    this.enabled = true,
    this.enableIconToImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          enabled
              ? () async {
                final result = await showDialog<dynamic>(
                  context: context,
                  builder:
                      (context) => IconPickerDialog(
                        currentIcon: currentIcon,
                        enableIconToImage: enableIconToImage,
                      ),
                );
                if (result != null) {
                  if (result is IconData) {
                    onIconChanged(result);
                  } else if (result is Map && result['icon'] is IconData) {
                    onIconChanged(result['icon'] as IconData);
                  }
                }
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(currentIcon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labelText ?? '选择图标',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (enabled) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
