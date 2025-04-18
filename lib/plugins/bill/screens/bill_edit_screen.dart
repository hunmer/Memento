import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import '../models/bill.dart';
import 'package:flutter/services.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _tag;
  bool _isExpense = true;
  IconData _selectedIcon = Icons.shopping_cart;

  final List<IconData> _availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.directions_bus,
    Icons.home,
    Icons.school,
    Icons.local_hospital,
    Icons.sports_basketball,
    Icons.movie,
    Icons.shopping_bag,
    Icons.attach_money,
    Icons.card_giftcard,
    Icons.work,
    Icons.flight,
    Icons.hotel,
  ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildTagSelector(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 16),
              _buildIconSelector(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择图标'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _availableIcons.map((IconData icon) {
                final isSelected = _selectedIcon.codePoint == icon.codePoint;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveBill,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.bill == null ? '添加' : '保存',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _saveBill() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amountText = _amountController.text;
      final note = _noteController.text.isEmpty ? null : _noteController.text;

      double amount = double.parse(amountText);
      if (_isExpense) {
        amount = -amount; // 支出为负数
      }

      try {
        if (widget.bill == null) {
          // 创建新账单
          final newBill = Bill(
            title: title,
            amount: amount,
            accountId: widget.account.id,
            tag: _tag,
            note: note,
            icon: _selectedIcon,
          );

          // 更新账户中的账单列表
          final updatedBills = [...widget.account.bills, newBill];
          final updatedAccount = widget.account.copyWith(bills: updatedBills);
          await widget.billPlugin.saveAccount(updatedAccount);
        } else {
          // 更新现有账单
          final updatedBill = widget.bill!.copyWith(
            title: title,
            amount: amount,
            tag: _tag,
            note: note,
            icon: _selectedIcon,
          );

          // 更新账户中的账单列表
          final updatedBills =
              widget.account.bills.map((bill) {
                return bill.id == updatedBill.id ? updatedBill : bill;
              }).toList();

          final updatedAccount = widget.account.copyWith(bills: updatedBills);
          await widget.billPlugin.saveAccount(updatedAccount);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
