/// 账单插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'bill_colors.dart';

/// 账单统计类型
enum BillStatsType { income, expense, balance }

/// 获取账单统计数据
///
/// [config] 包含:
/// - type: BillStatsType (income/expense/balance)
/// - startDate: 开始日期 (ISO8601)
/// - endDate: 结束日期 (ISO8601)
/// - targetAmount: 目标金额
/// - month: 月份 (yyyy-MM)
Future<Map<String, Map<String, dynamic>>> provideBillCommonWidgets(
  Map<String, dynamic> config,
) async {
  final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
  if (plugin == null) return {};

  // 解析配置
  final typeStr = config['type'] as String? ?? 'expense';
  final startDateStr = config['startDate'] as String?;
  final endDateStr = config['endDate'] as String?;
  final targetAmount = (config['targetAmount'] as num?)?.toDouble() ?? 10000.0;
  final monthStr = config['month'] as String?;

  DateTime? startDate;
  DateTime? endDate;
  DateTime? month;

  if (startDateStr != null) {
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (e) {
      debugPrint('[BillCommonWidgets] 解析 startDate 失败: $e');
    }
  }

  if (endDateStr != null) {
    try {
      endDate = DateTime.parse(endDateStr);
    } catch (e) {
      debugPrint('[BillCommonWidgets] 解析 endDate 失败: $e');
    }
  }

  if (monthStr != null) {
    try {
      month = DateTime.parse('$monthStr-01');
    } catch (e) {
      debugPrint('[BillCommonWidgets] 解析 month 失败: $e');
    }
  }

  // 如果指定了月份，覆盖日期范围
  if (month != null) {
    startDate = DateTime(month.year, month.month, 1);
    endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  }

  // 默认使用本月
  if (startDate == null && endDate == null) {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  // 获取账单数据
  final controller = plugin.controller;
  final bills = await controller.getBills(startDate: startDate, endDate: endDate);
  final accounts = controller.accounts;

  // 计算收入和支出
  double totalIncome = 0;
  double totalExpense = 0;
  final Map<String, double> categoryStats = {};
  final List<Map<String, dynamic>> billRecords = [];

  for (final bill in bills) {
    if (bill.amount > 0) {
      totalIncome += bill.amount;
    } else {
      totalExpense += bill.amount.abs();

      // 按类别统计支出
      final category = bill.category;
      categoryStats[category] = (categoryStats[category] ?? 0) + bill.amount.abs();
    }

    // 记录账单
    billRecords.add({
      'id': bill.id,
      'title': bill.title,
      'amount': bill.amount,
      'category': bill.category,
      'date': bill.date.toIso8601String(),
      'iconCodePoint': bill.icon.codePoint,
      'iconColor': bill.iconColor.value,
    });
  }

  final balance = totalIncome - totalExpense;

  // 根据类型确定显示的值
  double currentValue;
  String valueLabel;
  switch (typeStr) {
    case 'income':
      currentValue = totalIncome;
      valueLabel = '收入';
      break;
    case 'balance':
      currentValue = balance;
      valueLabel = '结余';
      break;
    case 'expense':
    default:
      currentValue = totalExpense;
      valueLabel = '支出';
      break;
  }

  // 按支出金额排序类别
  final sortedCategories = categoryStats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // 日期范围标签
  String dateRangeLabel = '本月';
  if (month != null) {
    dateRangeLabel = DateFormat('yyyy年MM月').format(month);
  } else if (startDate != null && endDate != null) {
    if (startDate.day == 1 && endDate.day == endDate.day) {
      dateRangeLabel = DateFormat('yyyy年MM月').format(startDate);
    } else {
      dateRangeLabel =
          '${DateFormat('MM/dd').format(startDate)} - ${DateFormat('MM/dd').format(endDate)}';
    }
  }

  // 获取账户信息
  final accountInfo = accounts.isNotEmpty
      ? {
          'name': accounts.first.title,
          'iconCodePoint': accounts.first.icon.codePoint,
          'iconColor': billColor.value,
        }
      : {
          'name': '默认账户',
          'iconCodePoint': Icons.account_balance_wallet.codePoint,
          'iconColor': billColor.value,
        };

  return {
    // 半圆仪表盘卡片：显示预算进度
    'halfCircleGaugeWidget': {
      'title': valueLabel,
      'subtitle': dateRangeLabel,
      'currentValue': currentValue,
      'targetValue': targetAmount,
      'unit': '¥',
      'progressColor':
          (currentValue <= targetAmount ? const Color(0xFF4CAF50) : const Color(0xFFF44336)).value,
      'backgroundColor': const Color(0xFFEEEEEE).value,
    },

    // 分段进度卡片：按类别显示支出
    'segmentedProgressCard': {
      'title': '支出分析',
      'subtitle': dateRangeLabel,
      'currentValue': totalExpense,
      'targetValue': targetAmount,
      'unit': '¥',
      'segments': sortedCategories.take(5).map((e) {
        return {
          'label': e.key,
          'value': e.value,
          'display': '¥${e.value.toStringAsFixed(0)}',
          'color': getCategoryColor(e.key).value,
        };
      }).toList(),
    },

    // 圆形进度卡片：显示收入/支出比例
    'circularProgressCard': {
      'title': '收支比例',
      'subtitle': dateRangeLabel,
      'progress': totalIncome > 0 ? totalExpense / totalIncome : 0.0,
      'progressColor': const Color(0xFFF44336).value, // red
      'centerWidget': {
        'title': '支出/收入',
        'value': totalIncome > 0
            ? '${(totalExpense / totalIncome * 100).toStringAsFixed(0)}%'
            : '0%',
        'subtitle': '¥${totalExpense.toStringAsFixed(0)} / ¥${totalIncome.toStringAsFixed(0)}',
      },
    },

    // 营养进度卡片：显示收支进度
    'nutritionProgressCard': {
      'leftData': {
        'current': currentValue,
        'total': targetAmount,
        'unit': '¥',
      },
      'leftConfig': {
        'icon': typeStr == 'income' ? '📈' : '📉',
        'label': valueLabel,
        'subtext': currentValue > targetAmount ? '超出预算' : '预算内',
      },
      'rightItems': sortedCategories.take(4).map((e) {
        return {
          'icon': '💰',
          'name': e.key,
          'current': e.value,
          'total': totalExpense > 0 ? totalExpense : 1.0,
          'color': getCategoryColor(e.key).value,
          'subtitle': '${(e.value / totalExpense * 100).toStringAsFixed(0)}%',
        };
      }).toList(),
    },

    // 分类堆叠卡片：显示类别支出
    'categoryStackWidget': {
      'title': '支出分类',
      'currentAmount': totalExpense,
      'targetAmount': targetAmount,
      'categories': sortedCategories.take(6).map((e) {
        return {
          'name': e.key,
          'amount': e.value,
          'color': getCategoryColor(e.key).value,
        };
      }).toList(),
    },

    // 钱包余额卡片：显示收支概览
    'walletBalanceCard': {
      'totalBalance': balance,
      'income': totalIncome,
      'expense': totalExpense,
      'accountInfo': accountInfo,
      'period': dateRangeLabel,
    },

    // 月度账单卡片：显示月度账单列表
    'monthlyBillCard': {
      'month': monthStr ?? DateFormat('yyyy-MM').format(DateTime.now()),
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'bills': billRecords.take(10).toList(),
      'moreCount': billRecords.length > 10 ? billRecords.length - 10 : 0,
    },
  };
}

/// 从类别名称获取颜色
Color getCategoryColor(String category) {
  // 预定义颜色映射 - 使用 Color() 确保返回正确的 Color 类型
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

  return colorMap[category] ?? billColor;
}
