import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/bill/models/account.dart';
import 'package:Memento/plugins/bill/models/bill.dart';

/// 账单插件示例数据
/// 当插件首次使用且没有数据时，自动加载这些示例数据
class BillSampleData {
  /// 获取示例账户和账单数据
  /// 当 accounts.json 文件不存在时使用
  static Map<String, dynamic> getSampleData() {
    // 获取当前时间作为基准
    final now = DateTime.now();

    // 示例账户1: 现金账户
    final cashAccount = Account(
      id: 'cash-account-001',
      title: '现金账户',
      icon: Icons.wallet,
      backgroundColor: const Color(0xFF4CAF50), // 绿色
      totalAmount: 0.0,
      bills: [
        // 月初工资 - 3天前
        Bill(
          id: 'bill-001',
          title: '月度工资',
          amount: 8500.0,
          category: '工资',
          date: now.subtract(const Duration(days: 3)),
          accountId: 'cash-account-001',
          note: '${_getCurrentMonth()}工资',
          tag: '固定收入',
          icon: Icons.work,
          iconColor: Colors.green,
          createdAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 9)),
          updatedAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 9)),
        ),
        // 昨天午餐
        Bill(
          id: 'bill-002',
          title: '午餐',
          amount: -32.5,
          category: '餐饮',
          date: now.subtract(const Duration(days: 1)).add(const Duration(hours: 12, minutes: 30)),
          accountId: 'cash-account-001',
          note: '公司附近餐厅',
          tag: '工作日',
          icon: Icons.restaurant,
          iconColor: Colors.orange,
          createdAt: now.subtract(const Duration(days: 1)).add(const Duration(hours: 12, minutes: 30)),
          updatedAt: now.subtract(const Duration(days: 1)).add(const Duration(hours: 12, minutes: 30)),
        ),
        // 前天地铁卡充值
        Bill(
          id: 'bill-003',
          title: '地铁卡充值',
          amount: -100.0,
          category: '交通',
          date: now.subtract(const Duration(days: 2)).add(const Duration(hours: 8, minutes: 15)),
          accountId: 'cash-account-001',
          note: '充值200元，实际消费100元',
          tag: '通勤',
          icon: Icons.directions_transit,
          iconColor: Colors.blue,
          createdAt: now.subtract(const Duration(days: 2)).add(const Duration(hours: 8, minutes: 15)),
          updatedAt: now.subtract(const Duration(days: 2)).add(const Duration(hours: 8, minutes: 15)),
        ),
        // 4天前超市购物
        Bill(
          id: 'bill-004',
          title: '超市购物',
          amount: -258.8,
          category: '购物',
          date: now.subtract(const Duration(days: 4)).add(const Duration(hours: 19, minutes: 20)),
          accountId: 'cash-account-001',
          note: '日用品和食材',
          tag: '生活必需品',
          icon: Icons.shopping_cart,
          iconColor: Colors.purple,
          createdAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 19, minutes: 20)),
          updatedAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 19, minutes: 20)),
        ),
        // 5天前朋友聚餐
        Bill(
          id: 'bill-005',
          title: '朋友聚餐',
          amount: -168.0,
          category: '餐饮',
          date: now.subtract(const Duration(days: 5)).add(const Duration(hours: 18, minutes: 45)),
          accountId: 'cash-account-001',
          note: '火锅聚餐，4人AA',
          tag: '社交',
          icon: Icons.restaurant,
          iconColor: Colors.orange,
          createdAt: now.subtract(const Duration(days: 5)).add(const Duration(hours: 18, minutes: 45)),
          updatedAt: now.subtract(const Duration(days: 5)).add(const Duration(hours: 18, minutes: 45)),
        ),
        // 6天前兼职收入
        Bill(
          id: 'bill-006',
          title: '兼职收入',
          amount: 1200.0,
          category: '工资',
          date: now.subtract(const Duration(days: 6)).add(const Duration(hours: 20)),
          accountId: 'cash-account-001',
          note: '周末兼职费',
          tag: '额外收入',
          icon: Icons.work,
          iconColor: Colors.green,
          createdAt: now.subtract(const Duration(days: 6)).add(const Duration(hours: 20)),
          updatedAt: now.subtract(const Duration(days: 6)).add(const Duration(hours: 20)),
        ),
      ],
    );

    // 示例账户2: 信用卡
    final creditCard = Account(
      id: 'credit-card-001',
      title: '信用卡',
      icon: Icons.credit_card,
      backgroundColor: const Color(0xFF2196F3), // 蓝色
      totalAmount: 0.0,
      bills: [
        // 昨天网上购物
        Bill(
          id: 'bill-007',
          title: '网上购物',
          amount: -599.0,
          category: '购物',
          date: now.subtract(const Duration(days: 1)).add(const Duration(hours: 14, minutes: 30)),
          accountId: 'credit-card-001',
          note: '购买冬季外套',
          tag: '服装',
          icon: Icons.shopping_bag,
          iconColor: Colors.pink,
          createdAt: now.subtract(const Duration(days: 1)).add(const Duration(hours: 14, minutes: 30)),
          updatedAt: now.subtract(const Duration(days: 1)).add(const Duration(hours: 14, minutes: 30)),
        ),
        // 2天前电影票
        Bill(
          id: 'bill-008',
          title: '电影票',
          amount: -68.0,
          category: '娱乐',
          date: now.subtract(const Duration(days: 2)).add(const Duration(hours: 21, minutes: 15)),
          accountId: 'credit-card-001',
          note: '《热辣滚烫》',
          tag: '休闲',
          icon: Icons.movie,
          iconColor: Colors.red,
          createdAt: now.subtract(const Duration(days: 2)).add(const Duration(hours: 21, minutes: 15)),
          updatedAt: now.subtract(const Duration(days: 2)).add(const Duration(hours: 21, minutes: 15)),
        ),
        // 今天早上咖啡
        Bill(
          id: 'bill-009',
          title: '咖啡',
          amount: -28.0,
          category: '餐饮',
          date: now.subtract(const Duration(hours: 3)),
          accountId: 'credit-card-001',
          note: '星巴克拿铁',
          tag: '提神',
          icon: Icons.local_cafe,
          iconColor: Colors.brown,
          createdAt: now.subtract(const Duration(hours: 3)),
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        // 3天前电费
        Bill(
          id: 'bill-010',
          title: '电费',
          amount: -320.5,
          category: '生活缴费',
          date: now.subtract(const Duration(days: 3)).add(const Duration(hours: 10)),
          accountId: 'credit-card-001',
          note: '${_getCurrentMonth()}电费',
          tag: '固定支出',
          icon: Icons.bolt,
          iconColor: Colors.yellow,
          createdAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 10)),
          updatedAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 10)),
        ),
        // 4天前话费充值
        Bill(
          id: 'bill-011',
          title: '话费充值',
          amount: -100.0,
          category: '生活缴费',
          date: now.subtract(const Duration(days: 4)).add(const Duration(hours: 16, minutes: 20)),
          accountId: 'credit-card-001',
          note: '中国移动充值',
          tag: '通讯',
          icon: Icons.phone,
          iconColor: Colors.green,
          createdAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 16, minutes: 20)),
          updatedAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 16, minutes: 20)),
        ),
      ],
    );

    // 示例账户3: 储蓄账户
    final savingsAccount = Account(
      id: 'savings-account-001',
      title: '储蓄账户',
      icon: Icons.savings,
      backgroundColor: const Color(0xFFFF9800), // 橙色
      totalAmount: 0.0,
      bills: [
        // 3天前投资收益
        Bill(
          id: 'bill-012',
          title: '投资收益',
          amount: 350.0,
          category: '投资收益',
          date: now.subtract(const Duration(days: 3)).add(const Duration(hours: 15, minutes: 30)),
          accountId: 'savings-account-001',
          note: '基金定投收益',
          tag: '理财',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          createdAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 15, minutes: 30)),
          updatedAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 15, minutes: 30)),
        ),
        // 5天前定期存款利息
        Bill(
          id: 'bill-013',
          title: '定期存款利息',
          amount: 125.8,
          category: '投资收益',
          date: now.subtract(const Duration(days: 5)).add(const Duration(hours: 11)),
          accountId: 'savings-account-001',
          note: '3个月定期存款利息',
          tag: '被动收入',
          icon: Icons.account_balance,
          iconColor: Colors.indigo,
          createdAt: now.subtract(const Duration(days: 5)).add(const Duration(hours: 11)),
          updatedAt: now.subtract(const Duration(days: 5)).add(const Duration(hours: 11)),
        ),
        // 4天前银行转账
        Bill(
          id: 'bill-014',
          title: '银行转账',
          amount: -2000.0,
          category: '转账',
          date: now.subtract(const Duration(days: 4)).add(const Duration(hours: 13, minutes: 45)),
          accountId: 'savings-account-001',
          note: '转至现金账户',
          tag: '资金调配',
          icon: Icons.swap_horiz,
          iconColor: Colors.blueGrey,
          createdAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 13, minutes: 45)),
          updatedAt: now.subtract(const Duration(days: 4)).add(const Duration(hours: 13, minutes: 45)),
        ),
      ],
    );

    // 计算所有账户的总金额
    cashAccount.calculateTotal();
    creditCard.calculateTotal();
    savingsAccount.calculateTotal();

    // 将账户转换为JSON字符串数组（符合存储格式）
    final accountsJson = [
      jsonEncode(cashAccount.toJson()),
      jsonEncode(creditCard.toJson()),
      jsonEncode(savingsAccount.toJson()),
    ];

    // 返回符合存储格式的数据
    return {
      'accounts': accountsJson,
    };
  }

  /// 获取简化版示例数据（用于快速测试）
  /// 包含较少账户和账单，便于快速验证功能
  static Map<String, dynamic> getSimplifiedSampleData() {
    // 获取当前时间作为基准
    final now = DateTime.now();

    // 简化账户1: 现金
    final simpleCash = Account(
      id: 'simple-cash-001',
      title: '现金',
      icon: Icons.money,
      backgroundColor: const Color(0xFF8BC34A),
      bills: [
        // 3天前工资收入
        Bill(
          id: 'simple-bill-001',
          title: '工资收入',
          amount: 5000.0,
          category: '工资',
          date: now.subtract(const Duration(days: 3)),
          accountId: 'simple-cash-001',
          note: '基本工资',
          icon: Icons.work,
          iconColor: Colors.green,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        // 昨天午餐
        Bill(
          id: 'simple-bill-002',
          title: '午餐',
          amount: -25.0,
          category: '餐饮',
          date: now.subtract(const Duration(days: 1)),
          accountId: 'simple-cash-001',
          note: '工作餐',
          icon: Icons.restaurant,
          iconColor: Colors.orange,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        // 前天交通费
        Bill(
          id: 'simple-bill-003',
          title: '交通费',
          amount: -15.0,
          category: '交通',
          date: now.subtract(const Duration(days: 2)),
          accountId: 'simple-cash-001',
          note: '地铁票',
          icon: Icons.directions_transit,
          iconColor: Colors.blue,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );

    simpleCash.calculateTotal();

    return {
      'accounts': [
        jsonEncode(simpleCash.toJson()),
      ],
    };
  }

  /// 获取空白数据（仅创建默认账户，无账单）
  static Map<String, dynamic> getEmptyData() {
    final emptyAccount = Account(
      id: 'default-account-001',
      title: '我的账户',
      icon: Icons.account_balance_wallet,
      backgroundColor: const Color(0xFF607D8B),
      bills: [],
    );

    emptyAccount.calculateTotal();

    return {
      'accounts': [
        jsonEncode(emptyAccount.toJson()),
      ],
    };
  }

  /// 获取当前月份的中文表示
  static String _getCurrentMonth() {
    final now = DateTime.now();
    const months = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return months[now.month - 1];
  }
}
