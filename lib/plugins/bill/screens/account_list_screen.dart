import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/route/route_history_manager.dart';
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

    // 设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能识别当前页面
  void _updateRouteContext() {
    RouteHistoryManager.updateCurrentContext(
      pageId: '/bill_accounts',
      title: '账户管理',
      params: {},
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'bill_accountManagement'.tr,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(context).colorScheme.onSurface,
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
          child: Icon(
            Icons.add,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    if (widget.billPlugin.accounts.isEmpty) {
      return Center(child: Text('bill_noAccounts'.tr));
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
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('bill_confirmDelete'.tr),
                  content: Text(
                    '确定要删除账户"${account.title}"吗？\n删除后该账户下的所有账单记录都将被删除！',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('bill_cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            widget.billPlugin.controller.deleteAccount(account.id);
            Toast.success('${'bill_accountDeleted'.tr} "${account.title}"');
          },
          child: _buildAccountCard(context, account),
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${account.bills.length} 笔账单',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                            : Theme.of(context).colorScheme.onSurface,
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
