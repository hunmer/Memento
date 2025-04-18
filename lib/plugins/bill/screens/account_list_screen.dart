import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import 'account_bills_screen.dart';
import 'account_edit_screen.dart';

class AccountListScreen extends StatelessWidget {
  final BillPlugin billPlugin;

  const AccountListScreen({
    Key? key,
    required this.billPlugin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户管理'),
      ),
      body: _buildAccountList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createAccount(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountList() {
    return StatefulBuilder(
      builder: (context, setState) {
        billPlugin.addListener(() => setState(() {}));

        if (billPlugin.accounts.isEmpty) {
          return const Center(
            child: Text('暂无账户，点击右下角按钮创建'),
          );
        }

        return ListView.builder(
          itemCount: billPlugin.accounts.length,
          itemBuilder: (context, index) {
            final account = billPlugin.accounts[index];
            return _buildAccountCard(context, account);
          },
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _openAccountBills(context, account),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: account.backgroundColor,
                child: Icon(
                  account.icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总金额: ¥${account.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editAccount(context, account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAccountBills(BuildContext context, Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountBillsScreen(
          billPlugin: billPlugin,
          account: account,
        ),
      ),
    );
  }

  void _createAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountEditScreen(
          billPlugin: billPlugin,
        ),
      ),
    );
  }

  void _editAccount(BuildContext context, Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountEditScreen(
          billPlugin: billPlugin,
          account: account,
        ),
      ),
    );
  }
}