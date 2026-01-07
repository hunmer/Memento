import 'package:flutter/material.dart';
import 'dart:async';
import 'floating_ball_service.dart';
import 'floating_ball_manager.dart';
import 'widgets/shared_floating_ball_widget.dart';
import 'models/floating_ball_gesture.dart';
import 'package:Memento/core/action/action_manager.dart';

/// 浮浮球Widget
///
/// 这个类现在使用SharedFloatingBallWidget来提供核心功能，
/// 专注于应用内悬浮球的配置和集成。
class FloatingBallWidget extends StatefulWidget {
  final double baseSize;
  final Color color;
  final String iconPath;

  const FloatingBallWidget({
    super.key,
    this.baseSize = 60,
    this.color = Colors.blue,
    this.iconPath = 'assets/icon/icon.png',
  });

  @override
  State<FloatingBallWidget> createState() => _FloatingBallWidgetState();
}

class _FloatingBallWidgetState extends State<FloatingBallWidget> {
  final FloatingBallManager _manager = FloatingBallManager();
  StreamSubscription<double>? _sizeSubscription;
  StreamSubscription<Offset>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    // 监听大小变化并传递给SharedFloatingBallWidget
    _sizeSubscription = FloatingBallService().sizeChangeStream.listen((scale) {
      // 通过setState触发SharedFloatingBallWidget重新构建以应用新的大小
      if (mounted) {
        setState(() {});
      }
    });

    // 监听位置更新（虽然SharedFloatingBallWidget内部处理，但保留接口以兼容现有服务）
    _positionSubscription = FloatingBallService().positionChangeStream.listen((
      position,
    ) {
      // 位置变化由SharedFloatingBallWidget内部处理
    });

    // 在下一帧更新上下文
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // 不覆盖 FloatingBallService 的 context，使用 service 中保存的有效 context
        // FloatingBallService().updateContext(context);
        // 设置动作上下文（使用 service 中保存的 context）
        final serviceContext = FloatingBallService().lastContext;
        if (serviceContext != null && serviceContext.mounted) {
          _manager.setActionContext(serviceContext);
        }
      }
    });
  }

  @override
  void dispose() {
    _sizeSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// 处理手势动作
  void _handleGesture(FloatingBallGesture gesture) async {
    print('[悬浮球Widget] 手势触发: ${gesture.name}');

    // 长按手势不触发动作，避免与长按移动功能冲突
    if (gesture == FloatingBallGesture.longPress) {
      print('[悬浮球Widget] 跳过 longPress 手势');
      return;
    }

    // 使用 FloatingBallService 中保存的有效 context（有 Navigator）
    final serviceContext = FloatingBallService().lastContext;
    if (serviceContext != null && serviceContext.mounted) {
      print('[悬浮球Widget] 开始执行动作: ${gesture.name}');
      final actionManager = ActionManager();
      final result = await actionManager.executeGestureAction(gesture, serviceContext);

      print(
        '[悬浮球Widget] 动作执行结果: success=${result.success}, error=${result.error}',
      );
    } else {
      print('[悬浮球Widget] context 已卸载，无法执行动作');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 不在这里覆盖 context，因为这是 Overlay 的 context（没有 Navigator）
    // _manager.setActionContext(context);

    return SharedFloatingBallWidget(
      baseSize: widget.baseSize,
      color: widget.color,
      iconPath: widget.iconPath,
      onGesture: _handleGesture,
      onPositionChanged: (position) {
        // 只保存位置到管理器，不触发 Stream 通知
        // Stream 通知仅在重置位置时使用
        _manager.savePosition(position);
      },
      onSizeChanged: (scale) {
        // 保存大小到管理器
        _manager.saveSizeScale(scale);
        // 通知服务层
        FloatingBallService().notifySizeChange(scale);
      },
      onConfigChanged: () {
        // 配置变更时刷新界面
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
