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

    // 使用 Overlay 实现真正的 Toast（支持任意位置）
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        // 根据位置选择不同的布局策略
        if (alignment == Alignment.center) {
          // 中间：使用 Positioned.fill + Center
          return Positioned.fill(
            child: Center(
              child: _buildToastContent(message),
            ),
          );
        } else if (alignment == Alignment.topCenter) {
          // 顶部：距离顶部 50px
          return Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildToastContent(message),
              ),
            ),
          );
        } else {
          // 底部：距离底部 50px
          return Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildToastContent(message),
              ),
            ),
          );
        }
      },
    );

    overlay.insert(overlayEntry);

    // 自动移除
    Future.delayed(Duration(milliseconds: durationMs), () {
      overlayEntry.remove();
    });
  }

  /// 构建 Toast 内容
  Widget _buildToastContent(String message) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
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
}
