import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'bill_plugin.dart';

/// 账单插件的主页小组件注册
class BillHomeWidgets {
  /// 注册所有账单插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'bill_icon',
      pluginId: 'bill',
      name: 'bill_widgetName'.tr,
      description: 'bill_widgetDescription'.tr,
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        name: 'bill_widgetName'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'bill_overview',
      pluginId: 'bill',
      name: 'bill_overviewName'.tr,
      description: 'bill_overviewDescription'.tr,
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.green,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) return [];
      final todayFinance = plugin.controller.getTodayFinance();
      final monthFinance = plugin.controller.getMonthFinance();
      final monthBillCount = plugin.controller.getMonthBillCount();

      return [
        StatItemData(
          id: 'today_finance',
          label: 'bill_todayFinance'.tr,
          value: '¥${todayFinance.toStringAsFixed(2)}',
          highlight: todayFinance != 0,
          color: todayFinance >= 0 ? Colors.green : Colors.red,
        ),
        StatItemData(
          id: 'month_finance',
          label: 'bill_monthFinance'.tr,
          value: '¥${monthFinance.toStringAsFixed(2)}',
          highlight: monthFinance != 0,
          color: monthFinance >= 0 ? Colors.green : Colors.red,
        ),
        StatItemData(
          id: 'month_bills',
          label: 'bill_monthlyRecord'.tr,
          value: '$monthBillCount',
          highlight: false,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {

      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'bill',
        pluginName: 'bill_name'.tr,
        pluginIcon: Icons.account_balance_wallet,
        pluginDefaultColor: Colors.green,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
