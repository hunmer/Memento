import 'package:flutter/material.dart';
import 'dart:async';
import 'floating_ball_service.dart';
import 'floating_ball_manager.dart';
import 'widgets/shared_floating_ball_widget.dart';
import 'models/floating_ball_gesture.dart';

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
        FloatingBallService().updateContext(context);
        // 设置动作上下文
        _manager.setActionContext(context);
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
  void _handleGesture(FloatingBallGesture gesture) {
    final action = _manager.getAction(gesture);
    if (action != null) {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 确保动作上下文是最新的
    _manager.setActionContext(context);

    return SharedFloatingBallWidget(
      baseSize: widget.baseSize,
      color: widget.color,
      iconPath: widget.iconPath,
      onGesture: _handleGesture,
      onPositionChanged: (position) {
        // 保存位置到管理器
        _manager.savePosition(position);
        // 通知服务层
        FloatingBallService().updatePosition(position);
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
