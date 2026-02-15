import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 渲染图标，支持 emoji 字符串和 MaterialIcons codePoint
Widget _renderIcon(String icon, {double size = 18}) {
  // 尝试解析为 MaterialIcons codePoint
  final codePoint = int.tryParse(icon);
  if (codePoint != null) {
    return Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: size);
  }
  // 否则作为普通 emoji 字符串处理
  return Text(icon, style: TextStyle(fontSize: size));
}

/// 列进度数据模型
class ColumnProgressData {
  final double current;
  final double total;
  final String unit;

  const ColumnProgressData({
    required this.current,
    required this.total,
    required this.unit,
  });

  /// 从 JSON 创建
  factory ColumnProgressData.fromJson(Map<String, dynamic> json) {
    return ColumnProgressData(
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'current': current, 'total': total, 'unit': unit};
  }
}

/// 左侧区域配置
class LeftSectionConfig {
  final String icon;
  final String label;
  final String? subtext; // 可选的副标题，显示在进度条下方

  const LeftSectionConfig({
    this.icon = '🔥',
    this.label = 'Calories',
    this.subtext,
  });

  /// 从 JSON 创建
  factory LeftSectionConfig.fromJson(Map<String, dynamic> json) {
    return LeftSectionConfig(
      icon: json['icon'] as String? ?? '🔥',
      label: json['label'] as String? ?? 'Calories',
      subtext: json['subtext'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'label': label,
      if (subtext != null) 'subtext': subtext,
    };
  }
}

/// 进度项数据模型
class ProgressItemData {
  final String icon;
  final String name;
  final double current;
  final double total;
  final Color color;

  /// 可选的副标题（如时间范围）
  final String? subtitle;

  const ProgressItemData({
    required this.icon,
    required this.name,
    required this.current,
    required this.total,
    required this.color,
    this.subtitle,
  });

  /// 从 JSON 创建
  factory ProgressItemData.fromJson(Map<String, dynamic> json) {
    return ProgressItemData(
      icon: json['icon'] as String? ?? '',
      name: json['name'] as String? ?? '',
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
      subtitle: json['subtitle'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'name': name,
      'current': current,
      'total': total,
      'color': color.value,
      if (subtitle != null) 'subtitle': subtitle,
    };
  }
}

/// 左右分栏进度条卡片小组件
class SplitColumnProgressBarCard extends StatefulWidget {
  /// 左侧数据（用于进度条）
  final ColumnProgressData? leftData;

  /// 左侧区域配置（图标、标签等）
  final LeftSectionConfig? leftConfig;

  /// 右侧进度项列表
  final List<ProgressItemData>? rightItems;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const SplitColumnProgressBarCard({
    super.key,
    this.leftData,
    this.leftConfig,
    this.rightItems,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory SplitColumnProgressBarCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析左侧数据
    ColumnProgressData? leftData;
    if (props['leftData'] != null) {
      leftData = ColumnProgressData.fromJson(
        props['leftData'] as Map<String, dynamic>,
      );
    }

    // 解析左侧配置
    LeftSectionConfig? leftConfig;
    if (props['leftConfig'] != null) {
      leftConfig = LeftSectionConfig.fromJson(
        props['leftConfig'] as Map<String, dynamic>,
      );
    }

    // 解析右侧数据
    final rightItems =
        (props['rightItems'] as List<dynamic>?)
            ?.map((e) => ProgressItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SplitColumnProgressBarCard(
      leftData: leftData,
      leftConfig: leftConfig,
      rightItems: rightItems,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SplitColumnProgressBarCard> createState() =>
      _SplitColumnProgressBarCardState();
}

class _SplitColumnProgressBarCardState extends State<SplitColumnProgressBarCard>
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

    final leftData =
        widget.leftData ??
        const ColumnProgressData(current: 0, total: 100, unit: '');
    final leftConfig = widget.leftConfig ?? const LeftSectionConfig();
    final rightItems = widget.rightItems ?? const [];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              height: widget.inline ? double.maxFinite : 180,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LeftSection(
                      data: leftData,
                      config: leftConfig,
                      animation: _animation,
                      size: widget.size,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      horizontal: widget.size.getPadding().horizontal / 2,
                    ),
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _RightSection(
                      items: rightItems,
                      animation: _animation,
                      size: widget.size,
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

class _LeftSection extends StatelessWidget {
  final ColumnProgressData data;
  final LeftSectionConfig config;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _LeftSection({
    required this.data,
    required this.config,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _renderIcon(config.icon, size: 18),
            const SizedBox(width: 6),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        SizedBox(height: size.getItemSpacing()),
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 36,
                child: AnimatedFlipCounter(
                  value: data.current * animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 18,
                child: Text(
                  data.unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size.getItemSpacing()),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor:
                    (data.total > 0 ? data.current / data.total : 0) *
                    animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (config.subtext != null) ...[
          SizedBox(height: size.getItemSpacing()),
          SizedBox(
            height: 16,
            child: Text(
              config.subtext!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.0,
              ),
            ),
          ),
        ] else ...[
          SizedBox(height: size.getItemSpacing()),
          SizedBox(
            height: 16,
            child: Text(
              '${(data.total - data.current).toInt()} ${data.unit} remaining',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RightSection extends StatelessWidget {
  final List<ProgressItemData> items;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _RightSection({
    required this.items,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: size.getItemSpacing()),
              _ProgressItem(
                data: items[i],
                animation: animation,
                index: i,
                size: size,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final ProgressItemData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _ProgressItem({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = 0.08;
    final end = (0.6 + index * step).clamp(0.0, 1.0);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    final progress = data.total > 0 ? data.current / data.total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _renderIcon(data.icon, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? Colors.grey.shade100
                                    : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (data.subtitle != null) ...[
                    SizedBox(height: size.getItemSpacing() / 4),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                      ), // Align with name (icon width + spacing)
                      child: Text(
                        data.subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color:
                              isDark
                                  ? Colors.grey.shade500
                                  : const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 16,
              child: AnimatedFlipCounter(
                value: data.current * itemAnimation.value,
                fractionDigits: data.current % 1 != 0 ? 1 : 0,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: data.color,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: size.getItemSpacing() / 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress * itemAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
