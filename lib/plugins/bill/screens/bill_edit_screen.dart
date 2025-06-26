import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import '../bill_plugin.dart';
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
  DateTime _selectedDate = DateTime.now();

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
      _noteController.text = widget.bill!.note;
      _tag = widget.bill!.tag ?? widget.bill!.category;
      _isExpense = widget.bill!.isExpense;
      _selectedIcon = widget.bill!.icon;
      _selectedColor = widget.bill!.iconColor;
      _selectedDate = widget.bill!.date;
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
            leading:
                widget.onCancel != null
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    )
                    : null,
            actions: [
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      // 解析金额
                      final amount = double.parse(_amountController.text);

                      // 创建账单对象
                      final bill = Bill(
                        id:
                            widget.bill?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        amount: _isExpense ? -amount : amount,
                        accountId: widget.accountId,
                        category: _tag ?? '未分类',
                        date: _selectedDate,
                        tag: _tag,
                        note: _noteController.text,
                        icon: _selectedIcon,
                        iconColor: _selectedColor,
                        createdAt: widget.bill?.createdAt ?? _selectedDate,
                      );

                      // 使用 controller 保存账单
                      await widget.billPlugin.controller.saveBill(bill);

                      // 显示成功提示
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            BillLocalizations.of(context)!.billSaved,
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // 返回上一页
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      widget.onSaved?.call();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${BillLocalizations.of(context)!.billSaveFailed}: $e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(widget.bill == null ? '添加' : '保存'),
              ),
            ],
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
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
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
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text(BillLocalizations.of(context)!.expense),
                icon: const Icon(Icons.arrow_upward),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(BillLocalizations.of(context)!.income),
                icon: const Icon(Icons.arrow_downward),
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
      decoration: InputDecoration(
        labelText: BillLocalizations.of(context).title,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return BillLocalizations.of(context).enterTitle;
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: BillLocalizations.of(context).amount,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.currency_yuan),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return BillLocalizations.of(context).enterAmount;
        }
        if (double.tryParse(value) == null) {
          return BillLocalizations.of(context).enterValidAmount;
        }
        return null;
      },
    );
  }

  Widget _buildTagSelector() {
    return DropdownButtonFormField<String>(
      value: _tag,
      decoration: InputDecoration(
        labelText: BillLocalizations.of(context).category,
        border: const OutlineInputBorder(),
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

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDateTimePicker(
          context: context,
          initialDate: _selectedDate,
        );
        if (picked != null && picked != _selectedDate && mounted) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: BillLocalizations.of(context).time,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} '
              '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: BillLocalizations.of(context).note,
        border: const OutlineInputBorder(),
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
}
