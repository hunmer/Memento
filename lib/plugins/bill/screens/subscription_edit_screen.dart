import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/services/toast_service.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../models/subscription.dart';
import '../bill_plugin.dart';

class SubscriptionEditScreen extends StatefulWidget {
  final BillPlugin billPlugin;
  final Subscription? subscription;

  const SubscriptionEditScreen({
    super.key,
    required this.billPlugin,
    this.subscription,
  });

  @override
  State<SubscriptionEditScreen> createState() => _SubscriptionEditScreenState();
}

class _SubscriptionEditScreenState extends State<SubscriptionEditScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _daysController;
  late final TextEditingController _noteController;

  String _category = '订阅';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  IconData _selectedIcon = Icons.subscriptions;
  Color _selectedColor = Colors.blue;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController();
    _totalAmountController = TextEditingController();
    _daysController = TextEditingController();
    _noteController = TextEditingController();

    if (widget.subscription != null) {
      final sub = widget.subscription!;
      _nameController.text = sub.name;
      _totalAmountController.text = sub.totalAmount.toString();
      _daysController.text = sub.days.toString();
      _noteController.text = sub.note ?? '';
      _category = sub.category;
      _startDate = sub.startDate;
      _endDate = sub.endDate;
      _selectedIcon = sub.icon;
      _selectedColor = sub.iconColor;
      _isActive = sub.isActive;
    } else {
      // Defaults
      _daysController.text = '30'; // Default to Monthly
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _daysController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setCycle(int days) {
    setState(() {
      _daysController.text = days.toString();
      // Optional: Auto-calculate End Date if needed, 
      // but for now we follow the logic that days defines the cycle duration.
    });
  }

  Future<void> _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      try {
        final totalAmount = double.parse(_totalAmountController.text);
        final days = int.parse(_daysController.text);

        if (days <= 0) {
          Toast.error('Subscription days must be greater than 0');
          return;
        }

        final subscription = Subscription(
          id: widget.subscription?.id,
          name: _nameController.text,
          totalAmount: totalAmount,
          days: days,
          category: _category,
          startDate: _startDate,
          endDate: _endDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          icon: _selectedIcon,
          iconColor: _selectedColor,
          isActive: _isActive,
        );

        if (widget.subscription == null) {
          await widget.billPlugin.controller.subscriptions.createSubscription(subscription);
          Toast.success('Subscription created');
        } else {
          await widget.billPlugin.controller.subscriptions.updateSubscription(subscription);
          Toast.success('Subscription updated');
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        Toast.error('Save failed: $e');
      }
    }
  }

  Future<void> _deleteSubscription() async {
    if (widget.subscription == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: const Text('Are you sure you want to delete this subscription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.billPlugin.controller.subscriptions.deleteSubscription(widget.subscription!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine selected cycle for UI highlights
    final currentDays = int.tryParse(_daysController.text) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text(
          widget.subscription == null ? 'Add Subscription' : 'Edit Subscription',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveSubscription,
            child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Icon Picker
            Center(
              child: Column(
                children: [
                  CircleIconPicker(
                    currentIcon: _selectedIcon,
                    backgroundColor: _selectedColor,
                    onIconSelected: (icon) => setState(() => _selectedIcon = icon),
                    onColorSelected: (color) => setState(() => _selectedColor = color),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose Icon',
                    style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name & Price Group
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInputRow(
                    label: 'Name',
                    child: TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Netflix',
                        hintStyle: TextStyle(color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 17),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 0, color: Color(0xFFE5E5EA)),
                  _buildInputRow(
                    label: 'Price',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('¥ ', style: TextStyle(color: Colors.grey, fontSize: 17)),
                        Expanded(
                          child: TextFormField(
                            controller: _totalAmountController,
                            textAlign: TextAlign.end,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(color: Colors.grey),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 17),
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timing Group
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Start Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Start Date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                        Text(
                          DateFormat('yyyy-MM-dd').format(_startDate),
                          style: const TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                  ),
                  
                  // End Date (Optional)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate.add(Duration(days: currentDays > 0 ? currentDays : 30)),
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('End Date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                        Text(
                          _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'None',
                          style: const TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cycle Buttons
                  Row(
                    children: [
                      Expanded(child: _buildCycleButton('Monthly', 30, currentDays == 30)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCycleButton('Quarterly', 90, currentDays == 90)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCycleButton('Yearly', 365, currentDays >= 360)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Auto-subscribe
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-subscribe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text('Renew automatically when expired', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeColor: const Color(0xFF34C759),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add comments, order numbers, or account details...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delete Button
            if (widget.subscription != null)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _deleteSubscription,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Delete Subscription',
                    style: TextStyle(color: Colors.red, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCycleButton(String label, int days, bool isSelected) {
    return GestureDetector(
      onTap: () => _setCycle(days),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

