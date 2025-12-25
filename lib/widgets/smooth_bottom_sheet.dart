import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// 使用 smooth_sheets 实现的底部抽屉工具类
///
/// 提供类似于 showModalBottomSheet 的 API，但使用 smooth_sheets 实现
/// 特性：
/// - 流畅的拖拽动画
/// - 支持滑动关闭
/// - 自动适配主题
/// - 统一的拖拽指示器
class SmoothBottomSheet {
  /// 显示底部抽屉
  ///
  /// [context] - 上下文
  /// [builder] - 内容构建器
  /// [swipeDismissible] - 是否支持滑动关闭，默认 true
  /// [barrierDismissible] - 是否点击背景关闭，默认 true
  /// [backgroundColor] - 背景色，默认使用主题背景色
  /// [borderRadius] - 圆角半径，默认 20
  /// [showDragHandle] - 是否显示拖拽指示器，默认 true
  /// [enableDrag] - 是否启用拖拽，默认 true
  /// [isScrollControlled] - 是否使用全屏高度，默认 false
  /// [useSafeArea] - 是否使用安全区域，默认 false
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool swipeDismissible = true,
    bool barrierDismissible = true,
    Color? backgroundColor,
    double borderRadius = 20,
    bool showDragHandle = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    bool useSafeArea = false,
  }) {
    return Navigator.of(context).push<T>(
      ModalSheetRoute(
        swipeDismissible: swipeDismissible,
        barrierDismissible: barrierDismissible,
        builder: (context) => Sheet(
          child: _SheetContent(
            builder: builder,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            showDragHandle: showDragHandle,
          ),
        ),
      ),
    );
  }

  /// 显示带标题的底部抽屉
  ///
  /// [context] - 上下文
  /// [title] - 标题文本
  /// [child] - 内容组件
  /// [actions] - 底部操作按钮列表（可选）
  /// [showCloseButton] - 是否显示关闭按钮，默认 false
  /// 其他参数同 show 方法
  static Future<T?> showWithTitle<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool showCloseButton = false,
    bool swipeDismissible = true,
    bool barrierDismissible = true,
    Color? backgroundColor,
    double borderRadius = 20,
    bool showDragHandle = true,
    bool enableDrag = true,
    bool useSafeArea = false,
  }) {
    return show<T>(
      context: context,
      swipeDismissible: swipeDismissible,
      barrierDismissible: barrierDismissible,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showDragHandle: showDragHandle,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      builder: (context) => _SheetWithTitle(
        title: title,
        showCloseButton: showCloseButton,
        actions: actions,
        child: child,
      ),
    );
  }
}

/// 底部抽屉内容容器
class _SheetContent extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showDragHandle;

  const _SheetContent({
    required this.builder,
    this.backgroundColor,
    required this.borderRadius,
    required this.showDragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            if (showDragHandle) _buildDragHandle(theme),

            // 内容 - 使用 Flexible 包裹以允许动态高度
            Flexible(
              child: builder(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建拖拽指示器
  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 带标题的底部抽屉内容
class _SheetWithTitle extends StatelessWidget {
  final String title;
  final bool showCloseButton;
  final List<Widget>? actions;
  final Widget child;

  const _SheetWithTitle({
    required this.title,
    required this.showCloseButton,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              // 标题
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 关闭按钮
              if (showCloseButton)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 内容
        child,

        // 底部操作按钮
        if (actions != null && actions!.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ),
        ],
      ],
    );
  }
}
