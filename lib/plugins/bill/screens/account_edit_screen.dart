import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/account.dart';
import 'package:Memento/widgets/icon_picker_dialog.dart';

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

  Future<void> _pickIcon() async {
    final IconData? result = await showIconPickerDialog(context, _selectedIcon);
    if (result != null) {
      setState(() {
        _selectedIcon = result;
      });
    }
  }

  Future<void> _pickColor() async {
    Color newColor = _selectedColor;
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectBackgroundColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) => newColor = color,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop(newColor);
              },
            ),
          ],
        );
      },
    );
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEdit ? '编辑账户' : '新建账户',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Icon Display
                    GestureDetector(
                      onTap: _pickIcon,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          _selectedIcon,
                          size: 48,
                          color: _selectedColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Icon & Color Selection Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _pickIcon,
                          child: Text(
                            '选择图标',
                            style: TextStyle(
                              color: _selectedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickColor,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedColor,
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Input Field
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              BillLocalizations.of(context).accountName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextField(
                            controller: _titleController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: '例如: 现金, 银行卡',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _selectedColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 32),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          BillLocalizations.of(context).deleteAccount,
                        ),
                        onPressed: _deleteAccount,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 4,
                    shadowColor: _selectedColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    isEdit ? '保存' : '创建',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAccount() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Toast.error(BillLocalizations.of(context).enterAccountName);
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
            NavigationHelper.createRoute(widget.billPlugin.buildMainView(context)),
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
              BillLocalizations.of(context).confirmDeleteAccountWithBills,
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
