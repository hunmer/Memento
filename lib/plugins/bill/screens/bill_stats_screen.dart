import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/bill_model.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';

class BillStatsScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const BillStatsScreen({
    super.key,
    required this.billPlugin,
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<BillStatsScreen> createState() => _BillStatsScreenState();
}

class _BillStatsScreenState extends State<BillStatsScreen> {
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
  void didUpdateWidget(BillStatsScreen oldWidget) {
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

      return currentAccount.bills
          .where((bill) {
            return bill.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
                   bill.createdAt.isBefore(monthEnd.add(const Duration(seconds: 1)));
          })
          .map((bill) => BillModel(
            id: bill.id,
            title: bill.title,
            amount: bill.absoluteAmount,
            date: bill.createdAt,
            icon: bill.icon,
            color: bill.iconColor,
            category: bill.tag ?? '未分类',
            note: bill.note,
            isExpense: bill.isExpense,
          ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, double> _getMonthStats(DateTime month) {
    final bills = _getBillsForMonth(month);
    double income = 0;
    double expense = 0;
    
    for (var bill in bills) {
      if (bill.isExpense) {
        expense += bill.amount;
      } else {
        income += bill.amount;
      }
    }
    
    return {'income': income, 'expense': expense};
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + monthsToAdd);
      _expandedCategories.clear();
    });
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

    return SingleChildScrollView(
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

  Widget _buildSummaryCard(bool isDark, double income, double expense, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('总收入', income, _incomeColor, Icons.arrow_downward, isDark),
              _buildSummaryItem('总支出', expense, _expenseColor, Icons.arrow_upward, isDark),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '结余',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              Text(
                '${balance >= 0 ? '+' : ''}${_formatCurrency(balance)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${color == _incomeColor ? '+' : '-'}${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isExpense, bool isDark) {
    final isSelected = _isExpenseSelected == isExpense;
    return GestureDetector(
      onTap: () => setState(() => _isExpenseSelected = isExpense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.grey[600] : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 2)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? (isDark ? Colors.white : Colors.grey[900])
                : (isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(_CategoryData category, double percentage, bool isDark) {
    final isExpanded = _expandedCategories.contains(category.name);
// Blue for income bars? Or Green? Design uses colored bars.
        // HTML uses specific colors for categories (Rose, Blue, Orange, Purple, Teal).
        // Since we don't have per-category colors in BillModel (we have iconColor), use that!
    final itemColor = category.color; // Use bill's color

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCategories.remove(category.name);
              } else {
                _expandedCategories.add(category.name);
              }
            });
          },
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: itemColor, size: 24),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        Text(
                          '¥${category.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
        
        // Sub Items
        if (isExpanded && category.subItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 12), // Indent to align with text
            child: Column(
              children: category.subItems.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!, width: 2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '¥${entry.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount.abs());
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
