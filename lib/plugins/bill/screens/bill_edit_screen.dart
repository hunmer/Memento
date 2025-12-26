import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/models/bill.dart';
import 'package:Memento/plugins/bill/models/subscription.dart';
import 'package:Memento/widgets/form_fields/index.dart';

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
  // 表单 key
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  // FormBuilderWrapper 的状态引用
  FormBuilderWrapperState? _wrapperState;

  // 分类相关数据
  String? _tag;
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;
  DateTime _selectedDate = DateTime.now();

  // 订阅服务状态
  bool _isSubscriptionEnabled = false;

  // 可用的分类标签
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

  // 分类图标映射
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
    _initializeFormData();
  }

  /// 初始化表单数据
  void _initializeFormData() {
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    if (widget.bill != null) {
      _tag = widget.bill!.tag ?? widget.bill!.category;
      _selectedIcon = widget.bill!.icon;
      _selectedColor = widget.bill!.iconColor;
      _selectedDate = widget.bill!.date;

      if (_tag != null && !_availableTags.contains(_tag)) {
        _availableTags.add(_tag!);
      }

      _updateRouteContext(isEdit: true, billId: widget.bill!.id);
    } else {
      _tag = widget.initialCategory ?? _availableTags.first;
      _selectedIcon = _categoryIcons[_tag] ?? Icons.category;

      if (_tag != null && !_availableTags.contains(_tag)) {
        _availableTags.add(_tag!);
      }

      _updateRouteContext(isEdit: false);
    }
  }

  /// 更新路由上下文
  void _updateRouteContext({required bool isEdit, String? billId}) {
    if (isEdit && billId != null) {
      RouteHistoryManager.updateCurrentContext(
        pageId: '/bill_edit',
        title: '编辑账单',
        params: {'billId': billId},
      );
    } else {
      RouteHistoryManager.updateCurrentContext(
        pageId: '/bill_create',
        title: '新建账单',
        params: {},
      );
    }
  }

  /// 保存账单
  Future<void> _handleSave(Map<String, dynamic> values) async {
    try {
      final amount = (values['amount'] as num?)?.toDouble() ?? 0.0;
      final isExpense = values['isExpense'] as bool? ?? false;
      final isSubscription = values['isSubscription'] as bool?;

      // 验证金额必须大于0
      if (amount <= 0) {
        Toast.error('请输入有效金额（需大于0）');
        return;
      }

      if (isSubscription == true) {
        // 验证订阅服务字段
        final subscriptionName = values['subscriptionName'] as String?;
        final subscriptionDaysValue = values['subscriptionDays'];

        if (subscriptionName == null || subscriptionName.isEmpty) {
          Toast.error('请输入订阅服务名称');
          return;
        }

        if (subscriptionDaysValue == null) {
          Toast.error('请输入订阅天数');
          return;
        }

        final days = int.tryParse(subscriptionDaysValue.toString());
        if (days == null || days <= 0) {
          Toast.error('请输入有效的订阅天数');
          return;
        }

        // 保存为订阅服务
        final subscription = Subscription(
          name: subscriptionName,
          totalAmount: amount,
          days: days,
          category: _tag ?? '订阅',
          startDate: _selectedDate,
          note: values['note'] as String?,
          icon: _selectedIcon,
          iconColor: _selectedColor,
        );

        await widget.billPlugin.controller.subscriptions.createSubscription(subscription);

        if (!mounted) return;
        Toast.success('订阅服务创建成功');
      } else {
        // 保存为普通账单
        final title = values['title'] as String?;
        final finalTitle = (title == null || title.isEmpty)
            ? (_tag ?? '未分类')
            : title;

        final bill = Bill(
          id: widget.bill?.id ?? const Uuid().v4(),
          title: finalTitle,
          amount: isExpense ? -amount : amount,
          accountId: widget.accountId,
          category: _tag ?? '未分类',
          date: _selectedDate,
          tag: _tag,
          note: values['note'] as String? ?? '',
          icon: _selectedIcon,
          iconColor: _selectedColor,
          createdAt: widget.bill?.createdAt ?? _selectedDate,
        );

        await widget.billPlugin.controller.saveBill(bill);

        if (!mounted) return;
        Toast.success('bill_billSaved'.tr);
      }

      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      Toast.error('${'bill_billSaveFailed'.tr}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.colorScheme.surface;
    final cardColor = theme.colorScheme.surfaceContainerLow;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.bill == null ? '添加账单' : '编辑账单',
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
              child: FormBuilderWrapper(
                formKey: _formKey,
                onStateReady: (state) => _wrapperState = state,
                config: FormConfig(
                  fields: _buildFormFields(primaryColor),
                  showSubmitButton: false,
                  showResetButton: false,
                  onSubmit: _handleSave,
                  fieldSpacing: 0,
                ),
                contentBuilder: (context, fields) {
                  // 使用 contentBuilder 自定义布局
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      // 标题字段
                      FormFieldGroup(
                        showDividers: false,
                        showBackground: false,
                        children: [fields[2]], // title字段
                      ),
                      const SizedBox(height: 16),
                      
                      // 类型和金额卡片
                      _buildTypeAndAmountCard(fields, cardColor, primaryColor, isDark),
                      const SizedBox(height: 16),

                      // 分类选择卡片
                      _buildCategoryCard(fields, cardColor, primaryColor, isDark),
                      const SizedBox(height: 16),


                      // 日期和备注
                      _buildDateAndNoteSection(fields),
                      const SizedBox(height: 16),

                      // 订阅服务卡片
                      _buildSubscriptionCard(fields, cardColor, primaryColor, isDark),
                    ],
                  );
                },
              ),
            ),
          ),

          // 保存按钮区域
          _buildSaveButton(backgroundColor, primaryColor),
        ],
      ),
    );
  }

  /// 构建表单字段配置
  List<FormFieldConfig> _buildFormFields(Color primaryColor) {
    return [
      // 收支类型选择器（隐藏，用于状态管理）
      FormFieldConfig(
        name: 'isExpense',
        type: FormFieldType.expenseTypeSelector,
        initialValue: widget.bill != null
            ? widget.bill!.isExpense
            : (widget.initialIsExpense ?? true),
        extra: {
          'expenseColor': const Color(0xFFE74C3C),
          'incomeColor': const Color(0xFF2ECC71),
        },
      ),

      // 金额输入框（隐藏，用于状态管理）
      FormFieldConfig(
        name: 'amount',
        type: FormFieldType.amountInput,
        initialValue: widget.bill != null
            ? widget.bill!.absoluteAmount
            : widget.initialAmount,
        required: true,
        validationMessage: '请输入有效金额（需大于0）',
        extra: {
          'currencySymbol': '¥',
          'fontSize': 40.0,
        },
      ),

      // 标题
      FormFieldConfig(
        name: 'title',
        type: FormFieldType.text,
        initialValue: widget.bill?.title ?? '',
        labelText: '标题',
        hintText: '留空则使用分类名称',
      ),

      // 日期选择器
      FormFieldConfig(
        name: 'date',
        type: FormFieldType.date,
        initialValue: _selectedDate,
        extra: {
          'format': 'yyyy年MM月dd日',
          'inline': true,
        },
      ),

      // 备注
      FormFieldConfig(
        name: 'note',
        type: FormFieldType.textArea,
        initialValue: widget.bill?.note ?? '',
        hintText: '添加备注...',
        extra: {
          'minLines': 3,
          'maxLines': 5,
        },
      ),

      // 订阅服务开关
      FormFieldConfig(
        name: 'isSubscription',
        type: FormFieldType.switchField,
        initialValue: false,
        labelText: '启用订阅服务',
        hintText: '启用后将自动生成每日账单',
        prefixIcon: Icons.autorenew,
        onChanged: (value) {
          setState(() {
            _isSubscriptionEnabled = value as bool;
          });
        },
      ),

      // 订阅服务名称
      FormFieldConfig(
        name: 'subscriptionName',
        type: FormFieldType.text,
        labelText: '订阅服务名称',
        hintText: '例如：Netflix会员',
      ),

      // 订阅天数
      FormFieldConfig(
        name: 'subscriptionDays',
        type: FormFieldType.number,
        labelText: '订阅天数',
        hintText: '例如：30',
      ),
    ];
  }

  /// 构建类型和金额卡片
  Widget _buildTypeAndAmountCard(List<Widget> fields, Color cardColor, Color primaryColor, bool isDark) {
    // 获取类型选择器和金额输入框的字段
    final typeField = fields[0];
    final amountField = fields[1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          typeField,
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Expanded(child: amountField)],
          ),
        ],
      ),
    );
  }

  /// 构建分类选择卡片
  Widget _buildCategoryCard(List<Widget> fields, Color cardColor, Color primaryColor, bool isDark) {
    return Container(
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
          CategorySelectorField(
            categories: _availableTags,
            selectedCategory: _tag,
            categoryIcons: _categoryIcons,
            primaryColor: primaryColor,
            onCategoryChanged: (category) {
              setState(() {
                _tag = category;
                _selectedIcon = _categoryIcons[category] ?? Icons.category;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 构建日期和备注区域
  Widget _buildDateAndNoteSection(List<Widget> fields) {
    final dateField = fields[3];
    final noteField = fields[4];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldGroup(
          showDividers: true,
          children: [dateField],
        ),
        const SizedBox(height: 16),
        FormFieldGroup(
          showDividers: false,
          children: [
            // 备注标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '备注',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            noteField,
          ],
        ),
      ],
    );
  }

  /// 构建订阅服务卡片
  Widget _buildSubscriptionCard(List<Widget> fields, Color cardColor, Color primaryColor, bool isDark) {
    final switchField = fields[5];
    final nameField = fields[6];
    final daysField = fields[7];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '订阅服务',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          switchField,
          // 根据订阅服务状态显示额外字段
          if (_isSubscriptionEnabled) ...[
            const SizedBox(height: 16),
            nameField,
            const SizedBox(height: 16),
            daysField,
            _buildDailyAmountCalculation(cardColor, primaryColor, isDark),
          ],
        ],
      ),
    );
  }

  /// 构建单日金额计算显示
  Widget _buildDailyAmountCalculation(Color cardColor, Color primaryColor, bool isDark) {
    return Builder(
      builder: (context) {
        final formState = _formKey.currentState;
        final amountValue = formState?.value['amount'];
        final daysValue = formState?.value['subscriptionDays'];

        if (amountValue == null || daysValue == null) {
          return const SizedBox.shrink();
        }

        final amount = amountValue as double;
        final days = int.tryParse(daysValue.toString());

        if (days == null || days <= 0) {
          return const SizedBox.shrink();
        }

        return Card(
          color: primaryColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.calculate, color: primaryColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '单日金额',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '¥${(amount / days).toStringAsFixed(2)} / 天',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(Color backgroundColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16) + MediaQuery.of(context).padding.copyWith(top: 0),
      color: backgroundColor.withValues(alpha: 0.8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // 使用 wrapper 的提交方法，确保所有字段值正确收集
            _wrapperState?.submitForm();
          },
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
    );
  }
}
