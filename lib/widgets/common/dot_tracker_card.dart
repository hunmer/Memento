import 'dart:convert';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 点阵追踪卡片数据模型
///
/// 用于存储点阵追踪卡片的配置数据，支持 JSON 序列化。
class DotTrackerCardData {
  /// 卡片标题
  final String title;

  /// 卡片图标代码点（用于 JSON 序列化）
  final int iconCodePoint;

  /// 当前数值
  final int currentValue;

  /// 数值单位
  final String unit;

  /// 状态文本（如 "On Track"）
  final String status;

  /// 周日期标签列表（如 ['M', 'T', 'W', 'T', 'F', 'S', 'S']）
  final List<String> weekDays;

  /// 每天的点阵状态（true 表示已完成/激活，false 表示未完成）
  /// 外层列表长度应与 weekDays 一致，内层列表表示每天的多状态
  final List<List<bool>> dotStates;

  const DotTrackerCardData({
    required this.title,
    required this.iconCodePoint,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.weekDays,
    required this.dotStates,
  });

  /// 从图标创建数据
  factory DotTrackerCardData.withIcon({
    required String title,
    required IconData icon,
    required int currentValue,
    required String unit,
    required String status,
    required List<String> weekDays,
    required List<List<bool>> dotStates,
  }) {
    return DotTrackerCardData(
      title: title,
      iconCodePoint: icon.codePoint,
      currentValue: currentValue,
      unit: unit,
      status: status,
      weekDays: weekDays,
      dotStates: dotStates,
    );
  }

  /// 从 JSON 创建数据
  factory DotTrackerCardData.fromJson(Map<String, dynamic> json) {
    return DotTrackerCardData(
      title: json['title'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      currentValue: json['currentValue'] as int,
      unit: json['unit'] as String,
      status: json['status'] as String,
      weekDays: List<String>.from(json['weekDays'] as List),
      dotStates: (json['dotStates'] as List)
          .map((day) => List<bool>.from(day as List))
          .toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconCodePoint': iconCodePoint,
      'currentValue': currentValue,
      'unit': unit,
      'status': status,
      'weekDays': weekDays,
      'dotStates': dotStates,
    };
  }

  /// 从 JSON 字符串创建数据
  factory DotTrackerCardData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DotTrackerCardData.fromJson(json);
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 复制并修改部分字段
  DotTrackerCardData copyWith({
    String? title,
    int? iconCodePoint,
    int? currentValue,
    String? unit,
    String? status,
    List<String>? weekDays,
    List<List<bool>>? dotStates,
  }) {
    return DotTrackerCardData(
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      weekDays: weekDays ?? this.weekDays,
      dotStates: dotStates ?? this.dotStates,
    );
  }

  /// 获取图标
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

/// 点阵追踪卡片小组件
///
/// 用于展示周度点阵追踪进度，例如每日目标完成情况、习惯打卡等。
/// 支持自定义标题、图标、数值、单位和点阵状态。
class DotTrackerCardWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 卡片图标
  final IconData icon;

  /// 当前数值
  final int currentValue;

  /// 数值单位
  final String unit;

  /// 状态文本（如 "On Track"）
  final String status;

  /// 周日期标签列表（如 ['M', 'T', 'W', 'T', 'F', 'S', 'S']）
  final List<String> weekDays;

  /// 每天的点阵状态（true 表示已完成/激活，false 表示未完成）
  /// 外层列表长度应与 weekDays 一致，内层列表表示每天的多状态
  final List<List<bool>> dotStates;

  /// 自定义宽度
  final double? width;

  /// 自定义高度
  final double? height;

  /// 是否启用动画
  final bool enableAnimation;

  /// 点击回调
  final VoidCallback? onTap;

  const DotTrackerCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.weekDays,
    required this.dotStates,
    this.width,
    this.height,
    this.enableAnimation = true,
    this.onTap,
  });

  /// 从数据模型创建组件
  factory DotTrackerCardWidget.fromData(
    DotTrackerCardData data, {
    Key? key,
    double? width,
    double? height,
    bool enableAnimation = true,
    VoidCallback? onTap,
  }) {
    return DotTrackerCardWidget(
      key: key,
      title: data.title,
      icon: data.icon,
      currentValue: data.currentValue,
      unit: data.unit,
      status: data.status,
      weekDays: data.weekDays,
      dotStates: data.dotStates,
      width: width,
      height: height,
      enableAnimation: enableAnimation,
      onTap: onTap,
    );
  }

  @override
  State<DotTrackerCardWidget> createState() => _DotTrackerCardWidgetState();
}

class _DotTrackerCardWidgetState extends State<DotTrackerCardWidget>
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
    if (widget.enableAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(DotTrackerCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation &&
        (oldWidget.currentValue != widget.currentValue ||
            oldWidget.dotStates != widget.dotStates)) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final primaryColor = Theme.of(context).colorScheme.secondary;
    final primaryLight =
        isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.4);

    final animatedChild = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.enableAnimation ? _animation.value : 1.0,
          child: Transform.translate(
            offset: Offset(
                0, widget.enableAnimation ? 20 * (1 - _animation.value) : 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.width ?? 380,
        height: widget.height ?? 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context, isDark, primaryColor, textColor, mutedColor),
            const SizedBox(height: 32),

            // 主要内容
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 数值显示
                _buildValueDisplay(textColor, mutedColor),
                // 点阵进度
                _buildDotsGrid(primaryColor, primaryLight),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(28),
        child: animatedChild,
      );
    }

    return animatedChild;
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor,
      Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Transform.rotate(
              angle: -0.78, // -45 degrees
              child: Icon(
                widget.icon,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: widget.onTap,
          icon: Icon(
            Icons.chevron_right,
            color: mutedColor,
            size: 20,
          ),
          label: Text(
            'Today',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedFlipCounter(
                value: widget.enableAnimation
                    ? widget.currentValue * _animation.value
                    : widget.currentValue.toDouble(),
                textStyle: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.status,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDotsGrid(Color primaryColor, Color primaryLight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyDotColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Row(
      children: List.generate(
        7,
        (index) {
          // 计算安全的 step 值，确保最大 end 值不超过 1.0
          // 公式: step <= (1.0 - baseEnd) / (elementCount - 1)
          // step <= (1.0 - 0.6) / 6 = 0.066
          final step = 0.06;
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * step,
              0.6 + index * step,
              curve: Curves.easeOutCubic,
            ),
          );

          return _DayDotColumn(
            day: widget.weekDays[index],
            dotStates: widget.dotStates[index],
            primaryColor: primaryColor,
            primaryLight: primaryLight,
            emptyDotColor: emptyDotColor,
            animation: widget.enableAnimation ? itemAnimation : AlwaysStoppedAnimation(1.0),
          );
        },
      ).toList(),
    );
  }
}

/// 每日点阵列组件
class _DayDotColumn extends StatelessWidget {
  final String day;
  final List<bool> dotStates;
  final Color primaryColor;
  final Color primaryLight;
  final Color emptyDotColor;
  final Animation<double> animation;

  const _DayDotColumn({
    required this.day,
    required this.dotStates,
    required this.primaryColor,
    required this.primaryLight,
    required this.emptyDotColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) {
                final isEnabled = index < dotStates.length && dotStates[index];
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isEnabled ? animation.value : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? (index == 0 && dotStates.every((s) => !s)
                                  ? primaryLight
                                  : primaryColor)
                              : emptyDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
