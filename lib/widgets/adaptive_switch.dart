import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';

/// 自适应开关组件变体类型
enum AdaptiveSwitchVariant {
  /// 简洁样式 - 类似 iOS 原生开关
  simple,

  /// 双值样式 - 带图标和文字
  dual,

  /// 滚动样式 - 带动画效果
  rolling,
}

/// 自适应开关组件
///
/// 使用 animated_toggle_switch 包实现，避免 iOS 模拟器上 Flutter 原生 Switch 的语义化崩溃问题。
///
/// 支持三种变体：
/// - [AdaptiveSwitchVariant.simple]: 简洁样式，类似 iOS 原生开关
/// - [AdaptiveSwitchVariant.dual]: 双值样式，带图标和文字
/// - [AdaptiveSwitchVariant.rolling]: 滚动样式，带动画效果
class AdaptiveSwitch extends StatelessWidget {
  /// 当前开关状态
  final bool value;

  /// 状态改变回调
  final ValueChanged<bool>? onChanged;

  /// 激活状态的颜色
  final Color? activeColor;

  /// 激活状态的拇指颜色
  final Color? activeThumbColor;

  /// 非激活状态的颜色
  final Color? inactiveColor;

  /// 非激活状态的拇指颜色
  final Color? inactiveThumbColor;

  /// 是否启用
  final bool enabled;

  /// 开关变体类型
  final AdaptiveSwitchVariant variant;

  /// 激活状态图标（仅 dual 和 rolling 变体）
  final Widget? activeIcon;

  /// 非激活状态图标（仅 dual 和 rolling 变体）
  final Widget? inactiveIcon;

  /// 激活状态文字（仅 dual 变体）
  final String? activeText;

  /// 非激活状态文字（仅 dual 变体）
  final String? inactiveText;

  /// 高度（仅 dual 和 rolling 变体）
  final double? height;

  /// 宽度（仅 dual 变体）
  final double? width;

  /// 动画时长
  final Duration? animationDuration;

  /// 动画曲线
  final Curve? animationCurve;

  /// 是否显示加载状态
  final bool loading;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.activeThumbColor,
    this.inactiveColor,
    this.inactiveThumbColor,
    this.enabled = true,
    this.variant = AdaptiveSwitchVariant.simple,
    this.activeIcon,
    this.inactiveIcon,
    this.activeText,
    this.inactiveText,
    this.height,
    this.width,
    this.animationDuration,
    this.animationCurve,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AdaptiveSwitchVariant.simple:
        return _buildSimpleSwitch(context);
      case AdaptiveSwitchVariant.dual:
        return _buildDualSwitch(context);
      case AdaptiveSwitchVariant.rolling:
        return _buildRollingSwitch(context);
    }
  }

  /// 构建简洁样式开关
  Widget _buildSimpleSwitch(BuildContext context) {
    final activeClr = activeColor ?? Theme.of(context).primaryColor;
    final inactiveClr = inactiveColor ?? Colors.grey.shade300;
    final thumbColor = activeThumbColor ?? Colors.white;

    return CustomAnimatedToggleSwitch<bool>(
      current: value,
      values: const [false, true],
      spacing: 0.0,
      indicatorSize: const Size.square(26.0),
      animationDuration: animationDuration ?? const Duration(milliseconds: 200),
      animationCurve: animationCurve ?? Curves.easeInOut,
      onChanged: enabled ? onChanged : null,
      loading: loading,
      iconBuilder: (context, local, global) => const SizedBox(),
      cursors: const ToggleCursors(defaultCursor: SystemMouseCursors.click),
      onTap: enabled && onChanged != null
          ? (_) => onChanged!(!value)
          : null,
      iconsTappable: false,
      wrapperBuilder: (context, global, child) {
        return Container(
          width: width ?? 50.0,
          height: height ?? 30.0,
          decoration: BoxDecoration(
            color: Color.lerp(inactiveClr, activeClr, global.position),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        );
      },
      foregroundIndicatorBuilder: (context, global) {
        return Container(
          width: 26.0,
          height: 26.0,
          margin: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: thumbColor,
            borderRadius: BorderRadius.circular(13.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建双值样式开关
  Widget _buildDualSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final activeClr = activeColor ?? theme.primaryColor;
    final inactiveClr = inactiveColor ?? Colors.grey.shade300;

    return AnimatedToggleSwitch<bool>.dual(
      current: value,
      first: false,
      second: true,
      spacing: 45.0,
      height: height ?? 50.0,
      animationDuration: animationDuration ?? const Duration(milliseconds: 300),
      animationCurve: animationCurve ?? Curves.easeInOut,
      style: ToggleStyle(
        borderColor: Colors.transparent,
        indicatorColor: activeThumbColor ?? Colors.white,
        backgroundColor: inactiveClr,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      styleBuilder: (v) => ToggleStyle(
        backgroundColor: v ? activeClr : inactiveClr,
      ),
      borderWidth: 0.0,
      onChanged: enabled ? onChanged : null,
      loading: loading,
      iconBuilder: (v) => v
          ? (activeIcon ?? const Icon(Icons.check, color: Colors.white))
          : (inactiveIcon ?? const Icon(Icons.close, color: Colors.grey)),
      textBuilder: (v) => v
          ? Center(
              child: Text(
                activeText ?? 'ON',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Center(
              child: Text(
                inactiveText ?? 'OFF',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  /// 构建滚动样式开关
  Widget _buildRollingSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final activeClr = activeColor ?? theme.primaryColor;

    return AnimatedToggleSwitch<bool>.rolling(
      current: value,
      values: const [false, true],
      height: height ?? 40.0,
      animationDuration: animationDuration ?? const Duration(milliseconds: 300),
      animationCurve: animationCurve ?? Curves.easeInOut,
      style: ToggleStyle(
        borderColor: Colors.transparent,
        indicatorColor: activeThumbColor ?? Colors.white,
        backgroundColor: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.0),
        indicatorBorderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      styleBuilder: (v) => ToggleStyle(
        backgroundColor: v ? activeClr.withOpacity(0.2) : Colors.grey.shade200,
        indicatorColor: v ? activeClr : Colors.grey.shade400,
      ),
      onChanged: enabled ? onChanged : null,
      loading: loading,
      iconBuilder: (v, foreground) {
        return v
            ? (activeIcon ??
                Icon(
                  Icons.check_circle,
                  color: activeThumbColor ?? Colors.white,
                  size: 20.0,
                ))
            : (inactiveIcon ??
                Icon(
                  Icons.cancel_outlined,
                  color: inactiveThumbColor ?? Colors.grey.shade600,
                  size: 20.0,
                ));
      },
    );
  }
}

/// 带标签的自适应开关组件
///
/// 将开关和标签组合在一起，方便在设置页面中使用
class AdaptiveSwitchListTile extends StatelessWidget {
  /// 标签文字
  final String title;

  /// 副标题
  final String? subtitle;

  /// 当前状态
  final bool value;

  /// 状态改变回调
  final ValueChanged<bool>? onChanged;

  /// 激活颜色
  final Color? activeColor;

  /// 开关变体
  final AdaptiveSwitchVariant variant;

  /// 前置图标
  final Widget? leading;

  /// 是否启用
  final bool enabled;

  const AdaptiveSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.variant = AdaptiveSwitchVariant.simple,
    this.leading,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: AdaptiveSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        variant: variant,
        enabled: enabled,
      ),
      enabled: enabled,
      onTap: enabled && onChanged != null
          ? () => onChanged!(!value)
          : null,
    );
  }
}
