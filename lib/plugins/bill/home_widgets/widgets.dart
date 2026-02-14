/// 账单插件主页小组件 - 自定义小组件
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/screens/bill_edit_screen.dart';
import 'utils.dart';

/// 构建 2x2 详细卡片组件（概览组件）
Widget buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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
    final availableItems = getAvailableStats(context);

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
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 渲染账单统计小组件数据 - 显示账户信息、时间范围和收支统计
Widget renderBillStatsData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取已转换的数据（由 dataSelector 处理）
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};

  final accountId = data['accountId'] as String? ?? '';
  final accountTitle = data['accountTitle'] as String? ?? '未知账户';
  final accountIconData = data['accountIcon'] as int?;
  final accountIcon =
      accountIconData != null
          ? IconData(accountIconData, fontFamily: 'MaterialIcons')
          : Icons.account_balance_wallet;
  final periodLabel = data['periodLabel'] as String? ?? '本月';
  final periodStart = data['periodStart'] as String?;
  final periodEnd = data['periodEnd'] as String?;

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const [
          'bill_added',
          'bill_deleted',
          'account_added',
          'account_deleted',
        ],
        onEvent: () => setState(() {}),
        child: buildBillStatsWidget(
          context,
          accountId,
          accountTitle,
          accountIcon,
          periodLabel,
          periodStart,
          periodEnd,
        ),
      );
    },
  );
}

/// 构建账单统计小组件内容（获取最新数据）
Widget buildBillStatsWidget(
  BuildContext context,
  String accountId,
  String accountTitle,
  IconData accountIcon,
  String periodLabel,
  String? periodStart,
  String? periodEnd,
) {
  final theme = Theme.of(context);

  // 支出卡片颜色（红色系）
  const expenseGradient = [Color(0xFFEF5350), Color(0xFFE53935)];
  // 收入卡片颜色（绿色系）
  const incomeGradient = [Color(0xFF66BB6A), Color(0xFF43A047)];

  return FutureBuilder<Map<String, double>>(
    future: loadBillStats(accountId, periodStart, periodEnd),
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
                  child: Icon(
                    accountIcon,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: buildBillTypeCard(
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
                  child: buildBillTypeCard(
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

/// 构建账单类型卡片（支出/收入）- 显示金额
Widget buildBillTypeCard({
  required BuildContext context,
  required double amount,
  required List<Color> gradient,
  required String accountId,
  required bool isExpense,
}) {
  final amountStr = amount > 0 ? '¥${amount.toStringAsFixed(0)}' : '¥0';

  // 获取正确的 BuildContext 用于导航
  final navContext = navigatorKey.currentContext ?? context;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        // 使用与 diary 插件相同的方式：直接 push BillEditScreen
        final billPlugin =
            PluginManager.instance.getPlugin('bill') as BillPlugin?;
        if (billPlugin != null) {
          NavigationHelper.push(
            navContext,
            BillEditScreen(
              billPlugin: billPlugin,
              accountId:
                  accountId.isNotEmpty
                      ? accountId
                      : billPlugin.selectedAccount?.id ?? '',
              initialIsExpense: isExpense,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Center(
          child: Text(
            amountStr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: gradient[0],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 导航到创建账单界面（点击整个卡片时触发）
void navigateToCreateBill(BuildContext context, SelectorResult result) {
  // 从 result.data 获取已转换的数据（由 dataSelector 处理）
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};
  final accountId = data['accountId'] as String?;

  // 使用 navigatorKey.currentContext 确保导航正常工作
  final navContext = navigatorKey.currentContext ?? context;
  NavigationHelper.pushNamed(
    navContext,
    '/bill',
    arguments: {'action': 'create', 'accountId': accountId, 'isExpense': true},
  );
}
