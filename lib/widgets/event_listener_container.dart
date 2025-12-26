import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:Memento/core/event/event_manager.dart';

/// 事件监听容器组件
/// 传入事件名称列表并监听，触发时通知父组件更新UI
///
/// ```dart
/// EventListenerContainer(
///   events: ['task_added', 'task_updated', 'task_deleted'],
///   onEvent: () => setState(() {}),
///   child: MyContent(),
/// )
/// ```
class EventListenerContainer extends StatefulWidget {
  /// 要监听的事件名称列表
  final List<String> events;

  /// 事件触发时的回调
  final VoidCallback onEvent;

  /// 子组件
  final Widget child;

  const EventListenerContainer({
    super.key,
    required this.events,
    required this.onEvent,
    required this.child,
  });

  @override
  State<EventListenerContainer> createState() => _EventListenerContainerState();
}

class _EventListenerContainerState extends State<EventListenerContainer> {
  /// 存储事件订阅列表
  final List<(String eventName, void Function(EventArgs) handler)> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _registerEventListeners();
  }

  void _registerEventListeners() {
    for (final event in widget.events) {
      void handler(EventArgs args) {
        if (kDebugMode) {
          print('[EventListenerContainer] received event: "$event"');
        }
        if (mounted) {
          widget.onEvent();
        }
      }
      EventManager.instance.subscribe(event, handler);
      _subscriptions.add((event, handler));
      if (kDebugMode) {
        print('[EventListenerContainer] subscribed to: "$event"');
      }
    }
  }

  @override
  void dispose() {
    // 取消所有事件订阅
    for (final (eventName, handler) in _subscriptions) {
      EventManager.instance.unsubscribe(eventName, handler);
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
