import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import '../models/bill.dart';
import '../models/bill_model.dart';

class BillStatsScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Account account;

  const BillStatsScreen({
    super.key,
    required this.billPlugin,
    required this.account,
  });

  @override
  State<BillStatsScreen> createState() => _BillStatsScreenState();
}

class _BillStatsScreenState extends State<BillStatsScreen> {
  List<BillModel> _bills = [];
  bool _isLoading = true;
  String _selectedPeriod = '月';
  DateTime _startDate = DateTime.now();
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    _loadBills();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '周':
        // 本周的开始（周一）到结束（周日）
        final weekday = now.weekday;
        _startDate = now.subtract(Duration(days: weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case '月':
        // 本月的第一天到最后一天
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case '年':
        // 本年的第一天到最后一天
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
    }

    // 将时间设置为当天的开始
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    // 将时间设置为当天的结束
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
    });

    // 从账户中获取指定时间范围内的账单
    final filteredBills = widget.account.bills.where((bill) =>
      bill.createdAt.isAfter(_startDate) &&
      bill.createdAt.isBefore(_endDate.add(const Duration(seconds: 1)))
    );

    // 转换为 BillModel
    final bills = filteredBills.map((bill) => BillModel(
      id: bill.id,
      title: bill.title,
      amount: bill.absoluteAmount,
      date: bill.createdAt,
      icon: bill.icon,
      color: widget.account.backgroundColor,
      category: bill.tag ?? '未分类',
      note: bill.note,
      isExpense: bill.isExpense,
    )).toList();

    setState(() {
      _bills = bills;
      _isLoading = false;
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _updateDateRange();
    _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _bills
        .where((bill) => !bill.isExpense)
        .fold(0.0, (sum, bill) => sum + bill.amount);
        
    final totalExpense = _bills
        .where((bill) => bill.isExpense)
        .fold(0.0, (sum, bill) => sum + bill.amount);
        
    final balance = totalIncome - totalExpense;
    
    // 按类别统计支出
    final expenseByCategory = <String, double>{};
    for (final bill in _bills.where((bill) => bill.isExpense)) {
      if (expenseByCategory.containsKey(bill.category)) {
        expenseByCategory[bill.category] = expenseByCategory[bill.category]! + bill.amount;
      } else {
        expenseByCategory[bill.category] = bill.amount;
      }
    }
    
    // 排序类别支出
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间段选择
                    Row(
                      children: [
                        const Text('时间范围：'),
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: '周',
                              label: Text('本周'),
                            ),
                            ButtonSegment<String>(
                              value: '月',
                              label: Text('本月'),
                            ),
                            ButtonSegment<String>(
                              value: '年',
                              label: Text('本年'),
                            ),
                          ],
                          selected: {_selectedPeriod},
                          onSelectionChanged: (Set<String> newSelection) {
                            _changePeriod(newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('yyyy-MM-dd').format(_startDate)} 至 ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    
                    // 收支概览卡片
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              '收支概览',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  '收入',
                                  totalIncome,
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  '支出',
                                  totalExpense,
                                  Colors.red,
                                ),
                                _buildStatItem(
                                  '结余',
                                  balance,
                                  balance >= 0 ? Colors.blue : Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 饼图展示
                    if (expenseByCategory.isNotEmpty) ...[
                      const Text(
                        '支出分类统计',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(expenseByCategory),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 类别详情列表
                      const Text(
                        '支出类别详情',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...sortedCategories.map((entry) {
                        final category = entry.key;
                        final amount = entry.value;
                        final percentage = (amount / totalExpense * 100).toStringAsFixed(1);
                        
                        return ListTile(
                          title: Text(category),
                          subtitle: LinearProgressIndicator(
                            value: amount / totalExpense,
                            backgroundColor: Colors.grey[200],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¥${amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('$percentage%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('所选时间段内没有支出记录'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
  }

  Widget _buildStatItem(String title, double amount, Color color) {
    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> expenseByCategory) {
    final totalExpense = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    
    expenseByCategory.forEach((category, amount) {
      final percentage = amount / totalExpense;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });
    
    return sections;
  }
}