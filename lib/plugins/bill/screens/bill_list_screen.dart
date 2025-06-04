import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/bill.dart';
import '../bill_plugin.dart';
import 'bill_edit_screen.dart';
import 'bill_stats_screen.dart';

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

class _BillListScreenState extends State<BillListScreen>
    with TickerProviderStateMixin {
  late final void Function() _billPluginListener;
  late final TabController _tabController;
  List<BillModel> _bills = [];
  bool _isLoading = true;
  bool _isEditing = false;
  // 移除未使用的字段
  String _selectedPeriod = '月';
  DateTime _startDate = DateTime.now();
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _billPluginListener = () {
      if (mounted) {
        debugPrint("BillPlugin 通知更新 - 重新加载账单");
        _loadBills();
      }
    };
    widget.billPlugin.addListener(_billPluginListener);
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
    _endDate = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
    );
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _updateDateRange();
    _loadBills();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // 如果正在编辑账单并切换到统计页面，先关闭编辑界面
      if (_isEditing && _tabController.index == 1) {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (mounted) {
      widget.billPlugin.removeListener(_billPluginListener);
      _tabController.removeListener(_handleTabChange);
      _tabController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBills() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前账户
      final currentAccount = widget.billPlugin.accounts.firstWhere(
        (account) => account.id == widget.accountId,
      );

      // 从账户中获取指定时间范围内的账单
      final filteredBills = currentAccount.bills.where(
        (bill) =>
            bill.createdAt.isAfter(_startDate) &&
            bill.createdAt.isBefore(_endDate.add(const Duration(seconds: 1))),
      );

      // 转换为BillModel
      final bills =
          filteredBills
              .map(
                (bill) => BillModel(
                  id: bill.id,
                  title: bill.title,
                  amount: bill.absoluteAmount,
                  date: bill.createdAt,
                  icon: bill.icon,
                  color: bill.iconColor,
                  category: bill.tag ?? '未分类',
                  note: bill.note,
                  isExpense: bill.isExpense,
                ),
              )
              .toList();

      // 按日期倒序排序，最新的账单显示在前面
      bills.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('加载账单失败: $e');
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BillEditScreen(
              billPlugin: widget.billPlugin,
              accountId: widget.accountId,
              bill: bill,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算选定时间范围内的总收入和总支出
    double totalIncome = 0;
    double totalExpense = 0;

    final currentAccount = widget.billPlugin.accounts.firstWhere(
      (account) => account.id == widget.accountId,
    );

    // 只统计选定时间范围内的账单
    for (var bill in currentAccount.bills) {
      // 检查账单是否在选定的时间范围内
      if (bill.createdAt.isAfter(_startDate) &&
          bill.createdAt.isBefore(_endDate.add(const Duration(seconds: 1)))) {
        if (bill.amount > 0) {
          totalIncome += bill.amount;
        } else {
          totalExpense += bill.amount.abs();
        }
      }
    }

    final balance = totalIncome - totalExpense;

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          // 账单列表页
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 时间段选择
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),

                  // 账单统计卡片
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '账单概览',
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
                                Icons.arrow_downward,
                              ),
                              _buildStatItem(
                                '支出',
                                totalExpense,
                                Colors.red,
                                Icons.arrow_upward,
                              ),
                              _buildStatItem(
                                '结余',
                                balance,
                                balance >= 0 ? Colors.blue : Colors.orange,
                                Icons.account_balance_wallet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 账单列表
                  Expanded(
                    child:
                        _bills.isEmpty
                            ? const Center(child: Text('暂无账单记录，点击右下角添加'))
                            : ListView.builder(
                              itemCount: _bills.length,
                              itemBuilder: (context, index) {
                                final bill = _bills[index];
                                return _buildBillItem(context, bill);
                              },
                            ),
                  ),
                ],
              ),

          // 统计分析页
          BillStatsScreen(
            billPlugin: widget.billPlugin,
            accountId: widget.accountId,
            startDate: _startDate,
            endDate: _endDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToBillEdit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 2);

    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBillItem(BuildContext context, BillModel bill) {
    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这条账单记录吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // 删除账单
        widget.billPlugin.deleteBill(widget.accountId, bill.id);

        // 更新UI
        setState(() {
          _bills.removeWhere((b) => b.id == bill.id);
        });

        // 显示删除成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('账单已删除'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: Icon(bill.icon, color: bill.color),
          title: Text(bill.title),
          subtitle: Text(
            '${bill.category} · ${dateFormatter.format(bill.date)}${(bill.note?.isNotEmpty ?? false) ? ' · ${bill.note}' : ''}',
          ),
          trailing: Text(
            formatter.format(bill.amount),
            style: TextStyle(
              color: bill.isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => _navigateToBillEdit(context, bill),
        ),
      ),
    );
  }
}
