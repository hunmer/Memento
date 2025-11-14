import 'package:flutter/material.dart';
import 'platform/mobile_js_engine.dart';

/// JavaScript Bridge UI 处理器
/// 提供默认的 Toast/Alert/Dialog 实现
class JSUIHandlers {
  final BuildContext context;

  JSUIHandlers(this.context);

  /// 注册所有 UI 处理器到 JSEngine
  void register(MobileJSEngine engine) {
    engine.setToastHandler(_handleToast);
    engine.setAlertHandler(_handleAlert);
    engine.setDialogHandler(_handleDialog);
  }

  /// Toast 处理器
  void _handleToast(String message, String duration, String gravity) {
    final durationMs = _parseDuration(duration);
    final alignment = _parseGravity(gravity);

    // 使用 SnackBar 实现 Toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: durationMs),
        behavior: SnackBarBehavior.floating,
        margin: _getMargin(alignment),
      ),
    );
  }

  /// Alert 处理器
  Future<bool> _handleAlert(
    String message, {
    String? title,
    String? confirmText,
    String? cancelText,
    bool showCancel = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: Text(message),
          actions: [
            if (showCancel)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText ?? '取消'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? '确定'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Dialog 处理器
  Future<String?> _handleDialog(
    String? title,
    String? content,
    List<Map<String, dynamic>> actions,
  ) async {
    if (actions.isEmpty) {
      return null;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: content != null ? Text(content) : null,
          actions: actions.map((action) {
            final text = action['text'] as String? ?? '';
            final value = action['value'] as String?;
            final isDestructive = action['isDestructive'] as bool? ?? false;

            return TextButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: Text(
                text,
                style: TextStyle(
                  color: isDestructive ? Colors.red : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    return result;
  }

  // ==================== 辅助方法 ====================

  /// 解析 duration 参数
  int _parseDuration(String duration) {
    switch (duration.toLowerCase()) {
      case 'short':
        return 2000;
      case 'long':
        return 4000;
      default:
        // 尝试解析为数字
        return int.tryParse(duration) ?? 2000;
    }
  }

  /// 解析 gravity 参数
  Alignment _parseGravity(String gravity) {
    switch (gravity.toLowerCase()) {
      case 'top':
        return Alignment.topCenter;
      case 'center':
        return Alignment.center;
      case 'bottom':
      default:
        return Alignment.bottomCenter;
    }
  }

  /// 根据对齐方式获取边距
  EdgeInsets _getMargin(Alignment alignment) {
    if (alignment == Alignment.topCenter) {
      return const EdgeInsets.only(top: 50, left: 20, right: 20);
    } else if (alignment == Alignment.center) {
      return const EdgeInsets.symmetric(horizontal: 20);
    } else {
      return const EdgeInsets.only(bottom: 50, left: 20, right: 20);
    }
  }
}
