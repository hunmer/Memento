import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 月份选择器组件
/// 显示一个水平滚动的月份列表，每个月份卡片显示收入和支出统计
/// 支持无限滚动和桌面端鼠标滚轮操作
class MonthSelector extends StatefulWidget {
  /// 当前选中的月份
  final DateTime? selectedMonth;

  /// 月份选择回调
  final ValueChanged<DateTime> onMonthSelected;

  /// 获取指定月份的统计数据
  final Map<String, double> Function(DateTime month) getMonthStats;

  /// 主题色
  final Color primaryColor;

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
  late DateTime _selectedMonth;
  List<DateTime> _allMonths = [];
  bool _isLoading = false;

  // 每次加载的月份数量
  static const int _loadCount = 25;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedMonth = widget.selectedMonth ?? DateTime.now();
    _initializeMonths();

    // 添加滚动监听器
    _scrollController.addListener(_onScroll);

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
      _scrollToSelectedMonth();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化月份列表
  void _initializeMonths() {
    final now = DateTime.now();
    final months = <DateTime>[];

    // 生成前后各 _loadCount 个月的月份
    for (int i = -_loadCount; i <= _loadCount; i++) {
      months.add(DateTime(now.year, now.month + i));
    }

    _allMonths = months;
  }

  /// 滚动事件监听
  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 200.0; // 触发加载的阈值

    // 当滚动到左边界时，向左扩展月份
    if (currentScroll < threshold) {
      _loadMoreMonths(left: true);
    }
    // 当滚动到右边界时，向右扩展月份
    else if (currentScroll > maxScroll - threshold) {
      _loadMoreMonths(left: false);
    }
  }

  /// 加载更多月份
  void _loadMoreMonths({required bool left}) {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final newMonths = <DateTime>[];
    final loadCount = 10;

    if (left) {
      // 向左加载（更早的月份）
      final firstMonth = _allMonths.first;
      for (int i = 1; i <= loadCount; i++) {
        newMonths.add(DateTime(firstMonth.year, firstMonth.month - i));
      }
      newMonths.addAll(_allMonths);
    } else {
      // 向右加载（更晚的月份）
      final lastMonth = _allMonths.last;
      for (int i = 1; i <= loadCount; i++) {
        newMonths.add(DateTime(lastMonth.year, lastMonth.month + i));
      }
      _allMonths.addAll(newMonths);
      return;
    }

    _allMonths = newMonths;

    // 恢复滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemWidth = 80.0 + 12; // 卡片宽度 + 间距
        final newOffset = _scrollController.offset + (itemWidth * loadCount);
        _scrollController.jumpTo(newOffset);
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  /// 滚动到选中的月份
  void _scrollToSelectedMonth() {
    final selectedIndex = _allMonths.indexWhere(
      (month) =>
          month.year == _selectedMonth.year &&
          month.month == _selectedMonth.month,
    );

    if (selectedIndex != -1 && _scrollController.hasClients) {
      // 计算滚动位置，让选中月份居中显示
      final itemWidth = 80.0 + 12; // 卡片宽度 + 间距
      final viewportWidth = _scrollController.position.viewportDimension;
      final targetOffset =
          (selectedIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 格式化月份显示为 "25年/6月" 格式
  String _formatMonth(DateTime month) {
    final year = month.year.toString().substring(2); // 取后两位
    return '$year年/${month.month}月';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerSignal: (event) {
        // 处理鼠标滚轮事件
        if (event is PointerScrollEvent && _scrollController.hasClients) {
          final newOffset = _scrollController.offset + event.scrollDelta.dy;
          _scrollController.jumpTo(
            newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        }
      },
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _allMonths.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final month = _allMonths[index];
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
                      _formatMonth(month),
                      style: TextStyle(
                        fontSize: 12,
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
