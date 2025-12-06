import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as fluttertoast;

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
/// 在移动端使用 FlutterToast，其他平台使用 SnackBar
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
  }) {
    if (message.isEmpty) return;

    // 根据平台选择不同的实现方式
    if (kIsWeb || ![
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ].contains(defaultTargetPlatform)) {
      // Web 和桌面平台使用 SnackBar
      _showSnackBar(
        message,
        type: type,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    } else {
      // 移动端使用 FlutterToast
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
      duration: const Duration(seconds: 10), // 加载提示显示更长时间
    );
  }

  @override
  void cancel() {
    if (kIsWeb || ![
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ].contains(defaultTargetPlatform)) {
      // SnackBar 会自动消失，不支持手动取消
      // 可以通过 ScaffoldMessengerController 来清除所有 SnackBar
      final context = _navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } else {
      // 取消 FlutterToast
      fluttertoast.Fluttertoast.cancel();
    }
  }

  @override
  void dismiss() {
    cancel();
  }

  /// 使用 FlutterToast 显示消息（移动端）
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

    // 转换自定义的 ToastGravity 到 fluttertoast 的 ToastGravity
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