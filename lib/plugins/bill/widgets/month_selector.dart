import 'package:flutter/material.dart';

/// 月份选择器组件
/// 显示一个水平滚动的月份列表，每个月份卡片显示收入和支出统计
/// 默认选择当前月份，以当前月份为中心显示12个月份，支持虚拟滚动
class MonthSelector extends StatefulWidget {
  /// 当前选中的月份
  final DateTime? selectedMonth;

  /// 月份选择回调
  final ValueChanged<DateTime> onMonthSelected;

  /// 获取指定月份的统计数据
  final Map<String, double> Function(DateTime month) getMonthStats;

  /// 主题色
  final Color primaryColor;

  /// 显示的月份数量（固定为12）
  static const int visibleMonthCount = 12;

  const MonthSelector({
    super.key,
    this.selectedMonth,
    required this.onMonthSelected,
    required this.getMonthStats,
    this.primaryColor = const Color(0xFF3498DB),
  });

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  late ScrollController _scrollController;
  late DateTime _centerMonth;
  late DateTime _selectedMonth;
  List<DateTime> _visibleMonths = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedMonth = widget.selectedMonth ?? DateTime.now();
    _centerMonth = DateTime.now();
    _generateVisibleMonths();

    // 延迟滚动到选中的月份
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
    });
  }

  @override
  void didUpdateWidget(MonthSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMonth != oldWidget.selectedMonth && widget.selectedMonth != null) {
      setState(() {
        _selectedMonth = widget.selectedMonth!;
      });
      _generateVisibleMonths();
      _scrollToSelectedMonth();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 生成可见月份列表（以当前月份为中心的12个月份）
  void _generateVisibleMonths() {
    final months = <DateTime>[];
    final halfCount = MonthSelector.visibleMonthCount ~/ 2;

    // 以中心月份为准，生成前后各半个月的月份
    for (int i = -halfCount; i <= halfCount; i++) {
      months.add(DateTime(_centerMonth.year, _centerMonth.month + i));
    }

    _visibleMonths = months;
  }

  /// 滚动到选中的月份
  void _scrollToSelectedMonth() {
    final selectedIndex = _visibleMonths.indexWhere(
      (month) => month.year == _selectedMonth.year && month.month == _selectedMonth.month,
    );

    if (selectedIndex != -1) {
      // 计算滚动位置，让选中月份居中显示
      final itemWidth = 80.0 + 12; // 卡片宽度 + 间距
      final viewportWidth = _scrollController.hasClients
          ? _scrollController.position.viewportDimension
          : 300; // 默认视口宽度
      final targetOffset = (selectedIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 处理滚动事件，实现虚拟滚动
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0; // 触发加载的阈值

    // 当滚动到左边界时，向左扩展月份
    if (currentScroll < threshold) {
      _extendMonthsLeft();
    }
    // 当滚动到右边界时，向右扩展月份
    else if (currentScroll > maxScroll - threshold) {
      _extendMonthsRight();
    }
  }

  /// 向左扩展月份（智能扩展，避免重复月份）
  void _extendMonthsLeft() {
    setState(() {
      final firstMonth = _visibleMonths.first;
      final newMonths = <DateTime>[];
      final extendCount = 3; // 每次扩展3个月

      for (int i = extendCount; i >= 1; i--) {
        final newMonth = DateTime(firstMonth.year, firstMonth.month - i);
        if (!_isMonthInList(newMonth)) {
          newMonths.add(newMonth);
        }
      }

      if (newMonths.isNotEmpty) {
        _visibleMonths = [...newMonths, ..._visibleMonths];
        // 保持控件数量在合理范围内（最多显示18个月份）
        if (_visibleMonths.length > 18) {
          _visibleMonths = _visibleMonths.sublist(0, 18);
        }
      }
    });
  }

  /// 向右扩展月份（智能扩展，避免重复月份）
  void _extendMonthsRight() {
    setState(() {
      final lastMonth = _visibleMonths.last;
      final newMonths = <DateTime>[];
      final extendCount = 3; // 每次扩展3个月

      for (int i = 1; i <= extendCount; i++) {
        final newMonth = DateTime(lastMonth.year, lastMonth.month + i);
        if (!_isMonthInList(newMonth)) {
          newMonths.add(newMonth);
        }
      }

      if (newMonths.isNotEmpty) {
        _visibleMonths = [..._visibleMonths, ...newMonths];
        // 保持控件数量在合理范围内（最多显示18个月份）
        if (_visibleMonths.length > 18) {
          _visibleMonths = _visibleMonths.sublist(_visibleMonths.length - 18);
        }
      }
    });
  }

  /// 检查月份是否已在列表中
  bool _isMonthInList(DateTime month) {
    return _visibleMonths.any((m) => m.year == month.year && m.month == month.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScroll();
        }
        return false;
      },
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _visibleMonths.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final month = _visibleMonths[index];
            final isSelected = month.year == _selectedMonth.year &&
                             month.month == _selectedMonth.month;
            final stats = widget.getMonthStats(month);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMonth = month;
                });
                widget.onMonthSelected(month);
              },
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.grey[800] : Colors.white)
                      : (isDark ? Colors.transparent : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: widget.primaryColor, width: 2)
                      : null,
                  boxShadow: isSelected || !isDark
                      ? [BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                        )]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${month.month}月',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${_formatCompact(stats['income'] ?? 0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF2ECC71), // 收入颜色
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '-${_formatCompact(stats['expense'] ?? 0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE74C3C), // 支出颜色
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 格式化数字为紧凑形式
  String _formatCompact(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
