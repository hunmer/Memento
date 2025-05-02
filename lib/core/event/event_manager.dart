import 'package:flutter/foundation.dart';
import 'dart:async';

/// 事件参数基类
class EventArgs {
  /// 事件名称
  final String eventName;
  
  /// 事件发生时间
  final DateTime whenOccurred;

  /// 创建一个事件参数实例
  EventArgs([this.eventName = '']) : whenOccurred = DateTime.now();
}

/// 事件订阅句柄，用于标识和管理订阅
class EventSubscription {
  final String _id;
  final String eventName;
  final Function(EventArgs) handler;
  bool _isActive = true;

  EventSubscription(this._id, this.eventName, this.handler);

  String get id => _id;
  bool get isActive => _isActive;

  void cancel() {
    _isActive = false;
  }
}

/// 事件管理器单例类
class EventManager {
  static final EventManager _instance = EventManager._internal();
  
  /// 获取EventManager单例实例
  static EventManager get instance => _instance;
  
  // 私有构造函数
  EventManager._internal();

  // 存储事件名称到订阅列表的映射
  final Map<String, List<EventSubscription>> _eventSubscriptions = {};
  
  // 用于生成唯一ID的计数器
  int _subscriptionIdCounter = 0;

  /// 注册一个事件处理器
  /// [eventName] 事件名称
  /// [handler] 事件处理函数
  /// 返回订阅句柄的唯一ID
  String subscribe(String eventName, Function(EventArgs) handler) {
    final id = 'sub_${_subscriptionIdCounter++}';
    final subscription = EventSubscription(id, eventName, handler);
    
    _eventSubscriptions.putIfAbsent(eventName, () => []).add(subscription);
    
    if (kDebugMode) {
      print('Event (debug): ${DateTime.now()} Subscribed to Event "$eventName"');
    }
    
    return id;
  }

  /// 通过事件名称和处理函数取消订阅
  /// [eventName] 事件名称
  /// [handler] 事件处理函数（可选）
  /// 如果不提供handler，则取消该事件的所有订阅
  /// 返回是否成功取消订阅
  bool unsubscribe(String eventName, [Function(EventArgs)? handler]) {
    bool removed = false;
    
    // 获取指定事件的订阅列表
    final subscriptions = _eventSubscriptions[eventName];
    if (subscriptions == null) return false;
    
    if (handler == null) {
      // 如果没有提供handler，取消该事件的所有订阅
      removed = subscriptions.isNotEmpty;
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
      subscriptions.clear();
    } else {
      // 如果提供了handler，只取消匹配的订阅
      subscriptions.removeWhere((subscription) {
        if (subscription.handler == handler && subscription.isActive) {
          subscription.cancel();
          removed = true;
          return true;
        }
        return false;
      });
    }
    
    // 清理空的事件列表
    if (subscriptions.isEmpty) {
      _eventSubscriptions.remove(eventName);
    }
    
    return removed;
  }

  /// 通过订阅ID取消订阅（已弃用）
  /// [subscriptionId] 订阅句柄的唯一ID
  /// 返回是否成功取消订阅
  @Deprecated('请使用 unsubscribe(eventName, [handler]) 方法代替')
  bool unsubscribeById(String subscriptionId) {
    bool removed = false;
    
    for (var subs in _eventSubscriptions.values) {
      subs.removeWhere((subscription) {
        if (subscription.id == subscriptionId && subscription.isActive) {
          subscription.cancel();
          removed = true;
          return true;
        }
        return false;
      });
    }
    
    // 清理空的事件列表
    _eventSubscriptions.removeWhere((_, subs) => subs.isEmpty);
    
    return removed;
  }

  /// 触发指定事件
  /// [eventName] 事件名称
  /// [args] 事件参数，如果不提供则使用默认的EventArgs
  void broadcast(String eventName, [EventArgs? args]) {
    final eventArgs = args ?? EventArgs(eventName);
    
    if (kDebugMode) {
      print('Event (debug): ${DateTime.now()} Broadcasting Event "$eventName"');
    }

    final subscriptions = _eventSubscriptions[eventName];
    if (subscriptions != null) {
      // 创建订阅列表的副本，以防在回调过程中发生修改
      final activeSubscriptions = subscriptions
          .where((subscription) => subscription.isActive)
          .toList();
      
      for (var subscription in activeSubscriptions) {
        try {
          subscription.handler(eventArgs);
        } catch (e) {
          debugPrint('Error in event handler for $eventName: $e');
        }
      }
    }
  }

  /// 将事件广播到Stream
  /// [eventName] 事件名称
  /// 返回包含事件参数的Stream
  Stream<EventArgs> asStream(String eventName) {
    final controller = StreamController<EventArgs>();
    late final String subscriptionId;
    
    handler(EventArgs args) {
      if (controller.isClosed) {
        unsubscribeById(subscriptionId);
        return;
      }
      controller.add(args);
    }
    
    subscriptionId = subscribe(eventName, handler);
    
    // 当Stream被取消时，自动取消事件订阅
    controller.onCancel = () {
      unsubscribeById(subscriptionId);
      controller.close();
    };
    
    return controller.stream;
  }

  /// 清除指定事件的所有订阅
  /// [eventName] 事件名称
  void clearEvent(String eventName) {
    _eventSubscriptions.remove(eventName);
  }

  /// 清除所有事件的订阅
  void clearAllEvents() {
    _eventSubscriptions.clear();
  }

  /// 获取指定事件的活跃订阅数量
  /// [eventName] 事件名称
  int getSubscriptionCount(String eventName) {
    return _eventSubscriptions[eventName]
        ?.where((subscription) => subscription.isActive)
        .length ?? 0;
  }
}