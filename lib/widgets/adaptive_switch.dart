import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 自适应开关组件
///
/// 在 iOS 上使用 CupertinoSwitch，在其他平台上使用 Material Switch。
/// 这个组件解决了 iOS 模拟器上 Flutter Switch 的语义化崩溃问题。
///
/// 崩溃原因: Flutter 的 FlutterSwitchSemanticsObject 创建原生 UISwitch 时，
/// iOS 模拟器的 _refreshVisualElementForTraitCollection 可能返回 nil visual element，
/// 导致断言失败。真机不会触发此问题。
class AdaptiveSwitch extends StatelessWidget {
  /// 当前开关状态
  final bool value;

  /// 状态改变回调
  final ValueChanged<bool>? onChanged;

  /// 激活状态的颜色（仅 Material）
  final Color? activeColor;

  /// 激活状态的拇指颜色（仅 Material）
  final Color? activeTrackColor;

  /// 非激活状态的拇指颜色（仅 Material）
  final Color? inactiveThumbColor;

  /// 非激活状态的轨道颜色（仅 Material）
  final Color? inactiveTrackColor;

  /// 激活状态的拇指颜色（仅 Cupertino）
  final Color? thumbColor;

  /// 是否启用
  final bool enabled;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // 在 iOS 上使用 CupertinoSwitch 避免 UISwitch 语义化崩溃
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: activeColor,
        thumbColor: thumbColor,
      );
    }

    // 其他平台使用 Material Switch
    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );
  }
}
