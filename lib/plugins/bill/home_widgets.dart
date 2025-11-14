import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'bill_plugin.dart';
import 'l10n/bill_localizations.dart';

/// 账单插件的主页小组件注册
class BillHomeWidgets {
  /// 注册所有账单插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'bill_icon',
      pluginId: 'bill',
      name: '账单',
      description: '快速打开账单管理',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.account_balance_wallet,
        color: Colors.green,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'bill_overview',
      pluginId: 'bill',
      name: '账单概览',
      description: '显示今日和本月财务统计',
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.green,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
    try {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) return [];

      final todayFinance = plugin.controller.getTodayFinance();
      final monthFinance = plugin.controller.getMonthFinance();
      final monthBillCount = plugin.controller.getMonthBillCount();

      return [
        StatItemData(
          id: 'today_finance',
          label: '今日财务',
          value: '¥${todayFinance.toStringAsFixed(2)}',
          highlight: todayFinance != 0,
          color: todayFinance >= 0 ? Colors.green : Colors.red,
        ),
        StatItemData(
          id: 'month_finance',
          label: '本月财务',
          value: '¥${monthFinance.toStringAsFixed(2)}',
          highlight: monthFinance != 0,
          color: monthFinance >= 0 ? Colors.green : Colors.red,
        ),
        StatItemData(
          id: 'month_bills',
          label: '本月记账',
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
      final l10n = BillLocalizations.of(context);

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
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
