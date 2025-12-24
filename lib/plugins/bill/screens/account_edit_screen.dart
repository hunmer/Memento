import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/account.dart';
import 'package:Memento/widgets/picker/icon_picker_dialog.dart';
import 'package:Memento/widgets/form_fields/text_input_field.dart';

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
          title: Text('app_selectBackgroundColor'.tr),
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
              child: Text('app_ok'.tr),
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? '编辑账户' : '新建账户',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                  TextInputField(
                    controller: _titleController,
                    labelText: 'bill_accountName'.tr,
                    hintText: '例如: 现金, 银行卡',
                    primaryColor: _selectedColor,
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 32),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        'bill_deleteAccount'.tr,
                      ),
                      onPressed: _deleteAccount,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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
    );
  }

  void _saveAccount() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Toast.error('bill_enterAccountName'.tr);
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
          // 先关闭BottomSheet
          Navigator.pop(context);
          // 使用WidgetsBinding确保在下一帧执行导航,避免导航冲突
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                NavigationHelper.createRoute(widget.billPlugin.buildMainView(context)),
              );
            }
          });
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
            title: Text('app_confirmDelete'.tr),
            content: Text(
              'bill_confirmDeleteAccountWithBills'.tr,
            ),
            actions: [
              TextButton(
                child: Text('app_cancel'.tr),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('app_delete'.tr),
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
