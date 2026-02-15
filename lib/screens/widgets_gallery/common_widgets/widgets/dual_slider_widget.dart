import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 双滑块数据模型
class DualSliderData {
  final String label1;
  final String label2;
  final String label3;
  final int value1;
  final int value2;
  final bool isPM;
  final String badgeText;

  const DualSliderData({
    required this.label1,
    required this.label2,
    required this.label3,
    required this.value1,
    required this.value2,
    required this.isPM,
    required this.badgeText,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory DualSliderData.fromJson(Map<String, dynamic> json) {
    return DualSliderData(
      label1: json['label1'] as String? ?? '',
      label2: json['label2'] as String? ?? '',
      label3: json['label3'] as String? ?? '',
      value1: json['value1'] as int? ?? 0,
      value2: json['value2'] as int? ?? 0,
      isPM: json['isPM'] as bool? ?? false,
      badgeText: json['badgeText'] as String? ?? '',
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {
      'label1': label1,
      'label2': label2,
      'label3': label3,
      'value1': value1,
      'value2': value2,
      'isPM': isPM,
      'badgeText': badgeText,
    };
  }
}

/// 双滑块小组件
///
/// 通用的双滑块展示组件，支持自定义标签和数值显示
/// 适用于各种需要双值对比的场景，如时区对比、进度追踪等
class DualSliderWidget extends StatefulWidget {
  /// 第一个标签（通常为主标题，如地点名称）
  final String label1;

  /// 第二个标签（通常为副标题，如偏移量）
  final String label2;

  /// 第三个标签（通常为日期或附加信息）
  final String label3;

  /// 第一个数值（通常为小时的十位）
  final int value1;

  /// 第二个数值（通常为小时的个位或分钟）
  final int value2;

  /// 是否为下午（PM）
  final bool isPM;

  /// 徽章文本（如时差信息）
  final String badgeText;

  /// 进度值（0.0 到 1.0）
  final double progress;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const DualSliderWidget({
    super.key,
    required this.label1,
    required this.label2,
    required this.label3,
    required this.value1,
    required this.value2,
    required this.isPM,
    required this.badgeText,
    this.progress = 0.67,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DualSliderWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return DualSliderWidget(
      label1: props['label1'] as String? ?? '',
      label2: props['label2'] as String? ?? '',
      label3: props['label3'] as String? ?? '',
      value1: props['value1'] as int? ?? 0,
      value2: props['value2'] as int? ?? 0,
      isPM: props['isPM'] as bool? ?? false,
      badgeText: props['badgeText'] as String? ?? '',
      progress: (props['progress'] as num?)?.toDouble() ?? 0.67,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<DualSliderWidget> createState() => _DualSliderWidgetState();
}

class _DualSliderWidgetState extends State<DualSliderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.error;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              height: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: widget.size.getPadding(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部：标签信息
                  _LabelInfo(
                    label1: widget.label1,
                    label2: widget.label2,
                    label3: widget.label3,
                    animation: _animation,
                    isDark: isDark,
                    size: widget.size,
                  ),

                  // 中间：滑块进度条
                  _SliderTrack(
                    progress: widget.progress,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    animation: _animation,
                    size: widget.size,
                  ),

                  // 底部：数值和徽章标签
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ValueDisplay(
                        value1: widget.value1,
                        value2: widget.value2,
                        isPM: widget.isPM,
                        animation: _animation,
                        isDark: isDark,
                        size: widget.size,
                      ),
                      _Badge(
                        badgeText: widget.badgeText,
                        animation: _animation,
                        size: widget.size,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 标签信息
class _LabelInfo extends StatelessWidget {
  final String label1;
  final String label2;
  final String label3;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _LabelInfo({
    required this.label1,
    required this.label2,
    required this.label3,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: size.getItemSpacing()),
                Row(
                  children: [
                    Text(
                      label2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(width: size.getItemSpacing()),
                    Text(
                      label3,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 滑块进度条
class _SliderTrack extends StatelessWidget {
  final double progress;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _SliderTrack({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: size.getTitleSpacing()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;

                return SizedBox(
                  height: 6,
                  width: trackWidth,
                  child: Stack(
                    children: [
                      // 背景轨道
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // 进度条
                      FractionallySizedBox(
                        widthFactor: progress * itemAnimation.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // 左滑块
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 右滑块
                      Positioned(
                        left: (progress - 0.02).clamp(0.0, 1.0) * trackWidth,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// 数值显示
class _ValueDisplay extends StatelessWidget {
  final int value1;
  final int value2;
  final bool isPM;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _ValueDisplay({
    required this.value1,
    required this.value2,
    required this.isPM,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPM ? 'PM' : 'AM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: size.getItemSpacing()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedFlipCounter(
                      value: value1 * itemAnimation.value,
                      textStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(width: size.getItemSpacing()),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(width: size.getItemSpacing()),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AnimatedFlipCounter(
                        value: value2 * itemAnimation.value,
                        textStyle: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 徽章标签
class _Badge extends StatelessWidget {
  final String badgeText;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _Badge({
    required this.badgeText,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: itemAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C759).withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
