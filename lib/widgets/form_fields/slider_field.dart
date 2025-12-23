import 'package:flutter/material.dart';

/// 滑块选择组件
///
/// 功能特性：
/// - 统一的样式和主题适配
/// - 支持标签和当前值显示
/// - 可配置范围和刻度
/// - 可选的快捷值按钮
class SliderField extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 当前值显示文本
  final String valueText;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 当前值
  final double value;

  /// 刻度数量
  final int? divisions;

  /// 值变化的回调
  final ValueChanged<double>? onChanged;

  /// 是否启用
  final bool enabled;

  /// 主题色
  final Color primaryColor;

  /// 快捷值列表（可选）
  final List<double>? quickValues;

  /// 快捷值标签生成器（可选）
  final String Function(double value)? quickValueLabel;

  /// 快捷值按钮点击回调（可选）
  final ValueChanged<double>? onQuickValueTap;

  const SliderField({
    super.key,
    required this.label,
    required this.valueText,
    required this.min,
    required this.max,
    required this.value,
    this.divisions,
    this.onChanged,
    this.enabled = true,
    this.primaryColor = const Color(0xFF607AFB),
    this.quickValues,
    this.quickValueLabel,
    this.onQuickValueTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和当前值
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primaryColor,
              inactiveTrackColor: primaryColor.withOpacity(0.2),
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              divisions: divisions,
              onChanged: enabled ? onChanged : null,
            ),
          ),

          // 快捷值按钮（如果提供）
          if (quickValues != null &&
              quickValues!.isNotEmpty &&
              quickValueLabel != null) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickValues!.map((quickValue) {
                  final isSelected = (value - quickValue).abs() < 0.01;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            enabled && onQuickValueTap != null
                                ? () => onQuickValueTap!(quickValue)
                                : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? primaryColor
                                      : primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            quickValueLabel!(quickValue),
                            style: TextStyle(
                              color: isSelected ? Colors.white : primaryColor,
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
