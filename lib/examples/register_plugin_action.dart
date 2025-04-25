import 'package:flutter/material.dart';
import '../core/floating_ball/floating_ball_service.dart';
import '../core/floating_ball/floating_ball_manager.dart';
import '../dialogs/plugin_list_dialog.dart';

/// 注册"选择打开插件"动作到悬浮球
void registerPluginActionToFloatingBall(BuildContext context) {
  // 初始化悬浮球服务
  final floatingBallService = FloatingBallService();
  floatingBallService.initialize(context);
  
  // 注册"选择打开插件"动作到单击事件
  floatingBallService.registerAction(
    FloatingBallGesture.tap, 
    '选择打开插件', 
    () => showPluginListDialog(context)
  );
  
  // 显示悬浮球
  floatingBallService.show(context);
}

/// 使用示例
/// 
/// ```dart
/// // 在主页或需要悬浮球的页面中调用
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     registerPluginActionToFloatingBall(context);
///   });
/// }
/// ```