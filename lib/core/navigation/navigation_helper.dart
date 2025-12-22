import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

import 'open_container_route.dart';
export 'open_container_route.dart';

/// 跨平台导航助手
///
/// 提供统一的导航接口，自动根据平台选择合适的路由类型：
/// - iOS: CupertinoPageRoute (支持原生左滑返回)
/// - Android: MaterialPageRoute
///
/// 使用示例：
/// ```dart
/// // 推送到新页面
/// NavigationHelper.push(
///   context,
///   const DetailScreen(),
/// );
///
/// // 替换当前页面
/// NavigationHelper.pushReplacement(
///   context,
///   const HomeScreen(),
/// );
///
/// // 带参数推送
/// NavigationHelper.push(
///   context,
///   DetailScreen(id: '123'),
/// );
/// ```
class NavigationHelper {
  /// 检查是否为 iOS 平台
  static bool get _isIOS => Platform.isIOS;

  // ==================== 基础 push 导航 ====================

  /// 推送到新页面
  ///
  /// [context] BuildContext
  /// [page] 要推送的页面
  /// [maintainState] 是否保持状态（默认 true）
  /// [fullscreenDialog] 是否全屏对话框（默认 false）
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (_isIOS) {
      return Navigator.of(context).push<T>(
        CupertinoPageRoute<T>(
          builder: (context) => page,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        ),
      );
    } else {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (context) => page,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        ),
      );
    }
  }

  /// 推送到新页面（带命名路由）
  ///
  /// [context] BuildContext
  /// [routeName] 路由名称
  /// [arguments] 传递的参数
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// 推送到新页面（带命名路由和参数生成器）
  ///
  /// [context] BuildContext
  /// [routeName] 路由名称
  /// [arguments] 传递的参数
  static Future<T?> pushNamedWithArg<T extends Object?>(
    BuildContext context,
    String routeName,
    Map<String, dynamic> arguments,
  ) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  // ==================== 替换导航 ====================

  /// 替换当前页面
  ///
  /// [context] BuildContext
  /// [newPage] 新页面
  /// [result] 返回给上一个页面的结果
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget newPage, {
    TO? result,
    bool maintainState = true,
  }) {
    if (_isIOS) {
      return Navigator.of(context).pushReplacement<T, TO>(
        CupertinoPageRoute<T>(
          builder: (context) => newPage,
          maintainState: maintainState,
        ),
        result: result,
      );
    } else {
      return Navigator.of(context).pushReplacement<T, TO>(
        MaterialPageRoute(
          builder: (context) => newPage,
          maintainState: maintainState,
        ),
        result: result,
      );
    }
  }

  /// 替换当前页面（带命名路由）
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  // ==================== 弹出并推送 ====================

  /// 弹出当前页面并推送新页面
  ///
  /// [context] BuildContext
  /// [newPage] 新页面
  static Future<T?> pushAndPop<T extends Object?>(
    BuildContext context,
    Widget newPage,
  ) {
    return Navigator.of(
      context,
    ).pushAndRemoveUntil<T>(_createRoute(context, newPage), (route) => false);
  }

  /// 弹出当前页面并推送新页面（带命名路由）
  static Future<T?> pushNamedAndPopUntil<T extends Object?>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil<T>(routeName, (route) => false);
  }

  // ==================== 移除直到导航 ====================

  /// 推送新页面并移除栈中的页面
  ///
  /// [context] BuildContext
  /// [newPage] 新页面
  /// [predicate] 保留页面的条件
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget newPage,
    RoutePredicate predicate,
  ) {
    return Navigator.of(
      context,
    ).pushAndRemoveUntil<T>(_createRoute(context, newPage), predicate);
  }

  /// 推送新页面并移除栈中的页面（带命名路由）
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil<T>(routeName, predicate, arguments: arguments);
  }

  // ==================== 弹出导航 ====================

  /// 弹出页面
  ///
  /// [context] BuildContext
  /// [result] 返回给上一个页面的结果
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// 弹出直到指定条件
  ///
  /// [context] BuildContext
  /// [predicate] 停止弹出的条件
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// 弹出到根页面
  ///
  /// [context] BuildContext
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ==================== 对话框和底部弹窗 ====================

  /// 显示模态对话框
  ///
  /// [context] BuildContext
  /// [dialog] 对话框组件
  /// [barrierDismissible] 是否可点击外部关闭
  /// [barrierColor] 遮罩颜色
  static Future<T?> showCustomDialog<T extends Object?>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => dialog,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
    );
  }

  /// 显示底部弹窗
  static Future<T?> showModalBottomSheet<T extends Object?>(
    BuildContext context,
    WidgetBuilder builder, {
    bool isScrollControlled = false,
  }) {
    return SmoothBottomSheet.show<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
    );
  }

  // ==================== iOS 专用导航 ====================

  /// iOS 风格的页面转场动画（仅 iOS 有效）
  ///
  /// [context] BuildContext
  /// [page] 页面
  /// [fullscreenDialog] 是否全屏对话框
  static Future<T?> pushIOS<T extends Object?>(
    BuildContext context,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      CupertinoPageRoute<T>(
        builder: (context) => page,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// 显示 iOS 风格对话框（所有平台）
  static Future<T?> showCupertinoDialog<T extends Object?>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
  }) {
    return showCupertinoDialog<T>(
      context,
      dialog,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 显示 iOS 风格的操作表
  static Future<T?> showCupertinoActionSheet<T extends Object?>(
    BuildContext context,
    Widget actionsSheet,
  ) {
    return showCupertinoActionSheet<T>(context, actionsSheet);
  }

  // ==================== Android 专用导航 ====================

  /// Android 风格的页面转场（仅 Android 有效）
  ///
  /// [context] BuildContext
  /// [page] 页面
  /// [fullscreenDialog] 是否全屏对话框
  static Future<T?> pushAndroid<T extends Object?>(
    BuildContext context,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => page,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  // ==================== 私有辅助方法 ====================

  /// 创建路由（根据平台自动选择）
  static Route<T> _createRoute<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    if (_isIOS) {
      return CupertinoPageRoute<T>(builder: (context) => page);
    } else {
      return NavigationHelper.createRoute(page);
    }
  }

  /// 创建路由（公开方法）
  ///
  /// [page] 页面Widget
  /// [fullscreenDialog] 是否全屏对话框
  /// [maintainState] 是否保持状态
  static Route<T> createRoute<T extends Object?>(
    Widget page, {
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) {
    if (Platform.isIOS) {
      return CupertinoPageRoute<T>(
        builder: (context) => page,
        fullscreenDialog: fullscreenDialog,
        maintainState: maintainState,
      );
    } else {
      return MaterialPageRoute<T>(
        builder: (context) => page,
        fullscreenDialog: fullscreenDialog,
        maintainState: maintainState,
      );
    }
  }

  // ==================== 工具方法 ====================

  /// 检查是否可以在当前上下文弹出
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// 获取当前路由名称
  static String? getCurrentRouteName(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name;
  }

  /// 检查是否为根路由
  static bool isFirstRouteInStack(BuildContext context) {
    return !Navigator.of(context).canPop();
  }

  // ==================== 路由参数更新 ====================

  /// 更新当前路由的参数（通过替换路由实现）
  ///
  /// 用于在不离开当前页面的情况下更新路由信息，常用于：
  /// - 日记日历切换日期时更新路由，使"询问当前上下文"功能能获取到当前日期
  /// - 其他需要动态反映页面状态到路由的场景
  ///
  /// [context] BuildContext
  /// [routeName] 新的路由名称
  /// [arguments] 新的路由参数
  ///
  /// 示例：
  /// ```dart
  /// // 日记日历切换到2025-12-22
  /// NavigationHelper.updateRouteWithArguments(
  ///   context,
  ///   '/diary_detail',
  ///   {'date': '2025-12-22'},
  /// );
  /// ```
  static Future<void> updateRouteWithArguments(
    BuildContext context,
    String routeName,
    Map<String, dynamic> arguments,
  ) {
    // 调试输出：显示路由切换信息
    print('NavigationHelper: 切换到路由 "$routeName"，参数: $arguments');

    return pushReplacementNamed(context, routeName, arguments: arguments);
  }

  // ==================== OpenContainer 替代方法 ====================

  /// 使用 BackSwipePageRoute 导航到新页面
  ///
  /// @deprecated 请使用 [openContainerWithHero] 替代，支持 OpenContainer 展开动画
  @Deprecated('请使用 openContainerWithHero 替代')
  static Future<T?> openContainer<T extends Object?>(
    BuildContext context,
    WidgetBuilder builder, {
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve pushCurve = Curves.easeInOut,
    Curve popCurve = Curves.easeInOut,
    Color? closedColor,
    double? closedElevation,
    ShapeBorder? closedShape,
    Color? openColor,
    double? openElevation,
  }) {
    return openContainerWithHero<T>(
      context,
      builder,
      transitionDuration: transitionDuration,
      pushCurve: pushCurve,
      popCurve: popCurve,
      closedColor: closedColor,
      openColor: openColor,
      closedShape:
          closedShape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
    );
  }

  /// 使用 OpenContainer 风格导航到新页面
  ///
  /// 从源 widget 位置放大展开到全屏，实现 Material Design 的容器转换效果。
  ///
  /// [context] BuildContext
  /// [builder] 页面构建器
  /// [sourceKey] 源 widget 的 GlobalKey（用于获取位置，启用展开动画）
  /// [heroTag] 可选的标识符，用于路由命名
  /// [transitionDuration] 转场动画时长
  /// [closedBuilder] 关闭状态的构建器（用于过渡动画）
  /// [closedColor] 关闭状态的背景色
  /// [openColor] 打开状态的背景色
  /// [closedShape] 关闭状态的形状（默认圆角 12）
  /// [openShape] 打开状态的形状（默认直角）
  /// [onClosed] 页面关闭时的回调
  static Future<T?> openContainerWithHero<T extends Object?>(
    BuildContext context,
    WidgetBuilder builder, {
    String? heroTag,
    GlobalKey? sourceKey,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve pushCurve = Curves.easeInOut,
    Curve popCurve = Curves.easeInOut,
    WidgetBuilder? closedBuilder,
    Color? closedColor,
    Color? openColor,
    ShapeBorder closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    ),
    ShapeBorder openShape = const RoundedRectangleBorder(),
    void Function(T?)? onClosed,
  }) async {
    // 生成默认的 heroTag
    final tag =
        heroTag ?? 'open_container_${DateTime.now().millisecondsSinceEpoch}';

    // 如果提供了 sourceKey，使用 OpenContainer 动画
    if (sourceKey != null) {
      final result = await openContainerFromKey<T>(
        context: context,
        sourceKey: sourceKey,
        openBuilder: builder,
        closedBuilder: closedBuilder,
        closedColor: closedColor,
        openColor: openColor,
        closedShape: closedShape,
        openShape: openShape,
        transitionDuration: transitionDuration,
        routeSettings: RouteSettings(name: 'open_container_$tag'),
      );
      onClosed?.call(result);
      return result;
    }

    // 降级：没有 sourceKey 时使用普通路由
    final result = await Navigator.of(context).push<T>(
      BackSwipePageRoute<T>(
        builder: (_) => builder(context),
        transitionDuration: transitionDuration,
        pushCurve: pushCurve,
        popCurve: popCurve,
        settings: RouteSettings(name: 'hero_route_$tag'),
      ),
    );
    onClosed?.call(result);
    return result;
  }

  /// 使用 OpenContainer 风格导航（通过 GlobalKey）
  ///
  /// 这是更直接的 API，无需 heroTag 参数。
  ///
  /// [context] BuildContext
  /// [sourceKey] 源 widget 的 GlobalKey（必需）
  /// [openBuilder] 打开状态页面构建器
  /// [closedBuilder] 关闭状态的构建器（可选，用于过渡动画中显示）
  /// [closedColor] 关闭状态的背景色
  /// [openColor] 打开状态的背景色
  /// [closedShape] 关闭状态的形状
  /// [openShape] 打开状态的形状
  /// [transitionDuration] 过渡动画时长
  static Future<T?> openContainerTransition<T extends Object?>(
    BuildContext context, {
    required GlobalKey sourceKey,
    required WidgetBuilder openBuilder,
    WidgetBuilder? closedBuilder,
    Color? closedColor,
    Color? openColor,
    ShapeBorder closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    ),
    ShapeBorder openShape = const RoundedRectangleBorder(),
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return openContainerFromKey<T>(
      context: context,
      sourceKey: sourceKey,
      openBuilder: openBuilder,
      closedBuilder: closedBuilder,
      closedColor: closedColor,
      openColor: openColor,
      closedShape: closedShape,
      openShape: openShape,
      transitionDuration: transitionDuration,
    );
  }
}

/// 扩展 BuildContext，提供便捷的导航方法
extension NavigationExtensions on BuildContext {
  /// 推送到新页面
  Future<T?> pushPage<T extends Object?>(
    Widget page, {
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return NavigationHelper.push<T>(
      this,
      page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// 替换当前页面
  Future<T?> pushReplacementPage<T extends Object?, TO extends Object?>(
    Widget newPage, {
    TO? result,
    bool maintainState = true,
  }) {
    return NavigationHelper.pushReplacement<T, TO>(
      this,
      newPage,
      result: result,
      maintainState: maintainState,
    );
  }

  /// 弹出页面
  void popPage<T extends Object?>([T? result]) {
    NavigationHelper.pop<T>(this, result);
  }

  /// 显示对话框
  Future<T?> showPageDialog<T extends Object?>(
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return NavigationHelper.showCustomDialog<T>(
      this,
      dialog,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
    );
  }

  /// 显示底部弹窗
  Future<T?> showPageBottomSheet<T extends Object?>(
    WidgetBuilder builder, {
    bool isScrollControlled = false,
  }) {
    return SmoothBottomSheet.show<T>(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
    );
  }

  /// 打开容器页面
  ///
  /// @deprecated 请使用 [openContainerWithHero] 替代
  @Deprecated('请使用 openContainerWithHero 替代')
  Future<T?> openContainer<T extends Object?>(
    WidgetBuilder builder, {
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve pushCurve = Curves.easeInOut,
    Curve popCurve = Curves.easeInOut,
    Color? closedColor,
    double? closedElevation,
    ShapeBorder? closedShape,
    Color? openColor,
    double? openElevation,
  }) {
    return openContainerWithHero<T>(
      builder,
      transitionDuration: transitionDuration,
      pushCurve: pushCurve,
      popCurve: popCurve,
      closedColor: closedColor,
      openColor: openColor,
      closedShape: closedShape,
    );
  }

  /// 打开容器页面（支持 OpenContainer 展开动画）
  ///
  /// [sourceKey] 源 widget 的 GlobalKey，提供时启用展开动画
  /// [heroTag] 可选的标识符，用于路由命名
  Future<T?> openContainerWithHero<T extends Object?>(
    WidgetBuilder builder, {
    String? heroTag,
    GlobalKey? sourceKey,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve pushCurve = Curves.easeInOut,
    Curve popCurve = Curves.easeInOut,
    WidgetBuilder? closedBuilder,
    Color? closedColor,
    Color? openColor,
    ShapeBorder? closedShape,
    void Function(T?)? onClosed,
  }) {
    return NavigationHelper.openContainerWithHero<T>(
      this,
      builder,
      heroTag: heroTag,
      sourceKey: sourceKey,
      transitionDuration: transitionDuration,
      pushCurve: pushCurve,
      popCurve: popCurve,
      closedBuilder: closedBuilder,
      closedColor: closedColor,
      openColor: openColor,
      closedShape:
          closedShape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
      onClosed: onClosed,
    );
  }
}
