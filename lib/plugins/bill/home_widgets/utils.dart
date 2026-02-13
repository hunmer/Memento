/// 账单插件主页小组件工具函数
library;

import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'bill_colors.dart';

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractBillWidgetData(List<dynamic> dataArray) {
  final accountData = dataArray[0] as Map<String, dynamic>;
  final periodData = dataArray[1] as Map<String, dynamic>;

  return {
    'accountId': accountData['id'] as String,
    'accountTitle': accountData['title'] as String,
    'accountIcon': accountData['icon'] as int,
    'periodId': periodData['id'] as String,
    'periodLabel': periodData['label'] as String,
    'periodStart': periodData['start'] as String,
    'periodEnd': periodData['end'] as String,
  };
}

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
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

/// 加载账单统计数据
Future<Map<String, double>> loadBillStats(
  String accountId,
  String? periodStart,
  String? periodEnd,
) async {
  try {
    final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
    if (plugin == null) return {'expense': 0.0, 'income': 0.0};

    DateTime? startDate;
    DateTime? endDate = DateTime.now();

    if (periodStart != null) startDate = DateTime.parse(periodStart);
    if (periodEnd != null) endDate = DateTime.parse(periodEnd);

    final controller = plugin.controller;

    // 如果指定了账户，只统计该账户的账单
    if (accountId.isNotEmpty) {
      final allBills = await controller.getBills(
        startDate: startDate,
        endDate: endDate,
      );
      final accountBills =
          allBills.where((b) => b.accountId == accountId).toList();

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

/// 从类别名称获取颜色
Color getCategoryColor(String category) {
  // 预定义颜色映射
  final colorMap = <String, Color>{
    '餐饮': const Color(0xFFFF9800), // orange
    '交通': const Color(0xFF2196F3), // blue
    '购物': const Color(0xFF9C27B0), // purple
    '娱乐': const Color(0xFFE91E63), // pink
    '住房': const Color(0xFF795548), // brown
    '医疗': const Color(0xFFF44336), // red
    '教育': const Color(0xFF3F51B5), // indigo
    '通讯': const Color(0xFF00BCD4), // cyan
    '工资': const Color(0xFF4CAF50), // green
    '投资': const Color(0xFF009688), // teal
    '兼职': const Color(0xFF8BC34A), // lightGreen
    '礼金': const Color(0xFFFFC107), // amber
    '其他': const Color(0xFF9E9E9E), // grey
  };

  return colorMap[category] ?? const Color(0xFF9E9E9E);
}
