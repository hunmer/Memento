import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/bill/models/bill_model.dart';
import 'package:Memento/plugins/bill/models/bill.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'bill_edit_screen.dart';
import 'account_list_screen.dart';
import 'subscription_list_screen.dart';

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
  String _searchQuery = '';

  // 搜索过滤器状态
  final Map<String, bool> _searchFilters = {
    'category': true, // 是否搜索分类
    'note': true,     // 是否搜索笔记
  };

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
    // 初始化日历格式为月视图
    _calendarFormat = CalendarFormat.month;

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

    return ConstrainedBox(
      constraints: BoxConstraints.tight(
        Size(48, 48), // 设置固定宽度和高度，确保每个单元格尺寸一致（调整高度避免约束冲突）
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.2) : null,
          border: isToday ? Border.all(color: _primaryColor, width: 2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? _primaryColor : null,
              ),
            ),
            if (stats != null && isIncomePositive)
              Positioned(
                top: -6,
                left: 22,
                child: _buildStatBadge(stats.income, _incomeColor),
              ),
            if (stats != null && isExpensePositive)
              Positioned(
                top: -6,
                right: 22,
                child: _buildStatBadge(stats.expense, _expenseColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        amount.toInt().toString(),
        style: TextStyle(
          fontSize: 7,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<BillModel> get _selectedDayBills {
    if (_selectedDay == null) return [];

    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    return _allMonthBills.where((bill) {
      final billDate = DateTime(bill.date.year, bill.date.month, bill.date.day);
      return isSameDay(billDate, selectedDate);
    }).toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('bill_billList'.tr),
      largeTitle: 'bill_billList'.tr,
      enableSearchBar: true,
      searchPlaceholder: 'bill_searchPlaceholder'.tr,
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      enableSearchFilter: true,
      filterLabels: const {
        'category': '分类',
        'note': '笔记',
      },
      onSearchFilterChanged: (filters) {
        setState(() {
          _searchFilters.addAll(filters);
        });
      },
      searchBody: _buildSearchBody(),
      body: _buildMainBody(),
      enableLargeTitle: true,
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          tooltip: 'bill_accountManagement'.tr,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountListScreen(
                  billPlugin: widget.billPlugin,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.subscriptions),
          tooltip: '订阅服务',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionListScreen(
                  billPlugin: widget.billPlugin,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            NavigationHelper.openContainer<bool>(
              context,
              (BuildContext context) {
                return BillEditScreen(
                  billPlugin: widget.billPlugin,
                  accountId: widget.accountId,
                  initialDate: _selectedDay ?? DateTime.now(),
                  onSaved: () {
                    _loadMonthBills();
                  },
                );
              },
              closedColor: Colors.transparent,
              closedElevation: 0.0,
              closedShape: const RoundedRectangleBorder(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainBody() {
    return SingleChildScrollView(
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
                padding: EdgeInsets.zero,
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
                              title: Text('bill_confirmDelete'.tr),
                              content: Text('bill_confirmDeleteThisBill'.tr),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('bill_cancel'.tr),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text('bill_delete'.tr),
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
                          Toast.error('删除失败: $e');
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bill.color.withOpacity(0.2),
                          child: Icon(bill.icon, color: bill.color),
                        ),
                        title: Text(bill.title),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(bill.date),
                        ),
                        trailing: Text(
                          '${bill.isExpense ? '-' : '+'}${_formatCurrency(bill.amount)}',
                          style: TextStyle(
                            color:
                                bill.isExpense
                                    ? _expenseColor
                                    : _incomeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          NavigationHelper.openContainer<bool>(
                            context,
                            (BuildContext context) {
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
                              return BillEditScreen(
                                billPlugin: widget.billPlugin,
                                accountId: widget.accountId,
                                bill: billObject,
                                onSaved: () {
                                  _loadMonthBills();
                                },
                              );
                            },
                            closedColor: Colors.transparent,
                            closedElevation: 0.0,
                            closedShape: const RoundedRectangleBorder(),
                          );
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
    );
  }

  Widget _buildSearchBody() {
    // 过滤账单
    List<BillModel> filteredBills = _allMonthBills;

    if (_searchQuery.isNotEmpty) {
      filteredBills = filteredBills.where((bill) {
        final query = _searchQuery.toLowerCase();

        // 按名称搜索
        final matchTitle = bill.title.toLowerCase().contains(query);

        // 按分类搜索（如果启用）
        final matchCategory = (_searchFilters['category'] ?? true) &&
            bill.category.toLowerCase().contains(query);

        // 按笔记搜索（如果启用）
        final matchNote = (_searchFilters['note'] ?? true) &&
            (bill.note?.toLowerCase().contains(query) ?? false);

        // 满足任一条件即匹配
        return matchTitle || matchCategory || matchNote;
      }).toList();
    }

    if (_searchQuery.isNotEmpty && filteredBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的账单',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBills.length,
      itemBuilder: (context, index) {
        final bill = filteredBills[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: bill.color.withOpacity(0.2),
              child: Icon(bill.icon, color: bill.color),
            ),
            title: Text(bill.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy-MM-dd HH:mm').format(bill.date)),
                if (bill.note?.isNotEmpty == true)
                  Text(
                    bill.note!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            trailing: Text(
              '${bill.isExpense ? '-' : '+'}${_formatCurrency(bill.amount)}',
              style: TextStyle(
                color: bill.isExpense ? _expenseColor : _incomeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              NavigationHelper.openContainer<bool>(
                context,
                (BuildContext context) {
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
                  return BillEditScreen(
                    billPlugin: widget.billPlugin,
                    accountId: widget.accountId,
                    bill: billObject,
                    onSaved: () {
                      _loadMonthBills();
                    },
                  );
                },
                closedColor: Colors.transparent,
                closedElevation: 0.0,
                closedShape: const RoundedRectangleBorder(),
              );
            },
          ),
        );
      },
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
      backgroundColor: Colors.grey[100],
      selectedColor: _primaryColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? _primaryColor : Colors.grey[300]!,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? _primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DailyStats {
  double income = 0;
  double expense = 0;
}
