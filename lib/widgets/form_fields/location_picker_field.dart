import 'package:flutter/material.dart';
import '../picker/location_picker.dart';
import 'builders/index.dart' show createRoundedContainerDecoration;

/// 位置选择器字段组件
///
/// 集成 LocationPicker，提供位置选择功能
class LocationPickerField extends StatelessWidget {
  /// 当前位置地址
  final String? currentLocation;

  /// 字段标签
  final String? labelText;

  /// 占位提示
  final String? hintText;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<String> onLocationChanged;

  /// 是否为移动端
  final bool isMobile;

  const LocationPickerField({
    super.key,
    required this.onLocationChanged,
    this.currentLocation,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap:
          enabled
              ? () async {
                final result = await showDialog<String>(
                  context: context,
                  builder:
                      (context) => LocationPicker(
                        isMobile: isMobile,
                        onLocationSelected: (address) {
                          Navigator.of(context).pop(address);
                        },
                      ),
                );
                if (result != null) {
                  onLocationChanged(result);
                }
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: createRoundedContainerDecoration(context),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentLocation ?? labelText ?? hintText ?? '选择位置',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
