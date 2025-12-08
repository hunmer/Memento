import 'dart:io' show Platform;
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/account.dart';
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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xCCF6F6F8), // Semi-transparent background
        elevation: 0,
        centerTitle: true,
        title: Text(
          BillLocalizations.of(context).accountManagement,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
      ),
      body: _buildAccountList(),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed:
              () => NavigationHelper.push(context, AccountEditScreen(billPlugin: widget.billPlugin),
              ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    if (widget.billPlugin.accounts.isEmpty) {
      return Center(child: Text(BillLocalizations.of(context).noAccounts));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.billPlugin.accounts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final account = widget.billPlugin.accounts[index];
        return Dismissible(
          key: Key(account.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
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
                  title: Text(BillLocalizations.of(context).confirmDelete),
                  content: Text(
                    '确定要删除账户"${account.title}"吗？\n删除后该账户下的所有账单记录都将被删除！',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(BillLocalizations.of(context).cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        '删除',
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
            Toast.success('${BillLocalizations.of(context).accountDeleted} "${account.title}"');
          },
          child: _buildAccountCard(context, account),
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openAccountBills(context, account),
          onLongPress: () => _editAccount(context, account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: account.backgroundColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    account.icon,
                    color: account.backgroundColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${account.bills.length} 笔账单',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '¥${account.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        account.totalAmount < 0
                            ? const Color(0xFFE74C3C)
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAccountBills(BuildContext context, Account account) {
    // 设置选中的账户
    widget.billPlugin.selectedAccount = account;
    // 返回到主视图并显示选中账户的账单
    NavigationHelper.pushReplacement(
      context,
      widget.billPlugin.buildMainView(context),
    );
  }

  void _editAccount(BuildContext context, Account account) {
    NavigationHelper.push(context, AccountEditScreen(
              billPlugin: widget.billPlugin,
              account: account,),
    );
  }
}
