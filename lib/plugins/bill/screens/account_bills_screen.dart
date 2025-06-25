import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import '../models/bill.dart';
import 'bill_edit_screen.dart' as bill_edit;
import '../bill_plugin.dart';
import '../models/account.dart';
import '../models/statistic_range.dart';
import '../widgets/bill_statistics_card.dart';

class AccountBillsScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Account account;

  const AccountBillsScreen({
    super.key,
    required this.billPlugin,
    required this.account,
  });

  @override
  State<AccountBillsScreen> createState() => _AccountBillsScreenState();
}

class _AccountBillsScreenState extends State<AccountBillsScreen> {
  StatisticRange _selectedRange = StatisticRange.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.title),
        actions: [
          PopupMenuButton<StatisticRange>(
            icon: const Icon(Icons.filter_list),
            onSelected: (StatisticRange range) {
              setState(() {
                _selectedRange = range;
                if (range != StatisticRange.custom) {
                  _customStartDate = null;
                  _customEndDate = null;
                } else {
                  _showDateRangePicker();
                }
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: StatisticRange.week,
                  child: Text(BillLocalizations.of(context)!.thisWeek),
                ),
                PopupMenuItem(
                  value: StatisticRange.month,
                  child: Text(BillLocalizations.of(context)!.thisMonth),
                ),
                PopupMenuItem(
                  value: StatisticRange.year,
                  child: Text(BillLocalizations.of(context)!.thisYear),
                ),
                PopupMenuItem(
                  value: StatisticRange.all,
                  child: Text(BillLocalizations.of(context)!.all),
                ),
                PopupMenuItem(
                  value: StatisticRange.custom,
                  child: Text(BillLocalizations.of(context)!.custom),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createBill(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 添加一个账户引用来存储最新的账户数据
  late Account _currentAccount;

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
    widget.billPlugin.addListener(_handlePluginUpdate);
  }

  @override
  void dispose() {
    widget.billPlugin.removeListener(_handlePluginUpdate);
    super.dispose();
  }

  // 刷新账户数据
  void _refreshAccountData() {
    if (!mounted) return;

    // 从插件中获取最新的账户数据
    final updatedAccount = widget.billPlugin.accounts.firstWhere(
      (account) => account.id == widget.account.id,
      orElse: () => widget.account,
    );

    setState(() {
      _currentAccount = updatedAccount;
    });
  }

  void _handlePluginUpdate() {
    if (mounted) {
      _refreshAccountData();
    }
  }

  Widget _buildBody() {
    final statistics = widget.billPlugin.controller.getStatistics(
      bills: _currentAccount.bills,
      range: _selectedRange,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );

    return Column(
      children: [
        BillStatisticsCard(
          totalIncome: statistics.totalIncome,
          totalExpense: statistics.totalExpense,
          balance: statistics.balance,
        ),
        Expanded(child: _buildBillsList(_currentAccount.bills)),
      ],
    );
  }

  Widget _buildBillsList(List<Bill> bills) {
    if (bills.isEmpty) {
      return Center(child: Text(BillLocalizations.of(context)!.noBillsYet));
    }

    // 对账单按日期排序
    final sortedBills = List<Bill>.from(bills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      itemCount: sortedBills.length,
      itemBuilder: (context, index) {
        final bill = sortedBills[index];
        return _buildBillItem(bill);
      },
    );
  }

  Widget _buildBillItem(Bill bill) {
    final isExpense = bill.amount < 0;
    final amountColor = isExpense ? Colors.red : Colors.green;

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(BillLocalizations.of(context)!.confirmDelete),
                content: Text(
                  BillLocalizations.of(context)!.deleteBillConfirmation,
                ),
                actions: [
                  TextButton(
                    child: Text(BillLocalizations.of(context)!.cancel),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: Text(BillLocalizations.of(context)!.delete),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
        );
        if (confirmed == true) {
          await widget.billPlugin.controller.deleteBill(
            widget.account.id,
            bill.id,
          );
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        // 空实现，因为删除操作已在confirmDismiss中完成
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.account.backgroundColor.withAlpha(
            51,
          ), // 0.2 * 255 ≈ 51
          child: Icon(bill.icon, color: widget.account.backgroundColor),
        ),
        title: Text(bill.title),
        subtitle: bill.tag != null ? Text(bill.tag!) : null,
        trailing: Text(
          '${isExpense ? '-' : '+'}¥${bill.absoluteAmount.toStringAsFixed(2)}',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
        onTap: () => _editBill(context, bill),
      ),
    );
  }

  void _createBill(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => bill_edit.BillEditScreen(
              billPlugin: widget.billPlugin,
              accountId: _currentAccount.id,
              onSaved: () {
                // 强制更新列表
                _refreshAccountData();
              },
            ),
      ),
    );
  }

  void _editBill(BuildContext context, Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => bill_edit.BillEditScreen(
              billPlugin: widget.billPlugin,
              accountId: _currentAccount.id,
              bill: bill,
              onSaved: () {
                // 强制更新列表
                _refreshAccountData();
              },
            ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange:
          _customStartDate != null && _customEndDate != null
              ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
              : null,
    );

    if (picked != null && mounted) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }
}
