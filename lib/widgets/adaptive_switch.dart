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

  /// 激活状态的颜色（轨道颜色）
  final Color? activeColor;

  /// 激活状态的拇指颜色
  final Color? activeThumbColor;

  /// 激活状态的轨道颜色（仅 Material）
  final Color? activeTrackColor;

  /// 非激活状态的拇指颜色
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
    this.activeThumbColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // 在 iOS 上使用自定义开关组件，完全避免语义化问题
    if (Platform.isIOS) {
      return ExcludeSemantics(
        child: _CustomCupertinoSwitch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: activeColor,
        ),
      );
    }

    // 其他平台使用 Material Switch
    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: activeColor,
      activeThumbColor: activeThumbColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );
  }
}

/// 自定义 iOS 风格开关组件
///
/// 完全用 Flutter 绘制，不使用原生 UISwitch，避免模拟器崩溃
class _CustomCupertinoSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const _CustomCupertinoSwitch({
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  State<_CustomCupertinoSwitch> createState() => _CustomCupertinoSwitchState();
}

class _CustomCupertinoSwitchState extends State<_CustomCupertinoSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CustomCupertinoSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? CupertinoColors.activeGreen;
    final inactiveColor = CupertinoColors.systemGrey5;
    final thumbColor = CupertinoColors.white;

    return GestureDetector(
      onTap: widget.onChanged != null
          ? () => widget.onChanged!(!widget.value)
          : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 51.0,
            height: 31.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.5),
              color: Color.lerp(inactiveColor, activeColor, _animation.value),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2,
                  left: 2 + (_animation.value * 20),
                  child: Container(
                    width: 27.0,
                    height: 27.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.5),
                      color: thumbColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
