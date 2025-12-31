import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as fluttertoast;

// 条件导入：StyledToast 在 Web 平台有问题
// 默认使用存根，有 IO 库时（移动/桌面）使用真实实现
import '../../utils/styled_toast_stub.dart'
    if (dart.library.io) 'package:flutter_styled_toast/flutter_styled_toast.dart' as styled_toast;

/// Toast 消息类型
enum ToastType {
  normal,
  success,
  error,
  warning,
  info,
}

/// Toast 显示位置（仅移动端有效）
enum ToastGravity {
  TOP,
  CENTER,
  BOTTOM,
}

/// Toast 动画类型（flutter_styled_toast）
enum ToastAnimation {
  fade,
  slideFromTop,
  slideFromBottom,
  slideFromLeft,
  slideFromRight,
  scale,
  fadeScale,
  rotate,
  fadeRotate,
  scaleRotate,
}

/// Toast 服务接口
abstract class IToastService {
  /// 显示 Toast 消息
  void showToast(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,

    // flutter_styled_toast 扩展参数
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? fullWidth,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    TextAlign? textAlign,
  });

  /// 显示自定义 Widget Toast
  void showCustomWidget(
    Widget widget, {
    BuildContext? context,
    Duration? duration,
    ToastGravity? position,
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    VoidCallback? onDismiss,
  });

  /// 使用 FlutterToast 显示消息（支持全局显示，app外也能显示）
  void showToastGlobal(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  });

  /// 显示成功消息
  void showSuccess(String message, {Duration? duration});

  /// 显示错误消息
  void showError(String message, {Duration? duration});

  /// 显示警告消息
  void showWarning(String message, {Duration? duration});

  /// 显示信息消息
  void showInfo(String message, {Duration? duration});

  /// 显示加载消息
  void showLoading(String message);

  /// 取消当前显示的 Toast
  void cancel();

  /// 取消当前显示的 Toast（dismiss 方法别名）
  void dismiss() => cancel();
}

/// Toast 服务扩展接口（包含初始化方法）
abstract class IToastServiceWithInit extends IToastService {
  /// 设置 Navigator Key 用于获取 BuildContext
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey);
}

