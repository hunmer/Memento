import 'package:flutter/material.dart';

class BillLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'todayFinance': 'Today Finance',
      'monthFinance': 'Month Finance',
      'monthBills': 'Month Bills',
      'accountTitle': 'Account',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'thisYear': 'This Year',
      'all': 'All',
      'custom': 'Custom',
      'noBills': 'No bill records',
      'confirmDelete': 'Are you sure you want to delete this bill record?',
      'deleteAccount': 'Delete Account',
      'enterAccountName': 'Please enter account name',
      'saveFailed': 'Save failed',
      'deleteFailed': 'Delete failed',
      'accountManagement': 'Account Management',
      'noAccounts': 'No accounts, click the button below to create',
      'accountDeleted': 'Account deleted',
      'saveSuccess': 'Save success',
      'expense': 'Expense',
      'income': 'Income',
      'timeRange': 'Time Range:',
      'delete': 'Delete',
    },
    'zh': {
      'todayFinance': '今日财务',
      'monthFinance': '本月财务',
      'monthBills': '本月记账',
      'accountTitle': '账户',
      'thisWeek': '本周',
      'thisMonth': '本月',
      'thisYear': '本年',
      'all': '全部',
      'custom': '自定义',
      'noBills': '暂无账单记录',
      'confirmDelete': '确定要删除这条账单记录吗？',
      'deleteAccount': '删除账户',
      'enterAccountName': '请输入账户名称',
      'saveFailed': '保存失败',
      'deleteFailed': '删除失败',
      'accountManagement': '账户管理',
      'noAccounts': '暂无账户，点击右下角按钮创建',
      'accountDeleted': '账户已删除',
      'saveSuccess': '保存成功',
      'expense': '支出',
      'income': '收入',
      'timeRange': '时间范围：',
      'delete': '删除',
    },
  };

  static String getText(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ?? _localizedValues['en']![key]!;
  }
}
