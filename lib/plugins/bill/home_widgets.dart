import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
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

    // 创建账单快捷入口 - 直接跳转到创建账单界面
    registry.register(HomeWidget(
      id: 'bill_create_shortcut',
      pluginId: 'bill',
      name: 'bill_createShortcutName'.tr,
      description: 'bill_createShortcutDescription'.tr,
      icon: Icons.add_card,
      color: Colors.green,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.small, HomeWidgetSize.medium],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildCreateShortcutWidget(context, config),
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

  /// 构建创建账单快捷入口小组件
  static Widget _buildCreateShortcutWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final size = config['size'] as HomeWidgetSize? ?? HomeWidgetSize.medium;
    final isSmall = size == HomeWidgetSize.small;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleCreateBillTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.8),
                Colors.green.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isSmall) ...[
                // 大尺寸显示完整布局
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'bill_createBill'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 显示常用分类图标
                _buildQuickCategoryIcons(),
              ] else ...[
                // 小尺寸只显示图标
                Icon(
                  Icons.add_circle,
                  size: 32,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建快速分类图标行
  static Widget _buildQuickCategoryIcons() {
    final categories = [
      {'icon': Icons.restaurant, 'label': '餐饮'},
      {'icon': Icons.shopping_bag, 'label': '购物'},
      {'icon': Icons.commute, 'label': '交通'},
      {'icon': Icons.attach_money, 'label': '工资'},
    ];

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: categories.map((category) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category['icon'] as IconData,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                category['label'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 处理创建账单点击事件
  static void _handleCreateBillTap(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) {
        return;
      }

      // 检查是否有账户
      if (plugin.accounts.isEmpty) {
        // 如果没有账户,先导航到账户管理界面
        NavigationHelper.pushNamed(context, '/bill');
        return;
      }

      // 获取选中的账户ID
      final accountId = plugin.selectedAccount?.id ?? plugin.accounts.first.id;

      // 直接导航到创建账单界面
      NavigationHelper.pushNamed(
        context,
        '/bill',
        arguments: {
          'action': 'create',
          'accountId': accountId,
        },
      );
    } catch (e) {
      debugPrint('创建账单快捷入口错误: $e');
    }
  }
}