/// Toast 服务实现
/// 默认使用 flutter_styled_toast，支持丰富自定义
/// showToastGlobal 使用 FlutterToast，支持 app 外显示（仅移动端）
class ToastService implements IToastServiceWithInit {
  static ToastService? _instance;
  static ToastService get instance => _instance ??= ToastService._();
  ToastService._();

  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// 设置 Navigator Key 用于获取 BuildContext
  @override
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  @override
  void showToast(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,

    // flutter_styled_toast 扩展参数
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? fullWidth,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    TextAlign? textAlign,
  }) {
    if (message.isEmpty) return;

    // Web 平台使用 SnackBar
    if (kIsWeb) {
      _showSnackBar(
        message,
        type: type,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
      return;
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('ToastService: No context available, fallback to FlutterToast');
      _showFlutterToast(
        message,
        type: type,
        duration: duration ?? const Duration(seconds: 2),
        gravity: gravity,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
      );
      return;
    }

    final bgColor = backgroundColor ?? _getBackgroundColor(type);
    final txtColor = textColor ?? Colors.white;

    // 转换 ToastGravity 到 StyledToastPosition
    final toastPosition = _convertToastPosition(gravity);

    // 转换动画类型
    final toastAnimation = _convertAnimation(animation);

    styled_toast.showToast(
      message,
      context: context,
      duration: duration ?? const Duration(seconds: 2),
      position: toastPosition,
      backgroundColor: bgColor,
      textStyle: TextStyle(color: txtColor, fontSize: fontSize ?? 16),
      animation: toastAnimation,
      reverseAnimation: _convertAnimation(reverseAnimation),
      alignment: alignment as Alignment?,
      curve: curve ?? Curves.linear,
      reverseCurve: reverseCurve ?? Curves.linear,
      animDuration: animDuration ?? const Duration(milliseconds: 400),
      isIgnoring: isIgnoring ?? true,
      axis: axis ?? Axis.vertical,
      startOffset: startOffset,
      endOffset: endOffset,
      reverseStartOffset: reverseStartOffset,
      reverseEndOffset: reverseEndOffset,
      textAlign: textAlign ?? TextAlign.center,
    );
  }

  @override
  void showCustomWidget(
    Widget widget, {
    BuildContext? context,
    Duration? duration,
    ToastGravity? position,
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    VoidCallback? onDismiss,
  }) {
    // Web 平台暂不支持自定义 Widget Toast，使用 SnackBar 显示简单文本
    if (kIsWeb) {
      debugPrint('ToastService: Custom widget toast not supported on Web platform');
      return;
    }

    final ctx = context ?? _navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('ToastService: No context available for custom widget');
      return;
    }

    final toastPosition = _convertToastPosition(position);
    final toastAnimation = _convertAnimation(animation);

    styled_toast.showToastWidget(
      widget,
      context: ctx,
      duration: duration ?? const Duration(seconds: 2),
      position: toastPosition,
      animation: toastAnimation,
      reverseAnimation: _convertAnimation(reverseAnimation),
      alignment: alignment as Alignment?,
      curve: curve ?? Curves.linear,
      reverseCurve: reverseCurve ?? Curves.linear,
      animDuration: animDuration ?? const Duration(milliseconds: 400),
      isIgnoring: isIgnoring ?? true,
      axis: axis ?? Axis.vertical,
      startOffset: startOffset,
      endOffset: endOffset,
      reverseStartOffset: reverseStartOffset,
      reverseEndOffset: reverseEndOffset,
      onDismiss: onDismiss,
    );
  }

  @override
  void showToastGlobal(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    if (message.isEmpty) return;

    // 使用 FlutterToast，支持 app 外显示（仅移动端）
    if (kIsWeb || ![
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ].contains(defaultTargetPlatform)) {
      // Web 和桌面平台回退到 SnackBar
      _showSnackBar(
        message,
        type: type,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    } else {
      _showFlutterToast(
        message,
        type: type,
        duration: duration ?? const Duration(seconds: 2),
        gravity: gravity,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
      );
    }
  }

  @override
  void showSuccess(String message, {Duration? duration}) {
    showToast(
      message,
      type: ToastType.success,
      duration: duration,
    );
  }

  @override
  void showError(String message, {Duration? duration}) {
    showToast(
      message,
      type: ToastType.error,
      duration: duration,
    );
  }

  @override
  void showWarning(String message, {Duration? duration}) {
    showToast(
      message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  @override
  void showInfo(String message, {Duration? duration}) {
    showToast(
      message,
      type: ToastType.info,
      duration: duration,
    );
  }

  @override
  void showLoading(String message) {
    showToast(
      message,
      type: ToastType.info,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void cancel() {
    // 取消 flutter_styled_toast
    styled_toast.ToastManager().dismissAll();

    // 同时也取消 FlutterToast
    fluttertoast.Fluttertoast.cancel();
  }

  @override
  void dismiss() {
    cancel();
  }

  /// 使用 FlutterToast 显示消息（移动端，支持 app 外显示）
  void _showFlutterToast(
    String message, {
    ToastType type = ToastType.normal,
    Duration duration = const Duration(seconds: 2),
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    final bgColor = backgroundColor ?? _getBackgroundColor(type);
    final txtColor = textColor ?? Colors.white;

    var toastGravity = fluttertoast.ToastGravity.BOTTOM;
    if (gravity != null) {
      switch (gravity) {
        case ToastGravity.TOP:
          toastGravity = fluttertoast.ToastGravity.TOP;
          break;
        case ToastGravity.CENTER:
          toastGravity = fluttertoast.ToastGravity.CENTER;
          break;
        case ToastGravity.BOTTOM:
          toastGravity = fluttertoast.ToastGravity.BOTTOM;
          break;
      }
    }

    fluttertoast.Fluttertoast.showToast(
      msg: message,
      toastLength: duration.inSeconds > 3
          ? fluttertoast.Toast.LENGTH_LONG
          : fluttertoast.Toast.LENGTH_SHORT,
      gravity: toastGravity,
      timeInSecForIosWeb: duration.inSeconds,
      backgroundColor: bgColor,
      textColor: txtColor,
      fontSize: fontSize ?? 16.0,
    );
  }

  /// 使用 SnackBar 显示消息（Web 和桌面端）
  void _showSnackBar(
    String message, {
    ToastType type = ToastType.normal,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? textColor,
  }) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('ToastService: No context available for SnackBar');
      return;
    }

    final bgColor = backgroundColor ?? _getBackgroundColor(type);
    final txtColor = textColor ?? Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            _getIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: txtColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
      case ToastType.normal:
        return Colors.grey[800]!;
    }
  }

  /// 获取图标
  Widget _getIcon(ToastType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        iconData = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case ToastType.error:
        iconData = Icons.error;
        iconColor = Colors.white;
        break;
      case ToastType.warning:
        iconData = Icons.warning;
        iconColor = Colors.white;
        break;
      case ToastType.info:
        iconData = Icons.info;
        iconColor = Colors.white;
        break;
      case ToastType.normal:
        iconData = Icons.message;
        iconColor = Colors.white70;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  /// 转换 ToastGravity 到 StyledToastPosition
  styled_toast.StyledToastPosition _convertToastPosition(ToastGravity? gravity) {
    if (gravity == null) return styled_toast.StyledToastPosition.bottom;

    switch (gravity) {
      case ToastGravity.TOP:
        return styled_toast.StyledToastPosition.top;
      case ToastGravity.CENTER:
        return styled_toast.StyledToastPosition.center;
      case ToastGravity.BOTTOM:
        return styled_toast.StyledToastPosition.bottom;
    }
  }

  /// 转换 ToastAnimation 到 StyledToastAnimation
  styled_toast.StyledToastAnimation? _convertAnimation(ToastAnimation? animation) {
    if (animation == null) return null;

    switch (animation) {
      case ToastAnimation.fade:
        return styled_toast.StyledToastAnimation.fade;
      case ToastAnimation.slideFromTop:
        return styled_toast.StyledToastAnimation.slideFromTop;
      case ToastAnimation.slideFromBottom:
        return styled_toast.StyledToastAnimation.slideFromBottom;
      case ToastAnimation.slideFromLeft:
        return styled_toast.StyledToastAnimation.slideFromLeft;
      case ToastAnimation.slideFromRight:
        return styled_toast.StyledToastAnimation.slideFromRight;
      case ToastAnimation.scale:
        return styled_toast.StyledToastAnimation.scale;
      case ToastAnimation.fadeScale:
        return styled_toast.StyledToastAnimation.fadeScale;
      case ToastAnimation.rotate:
        return styled_toast.StyledToastAnimation.rotate;
      case ToastAnimation.fadeRotate:
        return styled_toast.StyledToastAnimation.fadeRotate;
      case ToastAnimation.scaleRotate:
        return styled_toast.StyledToastAnimation.scaleRotate;
    }
  }
}

/// Toast 服务的全局实例
/// 提供便捷的单例访问方式
final ToastService toastService = ToastService.instance;

/// Toast 服务的便捷访问器
class Toast {
  static final IToastService _service = ToastService.instance;

  /// 设置 Navigator Key（需要在 main.dart 中调用）
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    final service = _service;
    if (service is ToastService) {
      service.setNavigatorKey(navigatorKey);
    }
  }

  /// 显示普通消息
  static void show(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? fullWidth,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    TextAlign? textAlign,
  }) {
    final service = _service;
    if (service is ToastService) {
      service.showToast(
        message,
        type: type,
        duration: duration,
        gravity: gravity,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
        animation: animation,
        reverseAnimation: reverseAnimation,
        alignment: alignment,
        curve: curve,
        reverseCurve: reverseCurve,
        animDuration: animDuration,
        dismissOtherOnShow: dismissOtherOnShow,
        fullWidth: fullWidth,
        isIgnoring: isIgnoring,
        axis: axis,
        startOffset: startOffset,
        endOffset: endOffset,
        reverseStartOffset: reverseStartOffset,
        reverseEndOffset: reverseEndOffset,
        textAlign: textAlign,
      );
    }
  }

  /// 显示自定义 Widget
  static void showCustomWidget(
    Widget widget, {
    BuildContext? context,
    Duration? duration,
    ToastGravity? position,
    ToastAnimation? animation,
    ToastAnimation? reverseAnimation,
    AlignmentGeometry? alignment,
    Curve? curve,
    Curve? reverseCurve,
    Duration? animDuration,
    bool? dismissOtherOnShow,
    bool? isIgnoring,
    Axis? axis,
    Offset? startOffset,
    Offset? endOffset,
    Offset? reverseStartOffset,
    Offset? reverseEndOffset,
    VoidCallback? onDismiss,
  }) {
    final service = _service;
    if (service is ToastService) {
      service.showCustomWidget(
        widget,
        context: context,
        duration: duration,
        position: position,
        animation: animation,
        reverseAnimation: reverseAnimation,
        alignment: alignment,
        curve: curve,
        reverseCurve: reverseCurve,
        animDuration: animDuration,
        dismissOtherOnShow: dismissOtherOnShow,
        isIgnoring: isIgnoring,
        axis: axis,
        startOffset: startOffset,
        endOffset: endOffset,
        reverseStartOffset: reverseStartOffset,
        reverseEndOffset: reverseEndOffset,
        onDismiss: onDismiss,
      );
    }
  }

  /// 显示全局 Toast（app外也能显示，仅移动端）
  static void showGlobal(
    String message, {
    ToastType type = ToastType.normal,
    Duration? duration,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    final service = _service;
    if (service is ToastService) {
      service.showToastGlobal(
        message,
        type: type,
        duration: duration,
        gravity: gravity,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
      );
    }
  }

  /// 显示成功消息
  static void success(String message, {Duration? duration}) {
    _service.showSuccess(message, duration: duration);
  }

  /// 显示错误消息
  static void error(String message, {Duration? duration}) {
    _service.showError(message, duration: duration);
  }

  /// 显示警告消息
  static void warning(String message, {Duration? duration}) {
    _service.showWarning(message, duration: duration);
  }

  /// 显示信息消息
  static void info(String message, {Duration? duration}) {
    _service.showInfo(message, duration: duration);
  }

  /// 显示加载消息
  static void loading(String message) {
    _service.showLoading(message);
  }

  /// 取消当前 Toast
  static void cancel() {
    _service.cancel();
  }

  /// 取消当前显示的 Toast（dismiss 方法别名）
  static void dismiss() {
    _service.dismiss();
  }
}
