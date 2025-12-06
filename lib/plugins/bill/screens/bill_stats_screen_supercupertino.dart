import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import '../bill_plugin.dart';
import '../models/bill_model.dart';
import '../widgets/month_selector.dart';

class BillStatsScreenSupercupertino extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const BillStatsScreenSupercupertino({
    super.key,
    required this.billPlugin,
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<BillStatsScreenSupercupertino> createState() => _BillStatsScreenSupercupertinoState();
}

class _BillStatsScreenSupercupertinoState extends State<BillStatsScreenSupercupertino> {
  late DateTime _selectedMonth;
  bool _isExpenseSelected = true;
  final Set<String> _expandedCategories = {};

  // Colors from design
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _primaryColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    // 默认显示当前月份，而不是 startDate 的月份
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void didUpdateWidget(BillStatsScreenSupercupertino oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 不再根据 startDate 更新选中月份，保持用户当前选择的月份
    // 这样用户在浏览不同月份时不会因为组件更新而被重置
  }

  List<BillModel> _getBillsForMonth(DateTime month) {
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

      return bills
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
    } catch (e) {
      return [];
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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _expandedCategories.clear();
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = _getBillsForMonth(_selectedMonth);

    double totalIncome = 0;
    double totalExpense = 0;
    for (var bill in bills) {
      if (bill.isExpense) {
        totalExpense += bill.amount;
      } else {
        totalIncome += bill.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    // Filter bills for the list based on toggle
    final listBills = bills.where((b) => b.isExpense == _isExpenseSelected).toList();
    final totalListAmount = _isExpenseSelected ? totalExpense : totalIncome;

    // Group by Category
    final categoryStats = <String, _CategoryData>{};
    for (var bill in listBills) {
      if (!categoryStats.containsKey(bill.category)) {
        categoryStats[bill.category] = _CategoryData(
          name: bill.category,
          amount: 0,
          icon: bill.icon,
          color: bill.color,
        );
      }
      categoryStats[bill.category]!.amount += bill.amount;

      // Group by Title for sub-items
      final subMap = categoryStats[bill.category]!.subItems;
      final key = bill.title.isNotEmpty ? bill.title : '其他';
      subMap[key] = (subMap[key] ?? 0) + bill.amount;
    }

    final sortedCategories = categoryStats.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SuperCupertinoNavigationWrapper(
      title: const Text('统计分析'),
      largeTitle: '统计分析',
      enableSearchBar: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section (Month Strip)
            _buildHeader(isDark),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary Card
                  _buildSummaryCard(isDark, totalIncome, totalExpense, balance),

                  const SizedBox(height: 16),

                  // Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Toggle Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    _buildToggleButton('支出', true, isDark),
                                    _buildToggleButton('收入', false, isDark),
                                  ],
                                ),
                              ),
                              Text(
                                '¥${totalListAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List
                        if (sortedCategories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '暂无数据',
                              style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: sortedCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final category = sortedCategories[index];
                              final percentage = totalListAmount > 0
                                  ? category.amount / totalListAmount
                                  : 0.0;
                              return _buildCategoryItem(category, percentage, isDark);
                            },
                          ),
                      ],
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
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(200), // Glassmorphism-ish
      child: Column(
        children: [
          // Year and Nav
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '统计报表',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: () => _changeMonth(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${_selectedMonth.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () => _changeMonth(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Month Strip
          MonthSelector(
            selectedMonth: _selectedMonth,
            onMonthSelected: (month) {
              setState(() {
                _selectedMonth = month;
                _expandedCategories.clear();
              });
            },
            getMonthStats: _getMonthStats,
            primaryColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, double totalIncome, double totalExpense, double balance) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                ]
              : [
                  const Color(0xFF3B82F6),
                  const Color(0xFF2563EB),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本月总览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.white.withOpacity(0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('yyyy年MM月').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '收入',
                _formatCurrency(totalIncome),
                _incomeColor,
                Icons.arrow_downward,
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
              ),
              _buildSummaryItem(
                '支出',
                _formatCurrency(totalExpense),
                _expenseColor,
                Icons.arrow_upward,
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
              ),
              _buildSummaryItem(
                '结余',
                _formatCurrency(balance),
                balance >= 0 ? _incomeColor : _expenseColor,
                balance >= 0 ? Icons.check_circle : Icons.warning,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[200] : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isExpense, bool isDark) {
    final isSelected = (_isExpenseSelected && isExpense) || (!_isExpenseSelected && !isExpense);
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpenseSelected = isExpense;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(_CategoryData category, double percentage, bool isDark) {
    final isExpanded = _expandedCategories.contains(category.name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.2),
              child: Icon(
                category.icon,
                color: category.color,
              ),
            ),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Text(
              _formatCurrency(category.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[200] : const Color(0xFF0F172A),
              ),
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category.name);
                } else {
                  _expandedCategories.add(category.name);
                }
              });
            },
          ),
          if (isExpanded && category.subItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 64, right: 16, bottom: 12),
              child: Column(
                children: category.subItems.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(entry.value),
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String name;
  double amount;
  final IconData icon;
  final Color color;
  final Map<String, double> subItems = {};

  _CategoryData({
    required this.name,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
