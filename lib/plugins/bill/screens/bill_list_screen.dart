import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Memento/plugins/bill/models/bill_model.dart';
import 'package:Memento/plugins/bill/models/bill.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'bill_edit_screen.dart';

class BillListScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;

  const BillListScreen({
    super.key,
    required this.billPlugin,
    required this.accountId,
  });

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  late final void Function() _billPluginListener;

  // Calendar State
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data State
  List<BillModel> _allMonthBills = []; // All bills for the focused month
  Map<DateTime, _DailyStats> _dailyStats = {};

    String _filterCategory =
      'all'; // 'all', 'income', 'expense', or specific category name

  // Colors
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _primaryColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    // 确保默认选中今天
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _billPluginListener = () {
      if (mounted) {
        _loadMonthBills();
      }
    };
    widget.billPlugin.addListener(_billPluginListener);

    // 使用 WidgetsBinding 确保在第一帧渲染后再加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 添加额外延迟确保插件完全初始化
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadMonthBills();
        }
      });
    });
  }

  @override
  void dispose() {
    if (mounted) {
      widget.billPlugin.removeListener(_billPluginListener);
    }
    super.dispose();
  }

  void _loadMonthBills() {
    if (!mounted) return;

    // 检查账户数据是否可用
    if (widget.billPlugin.accounts.isEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _loadMonthBills();
        }
      });
      return;
    }

    try {
      final currentAccount = widget.billPlugin.accounts.firstWhere(
        (account) => account.id == widget.accountId,
      );
      // Calculate month start and end
      final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final monthEnd = DateTime(
        _focusedDay.year,
        _focusedDay.month + 1,
        0,
        23,
        59,
        59,
      );

      final filteredBills = currentAccount.bills.where(
        (bill) =>
            bill.date.isAfter(
              monthStart.subtract(const Duration(seconds: 1)),
            ) &&
            bill.date.isBefore(monthEnd.add(const Duration(seconds: 1))),
      );

      final bills =
          filteredBills
              .map(
                (bill) => BillModel(
                  id: bill.id,
                  title: bill.title,
                  amount: bill.absoluteAmount,
                  date: bill.date,
                  icon: bill.icon,
                  color: bill.iconColor,
                  category: bill.tag ?? '未分类',
                  note: bill.note,
                  isExpense: bill.isExpense,
                ),
              )
              .toList();

      // Sort by date descending
      bills.sort((a, b) => b.date.compareTo(a.date));

      // Calculate daily stats
      final stats = <DateTime, _DailyStats>{};
      for (var bill in bills) {
        final date = DateTime(bill.date.year, bill.date.month, bill.date.day);
        if (!stats.containsKey(date)) {
          stats[date] = _DailyStats();
        }
        if (bill.isExpense) {
          stats[date]!.expense += bill.amount;
        } else {
          stats[date]!.income += bill.amount;
        }
      }

      if (mounted) {
        setState(() {
          _allMonthBills = bills;
          _dailyStats = stats;
        });

        // 强制刷新日历显示
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      debugPrint('加载账单失败: $e');
    }
  }

  Map<String, double> _getMonthStats(DateTime month) {
    try {
      final currentAccount = widget.billPlugin.accounts.firstWhere(
        (account) => account.id == widget.accountId,
      );

      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final bills = currentAccount.bills.where(
        (bill) =>
            bill.date.isAfter(
              monthStart.subtract(const Duration(seconds: 1)),
            ) &&
            bill.date.isBefore(monthEnd.add(const Duration(seconds: 1))),
      );

      double income = 0;
      double expense = 0;

      for (var bill in bills) {
        if (bill.isExpense) {
          expense += bill.absoluteAmount;
        } else {
          income += bill.absoluteAmount;
        }
      }

      return {'income': income, 'expense': expense};
    } catch (e) {
      return {'income': 0, 'expense': 0};
    }
  }

  Future<void> _navigateToBillEdit(
    BuildContext context, [
    BillModel? billModel,
  ]) async {
    Bill? bill;
    if (billModel != null) {
      bill = Bill(
        id: billModel.id,
        title: billModel.title,
        amount: billModel.isExpense ? -billModel.amount : billModel.amount,
        accountId: widget.accountId,
        category: billModel.category,
        date: billModel.date,
        tag: billModel.category,
        note: billModel.note ?? '',
        createdAt: billModel.date,
        icon: billModel.icon,
        iconColor: billModel.color,
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF101622)
                            : const Color(0xFFF6F6F8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: BillEditScreen(
                    billPlugin: widget.billPlugin,
                    accountId: widget.accountId,
                    bill: bill,
                    initialDate: _selectedDay ?? DateTime.now(),
                  ),
                ),
          ),
    );
  }

  List<BillModel> get _filteredBills {
    // 如果没有选中日期，默认使用今天
    final selectedDate = _selectedDay ?? DateTime.now();

    final dayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final dayEnd = dayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    var bills =
        _allMonthBills
            .where(
              (bill) =>
                  bill.date.isAfter(
                    dayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  bill.date.isBefore(dayEnd.add(const Duration(seconds: 1))),
            )
            .toList();

    if (_filterCategory == 'all') return bills;
    if (_filterCategory == 'income') {
      return bills.where((b) => !b.isExpense).toList();
    }
    if (_filterCategory == 'expense') {
      return bills.where((b) => b.isExpense).toList();
    }

    return bills.where((b) => b.category == _filterCategory).toList();
  }

  List<String> get _availableCategories {
    final categories = {'all', 'income', 'expense'};
    // Add categories from current month's bills
    for (var bill in _allMonthBills) {
      categories.add(bill.category);
    }
    return categories.toList();
  }

  String _getCategoryLabel(String key) {
    switch (key) {
      case 'all':
        return 'bill_all'.tr;
      case 'income':
        return 'bill_income'.tr;
      case 'expense':
        return 'bill_expense'.tr;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month Selector
            MonthSelector(
              selectedMonth: _focusedDay,
              onMonthSelected: (month) {
                setState(() {
                  _focusedDay = month;
                  _loadMonthBills();
                });
              },
              getMonthStats: _getMonthStats,
              primaryColor: _primaryColor,
            ),

            // Calendar
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                // 确保选中判断正确，即使 _selectedDay 为 null 也选中今天
                if (_selectedDay == null) {
                  return isSameDay(DateTime.now(), day);
                }
                return isSameDay(_selectedDay!, day);
              },
              headerVisible: false,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonthBills();
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder:
                    (context, day, focusedDay) => _buildCalendarCell(day, false),
                selectedBuilder:
                    (context, day, focusedDay) => _buildCalendarCell(day, true),
                todayBuilder:
                    (context, day, focusedDay) =>
                        _buildCalendarCell(day, isSameDay(_selectedDay, day)),
              ),
              daysOfWeekHeight: 40,
              rowHeight: 64,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                weekendStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dowTextFormatter:
                    (date, locale) =>
                        DateFormat.E(locale).format(date)[0], // S M T W T F S
              ),
            ),

            // Date Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat(
                    'MMMM d, EEEE',
                    Localizations.localeOf(context).toString(),
                  ).format(_selectedDay ?? DateTime.now()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Content - Only List View
            _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final stats = _dailyStats[dateKey];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(2),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.grey[800]),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 2),
            if (stats.income > 0)
              Text(
                '+${stats.income.toInt()}',
                style: TextStyle(
                  color:
                      isSelected ? Colors.white.withAlpha(230) : _incomeColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (stats.expense > 0)
              Text(
                '-${stats.expense.toInt()}',
                style: TextStyle(
                  color:
                      isSelected ? Colors.white.withAlpha(230) : _expenseColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ],
      ),
    );
  }

  
  Widget _buildListView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredBills = _filteredBills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _availableCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _availableCategories[index];
              final isSelected = _filterCategory == category;
              return ActionChip(
                label: Text(_getCategoryLabel(category)),
                backgroundColor:
                    isSelected
                        ? _primaryColor
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                labelStyle: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  fontWeight: FontWeight.w500,
                ),
                shape: const StadiumBorder(side: BorderSide.none),
                onPressed: () => setState(() => _filterCategory = category),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Bill List
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // 增加底部padding为悬浮按钮留空间
          child: filteredBills.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Text(
                      'bill_noBills'.tr,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : Column(
                  children: filteredBills.asMap().entries.map((entry) {
                    final index = entry.key;
                    final bill = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < filteredBills.length - 1 ? 12 : 0),
                      child: _buildBillCard(bill, isDark),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildBillCard(BillModel bill, bool isDark) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '¥',
      decimalDigits: 0,
    ); // HTML shows no decimals

    // Determine colors based on HTML style
    // Income: Emerald bg/text
    // Expense: Rose bg/text
    // Use lighter variants for background

    Color iconBgColor;
    Color iconColor;
    Color amountColor;

    if (bill.isExpense) {
      iconBgColor =
          isDark
              ? const Color(0x4D9F1239)
              : const Color(0xFFFFF1F2); // Rose 900/30 or 50
      iconColor =
          isDark
              ? const Color(0xFFFDA4AF)
              : const Color(0xFFE11D48); // Rose 300 or 600
      amountColor = _expenseColor;
    } else {
      iconBgColor =
          isDark
              ? const Color(0x4D065F46)
              : const Color(0xFFECFDF5); // Emerald 900/30 or 50
      iconColor =
          isDark
              ? const Color(0xFF6EE7B7)
              : const Color(0xFF059669); // Emerald 300 or 600
      amountColor = _incomeColor;
    }

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('bill_confirmDelete'.tr),
                content: Text(
                  'bill_deleteBillConfirmation'.tr,
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('bill_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'bill_delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (_) {
        widget.billPlugin.controller.deleteBill(widget.accountId, bill.id);
        setState(() {
          _allMonthBills.removeWhere((b) => b.id == bill.id);
          // Re-calc stats for that day would be ideal, but reload is safer/easier
          _loadMonthBills();
        });
      },
      child: GestureDetector(
        onTap: () => _navigateToBillEdit(context, bill),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30), // More subtle inner bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(bill.icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title.isNotEmpty ? bill.title : bill.category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    if (bill.note != null && bill.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bill.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                (bill.isExpense ? '-' : '+') +
                    currencyFormatter.format(bill.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyStats {
  double income = 0;
  double expense = 0;
}
