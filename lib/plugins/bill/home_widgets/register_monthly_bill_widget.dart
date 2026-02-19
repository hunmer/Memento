/// 账单插件 - 月份账单组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'bill_colors.dart';
import 'providers.dart' show provideMonthlyBillWidgets;

/// 注册月份账单组件
void registerMonthlyBillWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'monthly_bill_widget',
      pluginId: 'bill',
      name: 'bill_monthlyBillsWidgetName'.tr,
      description: 'bill_monthlyWidgetDescription'.tr,
      icon: Icons.calendar_month,
      color: billColor,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const MediumSize(),
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'bill.monthly.config',

      // 公共组件提供者（用于配置时预览）
      commonWidgetsProvider: provideMonthlyBillWidgets,

      // 导航处理器：点击时打开账单列表页面
      navigationHandler: _navigateToMonthlyBill,

      // 数据选择器：提取配置参数
      dataSelector: _extractConfigData,

      builder: (context, config) {
        return _MonthlyBillLiveSelectorWidget(
          widgetDefinition: registry.getWidget('monthly_bill_widget')!,
          config: config,
        );
      },
    ),
  );
}

/// 导航到月份账单页面
void _navigateToMonthlyBill(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    debugPrint('[MonthlyBillWidget] 配置数据为空');
    return;
  }

  // 获取配置参数
  final month = data['month'] as String?;

  // 导航到账单页面，传递月份参数
  NavigationHelper.pushNamed(
    context,
    '/bill',
    arguments: {
      'showBillListTab': true, // 显示账单列表标签页
      'selectedMonth': month,
    },
  );
}

/// 提取配置数据
Map<String, dynamic> _extractConfigData(List<dynamic> data) {
  // 数据格式为 [{month: ...}]
  if (data.isEmpty) return {};
  final item = data.first as Map<String, dynamic>;
  return item;
}

/// 月份账单小组件 - 实时数据选择器版本
///
/// 使用 LiveSelectorWidget 基类，减少重复代码
class _MonthlyBillLiveSelectorWidget extends LiveSelectorWidget {
  const _MonthlyBillLiveSelectorWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'bill_added',
    'bill_deleted',
    'account_added',
    'account_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) {
    return provideMonthlyBillWidgets(config);
  }

  @override
  String get widgetTag => 'MonthlyBillWidget';

  /// 自定义空状态（显示"暂无账单"）
  @override
  Widget buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无账单',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
