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
