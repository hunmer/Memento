import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/bill.dart';
import '../models/account.dart';
import '../bill_plugin.dart';
import '../services/bill_service.dart';
import 'bill_edit_screen.dart';
import 'account_list_screen.dart';
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

class _BillListScreenState extends State<BillListScreen> with TickerProviderStateMixin {
  late final void Function() _billPluginListener;
  late final TabController _tabController;
  List<BillModel> _bills = [];
  bool _isLoading = true;
  bool _isEditing = false;
  BillModel? _selectedBill;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _billPluginListener = () {
      if (mounted) {
        _loadBills();
      }
    };
    widget.billPlugin.addListener(_billPluginListener);
    _loadBills();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // 如果正在编辑账单并切换到统计页面，先关闭编辑界面
      if (_isEditing && _tabController.index == 1) {
        setState(() {
          _isEditing = false;
          _selectedBill = null;
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
      final currentAccount = widget.billPlugin.accounts
          .firstWhere((account) => account.id == widget.accountId);

      // 从账户中获取账单并转换为BillModel
      final bills = currentAccount.bills
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
        tag: billModel.category,
        note: billModel.note,
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
    // 计算总收入和总支出
    double totalIncome = 0;
    double totalExpense = 0;

    final currentAccount = widget.billPlugin.accounts
        .firstWhere((account) => account.id == widget.accountId);
    for (var bill in currentAccount.bills) {
      if (bill.amount > 0) {
        totalIncome += bill.amount;
      } else {
        totalExpense += bill.amount.abs();
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bill.color,
          child: Icon(bill.icon, color: Colors.white),
        ),
        title: Text(bill.title),
        subtitle: Text(
          '${bill.category} · ${dateFormatter.format(bill.date)}${bill.note != null ? ' · ${bill.note}' : ''}',
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
    );
  }
}
