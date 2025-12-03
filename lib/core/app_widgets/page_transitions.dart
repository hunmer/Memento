import 'package:flutter/material.dart';

/// 无动画的页面过渡构建器 - 解决键盘弹出时的卡顿问题
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 直接返回子组件,不添加任何过渡动画
    return child;
  }
}
