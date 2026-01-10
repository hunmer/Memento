import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 趋势列表卡片示例
class TrendListCardExample extends StatelessWidget {
  const TrendListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趋势列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TrendListCardWidget(
            title: 'Stocks',
            icon: Icons.monetization_on,
            items: [
              TrendItemData(
                symbol: 'ELM.35',
                value: 7877.05,
                percentChange: 0.37,
                valueChange: 29.06,
                isPositive: true,
              ),
              TrendItemData(
                symbol: 'URP.20',
                value: 5009.71,
                percentChange: -0.25,
                valueChange: -12.50,
                isPositive: false,
              ),
              TrendItemData(
                symbol: 'CAC.40',
                value: 1958.08,
                percentChange: 0.52,
                valueChange: 10.13,
                isPositive: true,
              ),
              TrendItemData(
                symbol: 'YET',
                value: 8023.26,
                percentChange: 0.52,
                valueChange: 41.75,
                isPositive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 趋势项数据模型
class TrendItemData {
  final String symbol;
  final double value;
  final double percentChange;
  final double valueChange;
  final bool isPositive;

  const TrendItemData({
    required this.symbol,
    required this.value,
    required this.percentChange,
    required this.valueChange,
    required this.isPositive,
  });
}

/// 趋势列表卡片小组件
/// 用于显示股票、指数、价格等带有趋势变化的列表数据
class TrendListCardWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<TrendItemData> items;

  const TrendListCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

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
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: isDark
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
                  const SizedBox(height: 32),
                  ..._buildItems(context, isDark),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: isDark ? Colors.green.shade900 : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.add,
              size: 24,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.refresh,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildItems(BuildContext context, bool isDark) {
    final List<Widget> widgets = [];

    for (int i = 0; i < widget.items.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 20));
      }
      widgets.add(
        _TrendItemWidget(
          data: widget.items[i],
          animation: _animation,
          index: i,
        ),
      );
    }

    return widgets;
  }
}

/// 趋势列表项组件
class _TrendItemWidget extends StatelessWidget {
  final TrendItemData data;
  final Animation<double> animation;
  final int index;

  const _TrendItemWidget({
    required this.data,
    required this.animation,
    required this.index,
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

    final trendColor = data.isPositive
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 24,
                child: AnimatedFlipCounter(
                  value: data.value * itemAnimation.value,
                  fractionDigits: 2,
                  textStyle: TextStyle(
                    fontSize: 18,
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 20,
              child: Text(
                '${data.isPositive ? '+' : ''}${data.valueChange.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: trendColor.withOpacity(0.8),
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
