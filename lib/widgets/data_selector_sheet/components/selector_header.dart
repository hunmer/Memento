import 'package:flutter/material.dart';

/// 选择器顶栏组件
///
/// 显示标题、返回按钮、关闭按钮
class SelectorHeader extends StatelessWidget {
  /// 标题文本
  final String title;

  /// 步骤标题（可选，显示在主标题下方）
  final String? stepTitle;

  /// 主题颜色
  final Color? themeColor;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 返回按钮点击回调
  final VoidCallback? onBack;

  /// 关闭按钮点击回调
  final VoidCallback? onClose;

  /// 右侧自定义操作按钮
  final List<Widget>? actions;

  const SelectorHeader({
    super.key,
    required this.title,
    this.stepTitle,
    this.themeColor,
    this.showBackButton = true,
    this.showCloseButton = true,
    this.onBack,
    this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = themeColor ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: stepTitle != null ? 72 : 56,
          child: Stack(
            children: [
              // 标题居中
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (stepTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        stepTitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: effectiveColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // 左侧和右侧按钮
              Row(
                children: [
                  if (showBackButton && onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onBack,
                      tooltip: '返回',
                    )
                  else if (showCloseButton && onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      tooltip: '关闭',
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  if (actions != null) ...actions!,
                  if (showCloseButton && onClose != null && showBackButton && onBack != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      tooltip: '关闭',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
