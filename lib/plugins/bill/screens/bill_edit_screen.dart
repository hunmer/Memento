import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/bill.dart';

class BillEditScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final String accountId;
  final Bill? bill;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final DateTime? initialDate;

  // 预填充参数（用于快捷记账小组件）
  final String? initialCategory;
  final double? initialAmount;
  final bool? initialIsExpense;

  const BillEditScreen({
    super.key,
    required this.billPlugin,
    required this.accountId,
    this.bill,
    this.onSaved,
    this.onCancel,
    this.initialDate,
    this.initialCategory,
    this.initialAmount,
    this.initialIsExpense,
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
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;
  DateTime _selectedDate = DateTime.now();

  final List<String> _availableTags = <String>[
    '餐饮',
    '购物',
    '交通',
    '日用',
    '娱乐',
    '医疗',
    '教育',
    '住房',
    '工资',
    '奖金',
    '投资',
    '其他',
  ];

  final Map<String, IconData> _categoryIcons = {
    '餐饮': Icons.restaurant,
    '购物': Icons.shopping_bag,
    '交通': Icons.commute,
    '日用': Icons.local_mall,
    '娱乐': Icons.sports_esports,
    '医疗': Icons.local_hospital,
    '教育': Icons.school,
    '住房': Icons.home,
    '工资': Icons.attach_money,
    '奖金': Icons.card_giftcard,
    '投资': Icons.trending_up,
    '其他': Icons.more_horiz,
    '未分类': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();

    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    if (widget.bill != null) {
      _titleController.text = widget.bill!.title;
      _amountController.text = widget.bill!.absoluteAmount.toString();
      _noteController.text = widget.bill!.note;
      _tag = widget.bill!.tag ?? widget.bill!.category;
      _isExpense = widget.bill!.isExpense;
      _selectedIcon = widget.bill!.icon;
      _selectedColor = widget.bill!.iconColor;
      _selectedDate = widget.bill!.date;

      if (_tag != null && !_availableTags.contains(_tag)) {
        _availableTags.add(_tag!);
      }
    } else {
      // 使用预填充参数（来自快捷记账小组件）或默认值
      _tag = widget.initialCategory ?? _availableTags.first;
      _selectedIcon = _categoryIcons[_tag] ?? Icons.category;

      // 预填充金额
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }

      // 预填充收入/支出类型
      if (widget.initialIsExpense != null) {
        _isExpense = widget.initialIsExpense!;
      }

      // 确保分类在可用标签列表中
      if (_tag != null && !_availableTags.contains(_tag)) {
        _availableTags.add(_tag!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveBill() async {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.parse(_amountController.text);

        // Use category as title if title is empty
        final title =
            _titleController.text.isEmpty
                ? (_tag ?? '未分类')
                : _titleController.text;

        final bill = Bill(
          id:
              widget.bill?.id ??
              const Uuid().v4(),
          title: title,
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

        await widget.billPlugin.controller.saveBill(bill);

        if (!mounted) return;
        Toast.success('bill_billSaved'.tr);

        Navigator.of(context).pop();
        widget.onSaved?.call();
      } catch (e) {
        if (!mounted) return;
        Toast.error('${'bill_billSaveFailed'.tr}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Colors from the design
    final expenseColor = const Color(0xFFE74C3C);
    final incomeColor = const Color(0xFF2ECC71);
    final activeAmountColor = _isExpense ? expenseColor : incomeColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.bill == null ? '添加账单' : '编辑账单', // Could use l10n here if available
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type and Amount Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildTypeSelector(isDark),
                          const SizedBox(height: 24),
                          _buildAmountInput(activeAmountColor, isDark),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Category Selector Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '选择分类',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryList(primaryColor, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Details Section (Note & Date)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildNoteInput(isDark),
                          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                          _buildDateInput(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Save Button Area
          Container(
            padding: const EdgeInsets.all(16) + MediaQuery.of(context).padding.copyWith(top: 0),
            color: backgroundColor.withValues(alpha: 0.8),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'bill_save'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    final unselectedColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final selectedBgColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: unselectedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              label: 'bill_expense'.tr,
              isSelected: _isExpense,
              activeColor: const Color(0xFFE74C3C),
              bgOnSelected: selectedBgColor,
              onTap: () => setState(() => _isExpense = true),
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              label: 'bill_income'.tr,
              isSelected: !_isExpense,
              activeColor: const Color(0xFF2ECC71),
              bgOnSelected: selectedBgColor,
              onTap: () => setState(() => _isExpense = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color bgOnSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgOnSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(Color activeColor, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '¥',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: activeColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _amountController,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: activeColor,
              height: 1.2,
            ),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'bill_enterAmount'.tr;
              }
              if (double.tryParse(value) == null) {
                return 'bill_enterValidAmount'.tr;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableTags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final tag = _availableTags[index];
          final isSelected = tag == _tag;
          final icon = _categoryIcons[tag] ?? Icons.category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _tag = tag;
                _selectedIcon = icon;
                _titleController.text = ''; // Clear title so tag is used, or could set it to tag
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : (isDark ? Colors.grey[800] : Colors.grey[100]),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: Colors.grey[500], size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: '添加笔记...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput(bool isDark) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[500], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
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
}
