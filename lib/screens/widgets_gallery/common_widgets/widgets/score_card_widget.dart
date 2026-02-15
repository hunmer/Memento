import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 分数卡片小组件
///
/// 显示分数、等级和行为列表，支持动画效果
class ScoreCardWidget extends StatefulWidget {
  /// 分数
  final int score;

  /// 等级
  final String grade;

  /// 行为数据列表
  final List<ActionData> actions;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 组件尺寸
  final HomeWidgetSize size;

  const ScoreCardWidget({
    super.key,
    required this.score,
    required this.grade,
    required this.actions,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static ScoreCardWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final actionsList = props['actions'] as List<dynamic>?;
    final actions = actionsList?.map((action) {
      final map = action as Map<String, dynamic>;
      return ActionData(
        label: map['label'] as String,
        value: map['value'] as int,
        isPositive: map['isPositive'] as bool,
      );
    }).toList() ??
        [];

    return ScoreCardWidget(
      score: props['score'] as int? ?? 0,
      grade: props['grade'] as String? ?? 'A',
      actions: actions,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ScoreCardWidget> createState() => _ScoreCardWidgetState();
}

class _ScoreCardWidgetState extends State<ScoreCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 288,
              height: widget.inline ? double.maxFinite : 288,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFF3F3F46),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 径向渐变背景
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.2),
                          radius: 1.5,
                          colors: [
                            primaryColor.withOpacity(0.4),
                            primaryColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // 内容
                  Padding(
                    padding: widget.size.getPadding(),
                    child: Column(
                      children: [
                        // 分数显示
                        SizedBox(
                          height: widget.size.getHeightConstraints().maxHeight * 0.18,
                          child: Row(
                            children: [
                              Flexible(
                                flex: 3,
                                child: SizedBox(
                                  height: widget.size.getHeightConstraints().maxHeight * 0.18,
                                  child: AnimatedFlipCounter(
                                    value:
                                        widget.score.toDouble() *
                                        _animation.value,
                                    wholeDigits: 3,
                                    fractionDigits: 0,
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.size == const LargeSize() ? 56 : 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: widget.size.getItemSpacing() * 0.5),
                              Flexible(
                                flex: 1,
                                child: SizedBox(
                                  height: widget.size.getHeightConstraints().maxHeight * 0.18,
                                  child: Text(
                                    widget.grade,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: widget.size == const LargeSize() ? 56 : 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: widget.size.getTitleSpacing() * 0.25),
                        Text(
                          'Last Actions',
                          style: TextStyle(
                            color: const Color(0xFF71717A),
                            fontSize: widget.size == const LargeSize() ? 20 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: widget.size.getItemSpacing()),
                        // 行为列表
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: List.generate(widget.actions.length, (
                              index,
                            ) {
                              final action = widget.actions[index];
                              final itemAnimation = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.2 + index * 0.08,
                                  0.7 + index * 0.08,
                                  curve: Curves.easeOutCubic,
                                ),
                              );

                              return _ActionItem(
                                action: action,
                                animation: itemAnimation,
                                size: widget.size,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
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

/// 行为项组件
class _ActionItem extends StatelessWidget {
  final ActionData action;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _ActionItem({
    required this.action,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final displayValue = (action.value * animation.value).round();

        return Padding(
          padding: EdgeInsets.only(bottom: size.getItemSpacing() * 0.75),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size == const LargeSize() ? 20 : 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    action.isPositive ? '+' : '-',
                    style: TextStyle(
                      color:
                          action.isPositive
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                      fontSize: size == const LargeSize() ? 20 : 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: size.getItemSpacing() * 0.25),
                  SizedBox(
                    width: 60,
                    height: size == const LargeSize() ? 28 : 24,
                    child: AnimatedFlipCounter(
                      value: displayValue.toDouble(),
                      wholeDigits: 2,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        color:
                            action.isPositive
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                        fontSize: size == const LargeSize() ? 20 : 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 行为数据模型
class ActionData {
  final String label;
  final int value;
  final bool isPositive;

  const ActionData({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'isPositive': isPositive,
    };
  }

  /// 从 JSON 创建
  factory ActionData.fromJson(Map<String, dynamic> json) {
    return ActionData(
      label: json['label'] as String,
      value: json['value'] as int,
      isPositive: json['isPositive'] as bool,
    );
  }
}
