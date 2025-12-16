import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../bill_plugin.dart';
import 'package:Memento/plugins/bill/controls/subscription_controller.dart';

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

  /// 计算出的单日金额
  double? _calculatedDailyAmount;

  /// 标记用户是否手动修改过结束日期
  bool _endDateManuallyChanged = false;

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

      // 如果有结束日期，标记为手动修改过（避免覆盖用户可能设置的日期）
      if (sub.endDate != null) {
        _endDateManuallyChanged = true;
      }

      // 初始化时计算一次值
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateValues();
      });
    } else {
      // 新建订阅时，结束日期是自动计算的
      _endDateManuallyChanged = false;

      // 新建订阅时，也计算一次（可能默认值已有）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateValues();
      });
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

  void _calculateValues() {
    final totalAmount = double.tryParse(_totalAmountController.text);
    final days = int.tryParse(_daysController.text);

    setState(() {
      if (totalAmount != null && days != null && days > 0) {
        _calculatedDailyAmount = totalAmount / days;

        // 自动计算结束日期
        // 只有在用户没有手动修改过结束日期时才重新计算
        if (!_endDateManuallyChanged) {
          _endDate = _startDate.add(Duration(days: days - 1));
        }
      } else {
        _calculatedDailyAmount = null;
      }
    });
  }

  Future<void> _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      try {
        final totalAmount = double.parse(_totalAmountController.text);
        final days = int.parse(_daysController.text);

        if (days <= 0) {
          Toast.error('订阅天数必须大于0');
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
        );

        if (widget.subscription == null) {
          await widget.billPlugin.controller.subscriptions.createSubscription(subscription);
          Toast.success('订阅服务创建成功');
        } else {
          await widget.billPlugin.controller.subscriptions.updateSubscription(subscription);
          Toast.success('订阅服务更新成功');
        }

        Navigator.of(context).pop();
      } catch (e) {
        Toast.error('保存失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscription == null ? '新建订阅' : '编辑订阅'),
        actions: [
          TextButton(
            onPressed: _saveSubscription,
            child: Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // 服务名称
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '服务名称 *',
                hintText: '例如：Netflix会员、Spotify等',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务名称';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // 总金额
            TextFormField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '总金额 *',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              onChanged: (value) => _calculateValues(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入总金额';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效金额';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // 订阅天数
            TextFormField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '订阅天数 *',
                hintText: '例如：30（一个月）',
                border: OutlineInputBorder(),
                suffixText: '天',
              ),
              onChanged: (value) => _calculateValues(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入订阅天数';
                }
                final days = int.tryParse(value);
                if (days == null || days <= 0) {
                  return '请输入有效天数';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // 单日金额显示（自动计算）
            if (_calculatedDailyAmount != null)
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, color: Colors.blue),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '单日金额',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '¥${_calculatedDailyAmount!.toStringAsFixed(2)} / 天',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // 开始日期
            ListTile(
              title: Text('开始日期'),
              subtitle: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    // 开始日期改变时，重置结束日期的手动修改标记
                    _endDateManuallyChanged = false;
                  });
                  // 重新计算值（特别是结束日期）
                  _calculateValues();
                }
              },
            ),
            SizedBox(height: 8),

            // 结束日期（可选）
            ListTile(
              title: Text('结束日期（可选）'),
              subtitle: Text(
                _endDate != null
                    ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                    : '不限制',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _endDateManuallyChanged = true; // 标记用户手动修改过
                  });
                }
              },
            ),

            // 如果结束日期是自动计算的，显示提示
            if (_endDate != null && !_endDateManuallyChanged && _daysController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '根据开始日期和订阅天数自动计算',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SizedBox(height: 16),

            // 分类
            TextFormField(
              decoration: InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              initialValue: _category,
              onChanged: (value) => _category = value,
            ),
            SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saveSubscription,
                icon: Icon(Icons.save),
                label: Text('保存订阅服务', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
