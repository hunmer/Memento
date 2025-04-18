import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/bill.dart';
import '../models/account.dart';
import '../bill_plugin.dart';
import '../services/bill_service.dart';
import 'bill_edit_screen.dart';

class BillListScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Account account;

  const BillListScreen({
    super.key,
    required this.billPlugin,
    required this.account,
  });

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  List<BillModel> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }
  
  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
    });

    // 从账户中获取账单并转换为BillModel
    final bills = widget.account.bills.map((bill) => BillModel(
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

  Future<void> _navigateToBillEdit(BuildContext context, [BillModel? billModel]) async {
    Bill? bill;
    if (billModel != null) {
      bill = Bill(
        id: billModel.id,
        title: billModel.title,
        amount: billModel.isExpense ? -billModel.amount : billModel.amount,
        accountId: widget.account.id,
        tag: billModel.category,
        note: billModel.note,
        createdAt: billModel.date,
        icon: billModel.icon,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillEditScreen(
          billPlugin: widget.billPlugin,
          account: widget.account,
          bill: bill,
        ),
      ),
    );
    
    if (result == true) {
      _loadBills();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 计算总收入和总支出
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var bill in widget.account.bills) {
      if (bill.amount > 0) {
        totalIncome += bill.amount;
      } else {
        totalExpense += bill.amount.abs();
      }
    }
    
    final balance = totalIncome - totalExpense;
    
    return Scaffold(
      body: _isLoading
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
                  child: _bills.isEmpty
                      ? const Center(
                          child: Text('暂无账单记录，点击右下角添加'),
                        )
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToBillEdit(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildStatItem(String title, double amount, Color color, IconData icon) {
    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
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
          ),
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