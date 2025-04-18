import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import '../models/bill.dart';
import 'package:flutter/services.dart';
import '../../../widgets/icon_picker_dialog.dart';

class BillEditScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Account account;
  final Bill? bill;

  const BillEditScreen({
    super.key,
    required this.billPlugin,
    required this.account,
    this.bill,
  });

  @override
  State<BillEditScreen> createState() => _BillEditScreenState();
}

class _BillEditScreenState extends State<BillEditScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _tag;
  bool _isExpense = true;
  IconData _selectedIcon = Icons.shopping_cart;

  final List<String> _availableTags = [
    '未分类',
    '食品',
    '交通',
    '住宿',
    '购物',
    '娱乐',
    '医疗',
    '教育',
    '工资',
    '奖金',
    '投资',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    if (widget.bill != null) {
      _titleController.text = widget.bill!.title;
      _amountController.text = widget.bill!.absoluteAmount.toString();
      _noteController.text = widget.bill!.note ?? '';
      _tag = widget.bill!.tag;
      _isExpense = widget.bill!.isExpense;
      _selectedIcon = widget.bill!.icon;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bill == null ? '添加账单' : '编辑账单')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconSelector(),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildTagSelector(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('支出'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('收入'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {_isExpense},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isExpense = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '标题',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入标题';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: '金额',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_yuan),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入金额';
        }
        if (double.tryParse(value) == null) {
          return '请输入有效的金额';
        }
        return null;
      },
    );
  }

  Widget _buildTagSelector() {
    return DropdownButtonFormField<String>(
      value: _tag,
      decoration: const InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(),
      ),
      items:
          _availableTags.map((String tag) {
            return DropdownMenuItem<String>(value: tag, child: Text(tag));
          }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _tag = newValue;
        });
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: '备注',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildIconSelector() {
    return GestureDetector(
      onTap: () async {
        final IconData? selectedIcon = await showDialog<IconData>(
          context: context,
          builder: (context) => IconPickerDialog(currentIcon: _selectedIcon),
        );
        if (selectedIcon != null) {
          setState(() {
            _selectedIcon = selectedIcon;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(
            alpha: 26, // 0.1 * 255 ≈ 26
            red: Theme.of(context).colorScheme.primary.r,
            green: Theme.of(context).colorScheme.primary.g,
            blue: Theme.of(context).colorScheme.primary.b,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedIcon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '点击选择图标',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final amount = double.parse(_amountController.text);
            final bill = Bill(
              id: widget.bill?.id,
              title: _titleController.text,
              amount: _isExpense ? -amount : amount,
              accountId: widget.account.id,
              tag: _tag,
              note:
                  _noteController.text.isNotEmpty ? _noteController.text : null,
              icon: _selectedIcon,
              createdAt: widget.bill?.createdAt,
            );

            try {
              // 创建账户的副本
              Account updatedAccount;

              if (widget.bill == null) {
                // 创建新账单
                updatedAccount = widget.account.copyWith(
                  bills: [...widget.account.bills, bill],
                );
              } else {
                // 更新现有账单
                updatedAccount = widget.account.copyWith(
                  bills:
                      widget.account.bills
                          .map(
                            (existingBill) =>
                                existingBill.id == bill.id
                                    ? bill
                                    : existingBill,
                          )
                          .toList(),
                );
              }
              // 调用插件的保存账户方法
              await widget.billPlugin.saveAccount(updatedAccount);

              if (!mounted) return;
              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('保存失败: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Text(widget.bill == null ? '添加' : '保存'),
      ),
    );
  }
}
