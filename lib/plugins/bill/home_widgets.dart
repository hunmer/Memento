import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
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

    // 创建账单快捷入口 - 选择账户和时间范围后显示收支统计
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
      selectorId: 'bill.account_with_period',
      dataRenderer: _renderBillStatsData,
      navigationHandler: _navigateToCreateBill,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('bill_create_shortcut')!,
        config: config,
      ),
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

  /// 渲染账单统计小组件数据 - 显示账户信息、时间范围和收支统计
  static Widget _renderBillStatsData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 使用 getPathRawData 安全获取指定步骤的原始数据
    final accountData = result.getPathRawData<Map<String, dynamic>>('account');
    final periodData = result.getPathRawData<Map<String, dynamic>>('period');

    // 如果 path 为空，尝试从 result.data 获取（兼容旧数据）
    if (accountData == null && result.data is Map<String, dynamic>) {
      final data = result.data as Map<String, dynamic>;
      if (data.containsKey('title') && !data.containsKey('label')) {
        // 这是账户数据
        // ignore: avoid_as
      } else if (data.containsKey('label')) {
        // 这是时间范围数据
      }
    }

    final accountId = accountData?['id'] as String? ?? '';
    final accountTitle = accountData?['title'] as String? ?? '未知账户';
    final accountIconData = accountData?['icon'] as int?;
    final accountIcon = accountIconData != null
        ? IconData(accountIconData, fontFamily: 'MaterialIcons')
        : Icons.account_balance_wallet;
    final periodLabel = periodData?['label'] as String? ?? '本月';

    // 支出卡片颜色（红色系）
    const expenseGradient = [
      Color(0xFFEF5350),
      Color(0xFFE53935),
    ];
    // 收入卡片颜色（绿色系）
    const incomeGradient = [
      Color(0xFF66BB6A),
      Color(0xFF43A047),
    ];

    return FutureBuilder<Map<String, double>>(
      future: _loadBillStats(accountId, periodData),
      builder: (context, snapshot) {
        final expense = snapshot.data?['expense'] ?? 0.0;
        final income = snapshot.data?['income'] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部账户信息和时间范围
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      accountIcon,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountTitle,
                          style: theme.textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          periodLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 双卡片：支出和收入
              Row(
                children: [
                  // 支出卡片
                  Expanded(
                    child: _buildBillTypeCard(
                      context: context,
                      amount: expense,
                      gradient: expenseGradient,
                      accountId: accountId,
                      isExpense: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 收入卡片
                  Expanded(
                    child: _buildBillTypeCard(
                      context: context,
                      amount: income,
                      gradient: incomeGradient,
                      accountId: accountId,
                      isExpense: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 加载账单统计数据
  static Future<Map<String, double>> _loadBillStats(
    String accountId,
    Map<String, dynamic>? periodData,
  ) async {
    try {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) return {'expense': 0.0, 'income': 0.0};

      DateTime? startDate;
      DateTime? endDate = DateTime.now();

      if (periodData != null) {
        final startStr = periodData['start'] as String?;
        final endStr = periodData['end'] as String?;
        if (startStr != null) startDate = DateTime.parse(startStr);
        if (endStr != null) endDate = DateTime.parse(endStr);
      }

      final controller = plugin.controller;

      // 如果指定了账户，只统计该账户的账单
      if (accountId.isNotEmpty) {
        final allBills = await controller.getBills(
          startDate: startDate,
          endDate: endDate,
        );
        final accountBills = allBills.where((b) => b.accountId == accountId).toList();

        final income = accountBills
            .where((b) => b.amount > 0)
            .fold<double>(0, (sum, b) => sum + b.amount);

        final expense = accountBills
            .where((b) => b.amount < 0)
            .fold<double>(0, (sum, b) => sum + b.amount.abs());

        return {'expense': expense, 'income': income};
      }

      // 未指定账户，统计所有账户
      final income = await controller.getTotalIncome(
        startDate: startDate,
        endDate: endDate,
      );
      final expense = await controller.getTotalExpense(
        startDate: startDate,
        endDate: endDate,
      );

      return {'expense': expense, 'income': income};
    } catch (e) {
      debugPrint('加载账单统计失败: $e');
      return {'expense': 0.0, 'income': 0.0};
    }
  }

  /// 构建账单类型卡片（支出/收入）- 显示金额
  static Widget _buildBillTypeCard({
    required BuildContext context,
    required double amount,
    required List<Color> gradient,
    required String accountId,
    required bool isExpense,
  }) {
    final symbolIcon = isExpense ? Icons.remove : Icons.add;
    final amountStr = amount > 0 ? '¥${amount.toStringAsFixed(0)}' : '¥0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 打开创建账单界面
          NavigationHelper.pushNamed(
            context,
            '/bill',
            arguments: {
              'action': 'create',
              'accountId': accountId.isNotEmpty ? accountId : null,
              'isExpense': isExpense,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient.map((c) => c.withOpacity(0.9)).toList(),
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 金额
              Center(
                child: Text(
                  amountStr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // 右下角图标
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    symbolIcon,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到创建账单界面（点击整个卡片时触发）
  static void _navigateToCreateBill(
    BuildContext context,
    SelectorResult result,
  ) {
    // 使用 getPathRawData 安全获取账户ID
    final accountData = result.getPathRawData<Map<String, dynamic>>('account');
    final accountId = accountData?['id'] as String?;

    // 如果 path 为空，尝试从 result.data 获取
    if (accountId == null && result.data is Map<String, dynamic>) {
      final data = result.data as Map<String, dynamic>;
      if (data.containsKey('title')) {
        // 这是账户数据
      } else if (data.containsKey('id')) {
        // 这可能是旧版本的账户数据
      }
    }

    // 默认打开支出账单
    NavigationHelper.pushNamed(
      context,
      '/bill',
      arguments: {
        'action': 'create',
        'accountId': accountId,
        'isExpense': true,
      },
    );
  }
}
