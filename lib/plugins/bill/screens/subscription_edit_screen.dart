import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:Memento/widgets/form_fields/index.dart';
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

      // 设置编辑模式的路由上下文
      _updateRouteContext(isEdit: true, subscriptionId: sub.id);
    } else {
      // Defaults
      _daysController.text = '30'; // Default to Monthly

      // 设置新建模式的路由上下文
      _updateRouteContext(isEdit: false);
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

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前状态
  void _updateRouteContext({required bool isEdit, String? subscriptionId}) {
    if (isEdit && subscriptionId != null) {
      RouteHistoryManager.updateCurrentContext(
        pageId: '/bill_subscription_edit',
        title: '编辑订阅',
        params: {'subscriptionId': subscriptionId},
      );
    } else {
      RouteHistoryManager.updateCurrentContext(
        pageId: '/bill_subscription_create',
        title: '新建订阅',
        params: {},
      );
    }
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
          Toast.error('bill_subscriptionDaysError'.tr);
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
          Toast.success('bill_subscriptionCreated'.tr);
        } else {
          await widget.billPlugin.controller.subscriptions.updateSubscription(subscription);
          Toast.success('bill_subscriptionUpdated'.tr);
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        Toast.error('bill_saveFailed'.tr);
      }
    }
  }

  Future<void> _deleteSubscription() async {
    if (widget.subscription == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('bill_deleteSubscription'.tr),
        content: Text('bill_deleteConfirm'.tr.replaceAll('{name}', widget.subscription!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('bill_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('bill_delete'.tr),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
            ),
            child: Text('bill_cancel'.tr, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          widget.subscription == null ? 'bill_addSubscription'.tr : 'bill_editSubscription'.tr,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _saveSubscription,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: Text('bill_save'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
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
                  Text(
                    'bill_chooseIcon'.tr,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name & Price Group
            FormFieldGroup(
              children: [
                TextInputField(
                  controller: _nameController,
                  labelText: 'bill_subscriptionName'.tr,
                  hintText: 'Netflix',
                  inline: true,
                  validator:
                      (v) =>
                          v?.isEmpty == true ? 'bill_requiredField'.tr : null,
                ),
                TextInputField(
                  controller: _totalAmountController,
                  labelText: 'bill_subscriptionPrice'.tr,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  inline: true,
                  validator:
                      (v) =>
                          v?.isEmpty == true ? 'bill_requiredField'.tr : null,
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '¥',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Timing Group
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Start & End Date
                  FormFieldGroup(
                    showDividers: true,
                    children: [
                      DatePickerField(
                        date: _startDate,
                        formattedDate: DateFormat(
                          'yyyy-MM-dd',
                        ).format(_startDate),
                        placeholder: '',
                        labelText: 'bill_startDate'.tr,
                        inline: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _startDate = picked);
                        },
                      ),
                      DatePickerField(
                        date: _endDate,
                        formattedDate:
                            _endDate != null
                                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                : '',
                        placeholder: 'bill_none'.tr,
                        labelText: 'bill_endDate'.tr,
                        inline: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ??
                                _startDate.add(
                                  Duration(
                                    days: currentDays > 0 ? currentDays : 30,
                                  ),
                                ),
                            firstDate: _startDate,
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cycle Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCycleButton(
                            'bill_monthly'.tr,
                            30,
                            currentDays == 30,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCycleButton(
                            'bill_quarterly'.tr,
                            90,
                            currentDays == 90,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCycleButton(
                            'bill_yearly'.tr,
                            365,
                            currentDays >= 360,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Auto-subscribe
            FormFieldGroup(
              showDividers: false,
              children: [
                SwitchField(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  title: 'bill_autoSubscribe'.tr,
                  subtitle: 'bill_autoSubscribeDesc'.tr,
                  inline: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            FormFieldGroup(
              showDividers: false,
              children: [
                TextAreaField(
                  controller: _noteController,
                  labelText: 'bill_notes'.tr,
                  hintText: 'bill_notesHint'.tr,
                  maxLines: 4,
                  inline: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Delete Button
            if (widget.subscription != null)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _deleteSubscription,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'bill_deleteSubscription'.tr,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleButton(String label, int days, bool isSelected) {
    return GestureDetector(
      onTap: () => _setCycle(days),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
            : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

