import 'package:flutter/widgets.dart';
import 'package:Memento/core/event/event_manager.dart';

// 调试开关
const _kDebugEventListener = true;

/// 事件监听容器组件
/// 传入事件名称列表并监听，触发时通知父组件更新UI
///
/// 基础用法（无事件数据）：
/// ```dart
/// EventListenerContainer(
///   events: ['task_added', 'task_updated', 'task_deleted'],
///   onEvent: () => setState(() {}),
///   child: MyContent(),
/// )
/// ```
///
/// 高级用法（接收事件数据，性能优化）：
/// ```dart
/// EventListenerContainer(
///   events: ['diary_cache_updated'],
///   onEventWithData: (args) {
///     if (args is DiaryCacheUpdatedEventArgs) {
///       setState(() {
///         cachedEntries = args.entries;
///       });
///     }
///   },
///   child: MyContent(),
/// )
/// ```
class EventListenerContainer extends StatefulWidget {
  /// 要监听的事件名称列表
  final List<String> events;

  /// 事件触发时的回调（无事件数据，向后兼容）
  final VoidCallback? onEvent;

  /// 事件触发时的回调（携带事件数据，性能优化）
  /// 优先级高于 onEvent
  final void Function(EventArgs)? onEventWithData;

  /// 子组件
  final Widget child;

  const EventListenerContainer({
    super.key,
    required this.events,
    this.onEvent,
    this.onEventWithData,
    required this.child,
  }) : assert(
         onEvent != null || onEventWithData != null,
         'Either onEvent or onEventWithData must be provided',
       );

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
        if (_kDebugEventListener) {
          debugPrint('[EventListenerContainer] Received event: $event, args type: ${args.runtimeType}');
        }
        if (mounted) {
          // 优先使用 onEventWithData（性能优化，直接使用事件数据）
          if (widget.onEventWithData != null) {
            if (_kDebugEventListener) {
              debugPrint('[EventListenerContainer] Calling onEventWithData');
            }
            widget.onEventWithData!(args);
          } else if (widget.onEvent != null) {
            // 向后兼容
            widget.onEvent!();
          }
        }
      }
      EventManager.instance.subscribe(event, handler);
      _subscriptions.add((event, handler));
      if (_kDebugEventListener) {
        debugPrint('[EventListenerContainer] Subscribed to: $event');
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
