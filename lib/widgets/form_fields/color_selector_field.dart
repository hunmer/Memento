import 'package:flutter/material.dart';

/// 颜色选择组件
///
/// 功能特性：
/// - 支持预设颜色选择
/// - 统一的样式和主题适配
/// - 支持 inline 模式（label在左，颜色选择器在右）
class ColorSelectorField extends StatelessWidget {
  /// 当前选中的颜色
  final Color selectedColor;

  /// 颜色变更回调
  final Function(Color) onColorChanged;

  /// 标签文本
  final String? labelText;

  /// 预设颜色列表
  final List<Color> colors;

  /// 颜色圆点大小
  final double colorSize;

  /// 颜色圆点间距
  final double spacing;

  /// 是否使用inline模式（label在左，颜色选择器在右）
  final bool inline;

  /// inline模式下是否允许水平滚动（单行滚动展示）
  final bool scrollable;

  /// inline模式下label的宽度
  final double labelWidth;

  const ColorSelectorField({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.labelText,
    this.colors = const [
      Colors.grey,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ],
    this.colorSize = 36,
    this.spacing = 8,
    this.inline = false,
    this.scrollable = false,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // inline 模式：label 在左，颜色选择器在右
    if (inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            SizedBox(
              width: labelWidth,
              child: Text(
                labelText!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 单行滚动模式
          if (scrollable)
            SizedBox(
              height: colorSize + 4,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: spacing,
                  children: colors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => onColorChanged(color),
                      child: Container(
                        width: colorSize,
                        height: colorSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: color == Colors.white || color == Colors.yellow
                                    ? Colors.black
                                    : Colors.white,
                                size: colorSize * 0.55,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: colors.map((color) {
                final isSelected = selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    width: colorSize,
                    height: colorSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color == Colors.white || color == Colors.yellow
                                ? Colors.black
                                : Colors.white,
                            size: colorSize * 0.55,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
        ],
      );
    }

    // 默认模式：独立卡片样式
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: colors.map((color) {
              final isSelected = selectedColor.value == color.value;
              return GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: colorSize,
                  height: colorSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color == Colors.white || color == Colors.yellow
                              ? Colors.black
                              : Colors.white,
                          size: colorSize * 0.55,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
