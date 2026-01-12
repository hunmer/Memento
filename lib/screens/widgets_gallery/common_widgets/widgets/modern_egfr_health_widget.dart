import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// eGFR 健康指标数据模型
class EgfrHealthData {
  final String title;
  final double value;
  final String unit;
  final String date;
  final String status;

  const EgfrHealthData({
    required this.title,
    required this.value,
    required this.unit,
    required this.date,
    required this.status,
  });

  /// 从 JSON 创建
  factory EgfrHealthData.fromJson(Map<String, dynamic> json) {
    return EgfrHealthData(
      title: json['title'] as String? ?? 'eGFR',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'mL/min',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Unknown',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'unit': unit,
      'date': date,
      'status': status,
    };
  }
}

/// 现代 eGFR 健康指标卡片小组件
///
/// 通用的健康指标展示卡片，支持：
/// - 标题和图标
/// - 数值和单位显示（带翻转动画）
/// - 日期标签
/// - 状态指示器（带进度条）
class ModernEgfrHealthWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 数值
  final double value;

  /// 单位
  final String unit;

  /// 日期
  final String date;

  /// 状态标签
  final String status;

  /// 图标
  final IconData icon;

  /// 主色调
  final Color? primaryColor;

  /// 状态指示颜色
  final Color? statusColor;

  const ModernEgfrHealthWidget({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.date,
    required this.status,
    this.icon = Icons.science,
    this.primaryColor,
    this.statusColor,
  });

  /// 从 props 创建实例
  factory ModernEgfrHealthWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ModernEgfrHealthWidget(
      title: props['title'] as String? ?? 'eGFR',
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? 'mL/min',
      date: props['date'] as String? ?? '',
      status: props['status'] as String? ?? 'Unknown',
      icon: props['icon'] != null
          ? IconData(int.parse(props['icon'] as String), fontFamily: 'MaterialIcons')
          : Icons.science,
      primaryColor: props['primaryColor'] != null
          ? Color(int.parse(props['primaryColor'] as String))
          : null,
      statusColor: props['statusColor'] != null
          ? Color(int.parse(props['statusColor'] as String))
          : null,
    );
  }

  @override
  State<ModernEgfrHealthWidget> createState() => _ModernEgfrHealthWidgetState();
}

class _ModernEgfrHealthWidgetState extends State<ModernEgfrHealthWidget>
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
    final primaryColor = widget.primaryColor ??
        (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED));
    final accentColor = widget.statusColor ?? const Color(0xFF84CC16);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, -12),
                        ),
                      ],
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行
                  _buildHeader(isDark, primaryColor),
                  const SizedBox(height: 32),
                  // 数值和状态行
                  _buildContent(isDark, primaryColor, accentColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题行
  Widget _buildHeader(bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                widget.icon,
                size: 24,
                color: primaryColor,
              ),
            ),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                height: 1.0,
              ),
            ),
          ],
        ),
        Text(
          widget.date,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            height: 1.0,
          ),
        ),
      ],
    );
  }

  /// 构建内容区域
  Widget _buildContent(bool isDark, Color primaryColor, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 数值
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 52,
                child: AnimatedFlipCounter(
                  value: widget.value * _animation.value,
                  fractionDigits: 1,
                  textStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 22,
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 状态指示器
        _buildStatusIndicator(isDark, accentColor),
      ],
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(bool isDark, Color accentColor) {
    return Column(
      children: [
        SizedBox(
          height: 12,
          child: Text(
            widget.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 88,
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFFDE68A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // 渐变背景
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF365314),
                              const Color(0xFF3F6212),
                              const Color(0xFF365314),
                            ]
                          : [
                              const Color(0xFFFDE68A),
                              const Color(0xFFBEF264),
                              const Color(0xFFFDE68A),
                            ],
                    ),
                  ),
                ),
              ),
              // 指示点
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
