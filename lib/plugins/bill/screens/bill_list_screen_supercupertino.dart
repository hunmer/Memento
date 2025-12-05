import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import '../l10n/bill_localizations.dart';
import '../models/bill_model.dart';
import '../models/bill.dart';
import '../bill_plugin.dart';
import '../widgets/month_selector.dart';
import 'bill_edit_screen.dart';

class BillListScreenSupercupertino extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;

  const BillListScreenSupercupertino({
    super.key,
    required this.billPlugin,
    required this.accountId,
  });

  @override
  State<BillListScreenSupercupertino> createState() => _BillListScreenSupercupertinoState();
}

class _BillListScreenSupercupertinoState extends State<BillListScreenSupercupertino> {
  late final void Function() _billPluginListener;

  // Calendar State
  late CalendarFormat _calendarFormat;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data State
  List<BillModel> _allMonthBills = []; // All bills for the focused month
  Map<DateTime, _DailyStats> _dailyStats = {};

  String _filterCategory = 'all'; // 'all', 'income', 'expense', or specific category name

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

    // 监听插件数据变化，自动刷新
    _billPluginListener = () {
      if (mounted) {
        _loadMonthBills();
      }
    };
    widget.billPlugin.addListener(_billPluginListener);
  }

  @override
  void dispose() {
    widget.billPlugin.removeListener(_billPluginListener);
    super.dispose();
  }

  void _loadMonthBills() {
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

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (e) {
      return {'income': 0, 'expense': 0, 'balance': 0};
    }
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected) {
    final date = DateTime(day.year, day.month, day.day);
    final stats = _dailyStats[date];
    final isToday = isSameDay(DateTime.now(), day);
    final isIncomePositive = (stats?.income ?? 0) > 0;
    final isExpensePositive = (stats?.expense ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor.withOpacity(0.2) : null,
        border: isToday
            ? Border.all(color: _primaryColor, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? _primaryColor : null,
            ),
          ),
          if (stats != null && (isIncomePositive || isExpensePositive))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isIncomePositive)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: _incomeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isIncomePositive && isExpensePositive) const SizedBox(width: 2),
                  if (isExpensePositive)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: _expenseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<BillModel> get _filteredBills {
    if (_filterCategory == 'all') {
      return _allMonthBills;
    } else if (_filterCategory == 'income') {
      return _allMonthBills.where((bill) => !bill.isExpense).toList();
    } else if (_filterCategory == 'expense') {
      return _allMonthBills.where((bill) => bill.isExpense).toList();
    } else {
      return _allMonthBills.where((bill) => bill.category == _filterCategory).toList();
    }
  }

  List<BillModel> get _selectedDayBills {
    if (_selectedDay == null) return [];

    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    return _filteredBills.where((bill) {
      final billDate = DateTime(bill.date.year, bill.date.month, bill.date.day);
      return isSameDay(billDate, selectedDate);
    }).toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BillLocalizations.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(l10n.billList),
      largeTitle: l10n.billList,
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
                todayBuilder: (context, day, focusedDay) =>
                    _buildCalendarCell(day, isSameDay(day, _selectedDay ?? DateTime.now())),
              ),
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('all', '全部', Icons.list),
                  _buildFilterChip('income', '收入', Icons.arrow_downward),
                  _buildFilterChip('expense', '支出', Icons.arrow_upward),
                ],
              ),
            ),

            // Daily Bills List
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDay!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              if (_selectedDayBills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '这一天没有账单',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedDayBills.length,
                  itemBuilder: (context, index) {
                    final bill = _selectedDayBills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Dismissible(
                        key: Key(bill.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('确认删除'),
                                content: const Text('确定要删除这条账单吗？'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('删除'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) async {
                          try {
                            final currentAccount = widget.billPlugin.accounts.firstWhere(
                              (account) => account.id == widget.accountId,
                            );
                            await widget.billPlugin.controller.deleteBill(
                              currentAccount.id,
                              bill.id,
                            );
                            _loadMonthBills();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('删除失败: $e')),
                            );
                          }
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bill.color.withOpacity(0.2),
                            child: Icon(
                              bill.icon,
                              color: bill.color,
                            ),
                          ),
                          title: Text(bill.title),
                          subtitle: Text(
                            DateFormat('HH:mm').format(bill.date),
                          ),
                          trailing: Text(
                            '${bill.isExpense ? '-' : '+'}${_formatCurrency(bill.amount)}',
                            style: TextStyle(
                              color: bill.isExpense ? _expenseColor : _incomeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            final billObject = Bill(
                              id: bill.id,
                              title: bill.title,
                              amount: bill.isExpense ? -bill.amount : bill.amount,
                              accountId: widget.accountId,
                              category: bill.category,
                              date: bill.date,
                              tag: bill.category,
                              note: bill.note ?? '',
                              createdAt: bill.date,
                              icon: bill.icon,
                              iconColor: bill.color,
                            );

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BillEditScreen(
                                  billPlugin: widget.billPlugin,
                                  accountId: widget.accountId,
                                  bill: billObject,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadMonthBills();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
            ] else
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '请选择一天查看账单',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      enableLargeTitle: true,
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BillEditScreen(
                  billPlugin: widget.billPlugin,
                  accountId: widget.accountId,
                ),
              ),
            );
            if (result == true) {
              _loadMonthBills();
            }
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterCategory = value;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? _primaryColor : Colors.grey[600],
      ),
    );
  }
}

class _DailyStats {
  double income = 0;
  double expense = 0;
}
