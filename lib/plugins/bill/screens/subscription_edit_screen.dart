import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
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
  @override
  void initState() {
    super.initState();

    // 设置路由上下文
    if (widget.subscription != null) {
      _updateRouteContext(isEdit: true, subscriptionId: widget.subscription!.id);
    } else {
      _updateRouteContext(isEdit: false);
    }
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

  Future<void> _saveSubscription(Map<String, dynamic> values) async {
    try {
      // 从表单值中提取数据
      final iconData = values['iconData'] as Map<String, dynamic>?;
      final icon = iconData?['icon'] as IconData? ?? Icons.subscriptions;
      final iconColor = iconData?['color'] as Color? ?? Colors.blue;

      final subscription = Subscription(
        id: widget.subscription?.id,
        name: values['name'] as String,
        totalAmount: double.parse(values['totalAmount'].toString()),
        days: values['days'] as int,
        category: '订阅',
        startDate: values['startDate'] as DateTime,
        endDate: values['endDate'] as DateTime?,
        note: (values['note'] as String?)?.isEmpty == true ? null : values['note'] as String?,
        icon: icon,
        iconColor: iconColor,
        isActive: values['isActive'] as bool,
      );

      // 验证天数
      if (subscription.days <= 0) {
        Toast.error('bill_subscriptionDaysError'.tr);
        return;
      }

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
    final sub = widget.subscription;

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
          sub == null ? 'bill_addSubscription'.tr : 'bill_editSubscription'.tr,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: FormBuilderWrapper(
        buttonBuilder: (context, onSubmit, onReset) {
          // 自定义按钮区域：保存按钮在 AppBar，底部显示删除按钮
          return Column(
            children: [
              if (widget.subscription != null) ...[
                const SizedBox(height: 24),
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
              ],
              const SizedBox(height: 32),
            ],
          );
        },
        contentBuilder: (context, fields) {
          // 自定义布局：保存按钮在 AppBar
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 图标选择器（居中）
              fields[0],
              const SizedBox(height: 24),

              // 名称和价格组
              FormFieldGroup(
                children: [
                  fields[1], // 名称
                  fields[2], // 价格
                ],
              ),
              const SizedBox(height: 24),

              // 时间组
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 开始和结束日期
                    FormFieldGroup(
                      showDividers: true,
                      children: [
                        fields[3], // 开始日期
                        fields[4], // 结束日期
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 周期按钮
                    fields[5], // 订阅周期
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 自动订阅开关
              FormFieldGroup(
                showDividers: false,
                children: [
                  fields[6], // isActive
                ],
              ),
              const SizedBox(height: 24),

              // 备注
              FormFieldGroup(
                showDividers: false,
                children: [
                  fields[7], // 备注
                ],
              ),

              // 自定义按钮区域（删除按钮）
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextButton(
                      onPressed: () {
                        // 触发表单提交
                        final wrapper = context.findAncestorStateOfType<FormBuilderWrapperState>();
                        wrapper?.submitForm();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('bill_save'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        config: FormConfig(
          showSubmitButton: false, // 不显示默认提交按钮
          fieldSpacing: 0, // 使用自定义间距
          fields: [
            // 图标和颜色选择器
            FormFieldConfig(
              name: 'iconData',
              type: FormFieldType.circleIconPicker,
              initialValue: {
                'icon': sub?.icon ?? Icons.subscriptions,
                'color': sub?.iconColor ?? Colors.blue,
              },
              extra: {
                'showLabel': true,
                'labelText': 'bill_chooseIcon'.tr,
              },
            ),

            // 名称
            FormFieldConfig(
              name: 'name',
              type: FormFieldType.text,
              labelText: 'bill_subscriptionName'.tr,
              hintText: 'Netflix',
              initialValue: sub?.name ?? '',
              required: true,
              validationMessage: 'bill_requiredField'.tr,
              extra: {'inline': true},
            ),

            // 价格
            FormFieldConfig(
              name: 'totalAmount',
              type: FormFieldType.number,
              labelText: 'bill_subscriptionPrice'.tr,
              hintText: '0.00',
              initialValue: sub?.totalAmount ?? 0.0,
              required: true,
              validationMessage: 'bill_requiredField'.tr,
              extra: {
                'inline': true,
                'suffix': '¥',
              },
            ),

            // 开始日期
            FormFieldConfig(
              name: 'startDate',
              type: FormFieldType.date,
              labelText: 'bill_startDate'.tr,
              initialValue: sub?.startDate ?? DateTime.now(),
              extra: {
                'inline': true,
                'format': 'yyyy-MM-dd',
                'firstDate': DateTime(2000),
                'lastDate': DateTime(2100),
              },
            ),

            // 结束日期
            FormFieldConfig(
              name: 'endDate',
              type: FormFieldType.date,
              labelText: 'bill_endDate'.tr,
              hintText: 'bill_none'.tr,
              initialValue: sub?.endDate,
              extra: {
                'inline': true,
                'format': 'yyyy-MM-dd',
                'firstDate': sub?.startDate ?? DateTime.now(),
                'lastDate': DateTime(2100),
              },
            ),

            // 订阅周期
            FormFieldConfig(
              name: 'days',
              type: FormFieldType.subscriptionCycle,
              initialValue: sub?.days ?? 30,
              extra: {
                'monthlyLabel': 'bill_monthly'.tr,
                'quarterlyLabel': 'bill_quarterly'.tr,
                'yearlyLabel': 'bill_yearly'.tr,
              },
            ),

            // 自动订阅开关
            FormFieldConfig(
              name: 'isActive',
              type: FormFieldType.switchField,
              labelText: 'bill_autoSubscribe'.tr,
              hintText: 'bill_autoSubscribeDesc'.tr,
              initialValue: sub?.isActive ?? true,
              extra: {'inline': true},
            ),

            // 备注
            FormFieldConfig(
              name: 'note',
              type: FormFieldType.textArea,
              labelText: 'bill_notes'.tr,
              hintText: 'bill_notesHint'.tr,
              initialValue: sub?.note ?? '',
              extra: {
                'inline': true,
                'maxLines': 4,
              },
            ),
          ],
          onSubmit: _saveSubscription,
        ),
      ),
    );
  }
}
