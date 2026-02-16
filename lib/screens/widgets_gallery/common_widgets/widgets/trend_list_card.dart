import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/trend_list_card_data.dart';

/// 趋势列表卡片小组件
/// 用于显示股票、指数、价格等带有趋势变化的列表数据
class TrendListCardWidget extends StatefulWidget {
  /// 卡片数据
  final TrendListCardData data;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const TrendListCardWidget({
    super.key,
    required this.data,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory TrendListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TrendListCardWidget(
      data: TrendListCardData.fromJson(props),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<TrendListCardWidget> createState() => _TrendListCardWidgetState();
}

class _TrendListCardWidgetState extends State<TrendListCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF161618) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 340,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isDark),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildItems(context, isDark),
                      ),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary.withOpacity(0.4);
    final iconData = _getIconData(widget.data.iconName);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            size: 20,
            color: isDark ? Colors.green.shade900 : Colors.green.shade700,
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing()),
        Flexible(
          child: Text(
            widget.data.title,
            style: TextStyle(
              fontSize: widget.size.getTitleFontSize(),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(BuildContext context, bool isDark) {
    final List<Widget> widgets = [];

    for (int i = 0; i < widget.data.items.length; i++) {
      if (i > 0) {
        widgets.add(SizedBox(height: widget.size.getItemSpacing()));
      }
      widgets.add(
        _TrendItemWidget(
          data: widget.data.items[i],
          animation: _animation,
          index: i,
          size: widget.size,
        ),
      );
    }

    return widgets;
  }

  /// 根据图标名称获取图标数据
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'monetization_on':
        return Icons.monetization_on;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'attach_money':
        return Icons.attach_money;
      case 'euro':
        return Icons.euro;
      case 'yen':
        return Icons.currency_yen;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.trending_up;
    }
  }
}

/// 趋势列表项组件
class _TrendItemWidget extends StatelessWidget {
  final TrendItemData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _TrendItemWidget({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.1,
        0.5 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    final trendColor =
        data.isPositive
            ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
            : (isDark ? Colors.red.shade400 : Colors.red.shade500);

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Icon(
            data.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 24,
            color: trendColor,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.symbol,
                style: TextStyle(
                  fontSize: size.getSubtitleFontSize() * 0.8,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: size.getSmallSpacing()),
              SizedBox(
                height: 24,
                child: AnimatedFlipCounter(
                  value: data.value * itemAnimation.value,
                  fractionDigits: 2,
                  textStyle: TextStyle(
                    fontSize: size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${data.isPositive ? '+' : ''}${data.percentChange.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: size.getSubtitleFontSize(),
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: size.getSmallSpacing()),
            SizedBox(
              height: 20,
              child: Text(
                '${data.isPositive ? '+' : ''}${data.valueChange.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: size.getSubtitleFontSize(),
                  fontWeight: FontWeight.w500,
                  color: trendColor.withOpacity(0.8),
                  height: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
