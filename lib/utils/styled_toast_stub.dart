import 'package:flutter/widgets.dart';

/// StyledToast 存根类（Web 平台使用）
/// Web 平台的 flutter_styled_toast 有兼容问题，使用存根类避免错误
class StyledToast extends StatelessWidget {
  final Widget child;

  const StyledToast({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Web 平台直接返回 child，不使用 StyledToast 功能
    return child;
  }
}

/// Toast 显示位置（存根）
class StyledToastPosition {
  // ignore: unused_field
  final int _value;

  static const top = StyledToastPosition._(0);
  static const center = StyledToastPosition._(1);
  static const bottom = StyledToastPosition._(2);

  const StyledToastPosition._(this._value);
}

/// Toast 动画类型（存根）
class StyledToastAnimation {
  static const fade = StyledToastAnimation._(0);
  static const slideFromTop = StyledToastAnimation._(1);
  static const slideFromBottom = StyledToastAnimation._(2);
  static const slideFromLeft = StyledToastAnimation._(3);
  static const slideFromRight = StyledToastAnimation._(4);
  static const scale = StyledToastAnimation._(5);
  static const fadeScale = StyledToastAnimation._(6);
  static const rotate = StyledToastAnimation._(7);
  static const fadeRotate = StyledToastAnimation._(8);
  static const scaleRotate = StyledToastAnimation._(9);

  // ignore: unused_field
  final int _value;
  const StyledToastAnimation._(this._value);
}

/// Toast Manager（存根）
class ToastManager {
  void dismissAll() {
    // Web 平台空实现
  }
}

/// showToast 函数存根（Web 平台不执行任何操作）
void showToast(
  String message, {
  BuildContext? context,
  Duration? duration,
  StyledToastPosition? position,
  Color? backgroundColor,
  TextStyle? textStyle,
  StyledToastAnimation? animation,
  StyledToastAnimation? reverseAnimation,
  Alignment? alignment,
  Curve? curve,
  Curve? reverseCurve,
  Duration? animDuration,
  bool? isIgnoring,
  Axis? axis,
  Offset? startOffset,
  Offset? endOffset,
  Offset? reverseStartOffset,
  Offset? reverseEndOffset,
  TextAlign? textAlign,
}) {
  // Web 平台空实现，实际的 Toast 应由 SnackBar 处理
}

/// showToastWidget 函数存根（Web 平台不执行任何操作）
void showToastWidget(
  Widget widget, {
  BuildContext? context,
  Duration? duration,
  StyledToastPosition? position,
  StyledToastAnimation? animation,
  StyledToastAnimation? reverseAnimation,
  Alignment? alignment,
  Curve? curve,
  Curve? reverseCurve,
  Duration? animDuration,
  bool? isIgnoring,
  Axis? axis,
  Offset? startOffset,
  Offset? endOffset,
  Offset? reverseStartOffset,
  Offset? reverseEndOffset,
  VoidCallback? onDismiss,
}) {
  // Web 平台空实现，实际的 Toast 应由 SnackBar 处理
}
