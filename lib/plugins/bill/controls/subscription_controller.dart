import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../models/bill.dart';
import '../bill_plugin.dart';
import 'package:Memento/core/event/event_manager.dart';

/// 订阅服务事件参数
class SubscriptionAddedEventArgs extends EventArgs {
  final Subscription subscription;
  SubscriptionAddedEventArgs(this.subscription) : super('subscription_added');
}

class SubscriptionUpdatedEventArgs extends EventArgs {
  final Subscription subscription;
  SubscriptionUpdatedEventArgs(this.subscription) : super('subscription_updated');
}

class SubscriptionTerminatedEventArgs extends EventArgs {
  final String subscriptionId;
  SubscriptionTerminatedEventArgs(this.subscriptionId) : super('subscription_terminated');
}

class SubscriptionDeletedEventArgs extends EventArgs {
  final String subscriptionId;
  SubscriptionDeletedEventArgs(this.subscriptionId) : super('subscription_deleted');
}

class SubscriptionController with ChangeNotifier {
  /// 订阅服务事件名称
  static const String subscriptionAddedEvent = 'subscription_added';
  static const String subscriptionUpdatedEvent = 'subscription_updated';
  static const String subscriptionTerminatedEvent = 'subscription_terminated';
  static const String subscriptionDeletedEvent = 'subscription_deleted';

  late final BillPlugin _plugin;
  final List<Subscription> _subscriptions = [];
  static const String _subscriptionsKey = 'subscriptions';

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);

  /// 设置BillPlugin实例
  void setPlugin(BillPlugin plugin) {
    _plugin = plugin;
  }

  /// 加载订阅服务列表
  Future<void> loadSubscriptions() async {
    try {
      final data = await _plugin.storage.readJson(
        'bill/$_subscriptionsKey.json',
        {'subscriptions': []},
      );

      final List<dynamic> subscriptionsJson = data['subscriptions'] ?? [];
      _subscriptions.clear();
      _subscriptions.addAll(
        subscriptionsJson.map((json) => Subscription.fromJson(json)).toList(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('加载订阅服务失败: $e');
    }
  }

  /// 保存订阅服务列表
  Future<void> _saveSubscriptions() async {
    try {
      final data = {
        'subscriptions': _subscriptions.map((s) => s.toJson()).toList(),
      };
      await _plugin.storage.writeJson(
        'bill/$_subscriptionsKey.json',
        data,
      );
    } catch (e) {
      debugPrint('保存订阅服务失败: $e');
      rethrow;
    }
  }

  /// 创建订阅服务
  Future<void> createSubscription(Subscription subscription) async {
    _subscriptions.add(subscription);
    await _saveSubscriptions();
    notifyListeners();

    // 广播事件
    EventManager.instance.broadcast(
      subscriptionAddedEvent,
      SubscriptionAddedEventArgs(subscription),
    );

    // 检查并生成今日的订阅账单
    await _generateBillsForSubscription(subscription);
  }

  /// 更新订阅服务
  Future<void> updateSubscription(Subscription subscription) async {
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      _subscriptions[index] = subscription;
      await _saveSubscriptions();
      notifyListeners();

      // 广播事件
      EventManager.instance.broadcast(
        subscriptionUpdatedEvent,
        SubscriptionUpdatedEventArgs(subscription),
      );
    }
  }

  /// 终止订阅服务
  Future<void> terminateSubscription(String subscriptionId) async {
    final subscription = _subscriptions.firstWhere(
      (s) => s.id == subscriptionId,
      orElse: () => throw Exception('订阅服务不存在'),
    );

    final updatedSubscription = subscription.copyWith(
      isActive: false,
    );

    final index = _subscriptions.indexOf(subscription);
    _subscriptions[index] = updatedSubscription;
    await _saveSubscriptions();
    notifyListeners();

    // 广播事件
    EventManager.instance.broadcast(
      subscriptionTerminatedEvent,
      SubscriptionTerminatedEventArgs(subscriptionId),
    );
  }

  /// 删除订阅服务
  Future<void> deleteSubscription(String subscriptionId) async {
    _subscriptions.removeWhere((s) => s.id == subscriptionId);
    await _saveSubscriptions();
    notifyListeners();

    // 广播事件
    EventManager.instance.broadcast(
      subscriptionDeletedEvent,
      SubscriptionDeletedEventArgs(subscriptionId),
    );
  }

  /// 获取活跃的订阅服务
  List<Subscription> getActiveSubscriptions() {
    return _subscriptions.where((s) => s.isActive).toList();
  }

  /// 检查并生成缺失的订阅账单
  Future<void> checkAndGenerateMissingBills() async {
    for (final subscription in getActiveSubscriptions()) {
      await _generateBillsForSubscription(subscription);
    }
  }

  /// 为订阅服务生成账单
  Future<void> _generateBillsForSubscription(Subscription subscription) async {
    // 获取订阅账户（如果有多个账户，可以选择默认账户）
    final account = _plugin.selectedAccount;
    if (account == null) return;

    // 获取已存在的订阅账单
    final existingBills = account.bills.where(
      (bill) => bill.subscriptionId == subscription.id,
    ).toList();

    // 创建已存在账单的日期集合
    final existingDates = <String>{};
    for (final bill in existingBills) {
      final dateStr = '${bill.date.year}-${bill.date.month.toString().padLeft(2, '0')}-${bill.date.day.toString().padLeft(2, '0')}';
      existingDates.add(dateStr);
    }

    // 生成应该存在的日期列表
    final shouldHaveDates = <String>{};
    final now = DateTime.now();
    final lastDate = subscription.endDate != null && subscription.endDate!.isBefore(now)
        ? subscription.endDate!
        : now;

    for (int i = 0; i < subscription.days; i++) {
      final billDate = DateTime(
        subscription.startDate.year,
        subscription.startDate.month,
        subscription.startDate.day,
      ).add(Duration(days: i));

      if (billDate.isAfter(lastDate)) break;

      final dateStr = '${billDate.year}-${billDate.month.toString().padLeft(2, '0')}-${billDate.day.toString().padLeft(2, '0')}';
      shouldHaveDates.add(dateStr);
    }

    // 找出缺失的日期
    final missingDates = shouldHaveDates.difference(existingDates);

    // 生成缺失的账单
    for (final dateStr in missingDates) {
      final parts = dateStr.split('-');
      final billDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      // 只有过去的日期才生成账单
      if (billDate.isBefore(DateTime.now())) {
        final bill = Bill(
          id: const Uuid().v4(),
          title: '[订阅] ${subscription.name}',
          amount: -subscription.dailyAmount, // 支出为负数
          accountId: account.id,
          category: subscription.category,
          date: billDate,
          note: '自动生成的订阅账单 - ${subscription.days}天总金额¥${subscription.totalAmount.toStringAsFixed(2)}',
          icon: subscription.icon,
          iconColor: subscription.iconColor,
          isSubscription: true,
          subscriptionId: subscription.id,
          subscriptionStartDate: subscription.startDate,
          subscriptionEndDate: subscription.endDate,
        );

        await _plugin.controller.saveBill(bill);
      }
    }
  }

  /// 根据ID查找订阅服务
  Subscription? findSubscriptionById(String id) {
    try {
      return _subscriptions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
