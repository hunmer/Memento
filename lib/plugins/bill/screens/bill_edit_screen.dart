import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../bill_plugin.dart';
import '../models/account.dart';
import '../models/bill.dart';
import 'package:flutter/services.dart';
import '../../../widgets/circle_icon_picker.dart';

class BillEditScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;
  final Bill? bill;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const BillEditScreen({
    super.key,
    required this.billPlugin,
    required this.accountId,
    this.bill,
    this.onSaved,
    this.onCancel,
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
  Color _selectedColor = Colors.blue;

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
      _selectedColor = widget.bill!.iconColor;
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
    return Material(
      child: Column(
        children: [
        AppBar(
          title: Text(widget.bill == null ? '添加账单' : '编辑账单'),
          leading: widget.onCancel != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                )
              : null,
        ),
        Expanded(
          child: SingleChildScrollView(
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
        ),
        ],
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
              if (!mounted) return;
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
        if (!mounted) return;
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
    return CircleIconPicker(
      currentIcon: _selectedIcon,
      backgroundColor: _selectedColor,
      onIconSelected: (IconData icon) {
        if (!mounted) return;
        setState(() {
          _selectedIcon = icon;
        });
      },
      onColorSelected: (Color color) {
        if (!mounted) return;
        setState(() {
          _selectedColor = color;
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        minimumSize: const Size(200, 50),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          try {
            // 显示保存中提示
            if (!mounted) return;
            // 解析金额
            final amount = double.parse(_amountController.text);
            
            // 创建账单对象
            final bill = Bill(
              // 如果是编辑现有账单，使用原有ID；如果是新建账单，让构造函数生成新ID
              id: widget.bill?.id,
              title: _titleController.text,
              amount: _isExpense ? -amount : amount,
              accountId: widget.accountId,
              tag: _tag ?? '未分类',
              note: _noteController.text.isNotEmpty ? _noteController.text : null,
              icon: _selectedIcon,
              iconColor: _selectedColor,
              // 如果是编辑现有账单，保留原创建时间；如果是新建账单，使用当前时间
              createdAt: widget.bill?.createdAt,
            );
            
            // 获取当前账户的最新数据
            final currentAccount = widget.billPlugin.accounts.firstWhere(
              (a) => a.id == widget.accountId,
            );

            // 准备更新后的账户数据
            Account updatedAccount;
            if (widget.bill == null) {
              // 创建新账单
              updatedAccount = currentAccount.copyWith(
                bills: [...currentAccount.bills, bill],
              );
            } else {
              // 更新现有账单 - 替换相同ID的账单
              final updatedBills = currentAccount.bills.map((existingBill) {
                if (existingBill.id == bill.id) {
                  return bill;
                }
                return existingBill;
              }).toList();
              
              updatedAccount = currentAccount.copyWith(
                bills: updatedBills,
              );
            }
            
            // 更新账户总金额
            updatedAccount.calculateTotal();
            
            // 调用插件的保存账户方法
            await widget.billPlugin.saveAccount(updatedAccount);
            
            // 返回上一页
            if (!mounted) return;
            
            // 调用保存回调并返回
            Navigator.of(context).pop();
            widget.onSaved?.call();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Text(widget.bill == null ? '添加' : '保存'),
    );
  }
  }