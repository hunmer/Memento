import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import '../../../widgets/circle_icon_picker.dart';

class AccountEditScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Account? account;

  const AccountEditScreen({super.key, required this.billPlugin, this.account});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  late TextEditingController _titleController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.account?.title ?? '');
    _selectedIcon = widget.account?.icon ?? Icons.account_balance_wallet;
    _selectedColor = widget.account?.backgroundColor ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? '创建账户' : '编辑账户'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveAccount),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleIconPicker(
              currentIcon: _selectedIcon,
              backgroundColor: _selectedColor,
              onIconSelected: (icon) {
                setState(() {
                  _selectedIcon = icon;
                });
              },
              onColorSelected: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: BillLocalizations.of(context)!.accountName,
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.account != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: Text(BillLocalizations.of(context)!.deleteAccount),
                onPressed: _deleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveAccount() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BillLocalizations.of(context)!.enterAccountName),
        ),
      );
      return;
    }

    if (widget.account == null) {
      // 创建新账户
      final newAccount = Account(
        title: title,
        icon: _selectedIcon,
        backgroundColor: _selectedColor,
      );
      await widget.billPlugin.controller.createAccount(newAccount);

      if (mounted) {
        // 检查是否是第一个账户
        if (widget.billPlugin.accounts.length == 1) {
          // 如果是第一个账户，自动设置为选中账户并进入
          widget.billPlugin.selectedAccount = widget.billPlugin.accounts.first;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => widget.billPlugin.buildMainView(context),
            ),
          );
          return;
        }
        Navigator.pop(context);
      }
    } else {
      // 更新现有账户
      final updatedAccount = widget.account!.copyWith(
        title: title,
        icon: _selectedIcon,
        backgroundColor: _selectedColor,
      );
      await widget.billPlugin.controller.saveAccount(updatedAccount);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDelete),
            content: Text(
              BillLocalizations.of(context)!.confirmDeleteAccountWithBills,
            ),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.delete),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    await widget.billPlugin.controller.deleteAccount(widget.account!.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
