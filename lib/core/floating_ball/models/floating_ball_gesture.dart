/// 悬浮球手势类型
library;

import '../../../core/action/models/action_group.dart';
import '../../../core/action/models/action_instance.dart';

enum FloatingBallGesture {
  tap,
  doubleTap,
  longPress,
  swipeUp,
  swipeDown,
  swipeLeft,
  swipeRight,
}

/// 手势动作配置
class GestureActionConfig {
  final FloatingBallGesture gesture;
  final ActionGroup? group;
  final ActionInstance? singleAction;

  const GestureActionConfig({
    required this.gesture,
    this.group,
    this.singleAction,
  });

  bool get hasAction => group != null || singleAction != null;
  bool get isEmpty => !hasAction;

  Map<String, dynamic> toJson() {
    return {
      'gesture': gesture.name,
      'group': group?.toJson(),
      'singleAction': singleAction?.toJson(),
    };
  }

  factory GestureActionConfig.fromJson(Map<String, dynamic> json) {
    return GestureActionConfig(
      gesture: FloatingBallGesture.values.firstWhere(
        (e) => e.name == json['gesture'],
        orElse: () => FloatingBallGesture.tap,
      ),
      group: json['group'] != null ? ActionGroup.fromJson(json['group']) : null,
      singleAction:
          json['singleAction'] != null ? ActionInstance.fromJson(json['singleAction']) : null,
    );
  }

  @override
  String toString() {
    return 'GestureActionConfig(gesture: $gesture, hasAction: $hasAction)';
  }
}
