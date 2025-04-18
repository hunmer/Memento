import 'package:flutter/material.dart';
import '../models/bill.dart';
import 'bill_edit_screen.dart';
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
                const PopupMenuItem(
                  value: StatisticRange.week,
                  child: Text('本周'),
                ),
                const PopupMenuItem(
                  value: StatisticRange.month,
                  child: Text('本月'),
                ),
                const PopupMenuItem(
                  value: StatisticRange.year,
                  child: Text('本年'),
                ),
                const PopupMenuItem(
                  value: StatisticRange.all,
                  child: Text('全部'),
                ),
                const PopupMenuItem(
                  value: StatisticRange.custom,
                  child: Text('自定义'),
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

  @override
  void initState() {
    super.initState();
    widget.billPlugin.addListener(_handlePluginUpdate);
  }

  @override
  void dispose() {
    widget.billPlugin.removeListener(_handlePluginUpdate);
    super.dispose();
  }

  void _handlePluginUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody() {
    return StatefulBuilder(
      builder: (context, setState) {
        final statistics = widget.billPlugin.getStatistics(
          bills: widget.account.bills,
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
            Expanded(
              child: _buildBillsList(widget.account.bills),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillsList(List<Bill> bills) {
    if (bills.isEmpty) {
      return const Center(
        child: Text('暂无账单记录'),
      );
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
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条账单记录吗？'),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('删除'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await widget.billPlugin.deleteBill(widget.account.id, bill.id);
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        // 空实现，因为删除操作已在confirmDismiss中完成
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.account.backgroundColor.withAlpha(51), // 0.2 * 255 ≈ 51
          child: Icon(
            bill.icon,
            color: widget.account.backgroundColor,
          ),
        ),
        title: Text(bill.title),
        subtitle: bill.tag != null
            ? Text(bill.tag!)
            : null,
        trailing: Text(
          '${isExpense ? '-' : '+'}¥${bill.absoluteAmount.toStringAsFixed(2)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _editBill(context, bill),
      ),
    );
  }

  void _createBill(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillEditScreen(
          billPlugin: widget.billPlugin,
          account: widget.account,
        ),
      ),
    );
  }

  void _editBill(BuildContext context, Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillEditScreen(
          billPlugin: widget.billPlugin,
          account: widget.account,
          bill: bill,
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(
              start: _customStartDate!,
              end: _customEndDate!,
            )
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