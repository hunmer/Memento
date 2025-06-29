import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import 'account_edit_screen.dart';

class AccountListScreen extends StatefulWidget {
  final BillPlugin billPlugin;

  const AccountListScreen({super.key, required this.billPlugin});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  @override
  void initState() {
    super.initState();
    widget.billPlugin.addListener(_onAccountsChanged);
  }

  @override
  void dispose() {
    widget.billPlugin.removeListener(_onAccountsChanged);
    super.dispose();
  }

  void _onAccountsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(BillLocalizations.of(context)!.accountManagement),
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
      ),
      body: _buildAccountList(),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AccountEditScreen(billPlugin: widget.billPlugin),
              ),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountList() {
    if (widget.billPlugin.accounts.isEmpty) {
      return Center(child: Text(BillLocalizations.of(context)!.noAccounts));
    }

    return ListView.builder(
      itemCount: widget.billPlugin.accounts.length,
      itemBuilder: (context, index) {
        final account = widget.billPlugin.accounts[index];
        return Dismissible(
          key: Key(account.id),
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(BillLocalizations.of(context)!.confirmDelete),
                  content: Text(
                    '确定要删除账户"${account.title}"吗？\n删除后该账户下的所有账单记录都将被删除！',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(BillLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        '',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            widget.billPlugin.controller.deleteAccount(account.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${BillLocalizations.of(context)!.accountDeleted} "${account.title}"',
                ),
              ),
            );
          },
          child: _buildAccountCard(context, account),
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
                child: Icon(account.icon, color: Colors.white),
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
    // 设置选中的账户
    widget.billPlugin.selectedAccount = account;
    // 返回到主视图并显示选中账户的账单
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => widget.billPlugin.buildMainView(context),
      ),
    );
  }

  void _editAccount(BuildContext context, Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AccountEditScreen(
              billPlugin: widget.billPlugin,
              account: account,
            ),
      ),
    );
  }
}
