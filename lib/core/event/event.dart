/// 事件系统包，提供轻量级的事件发布/订阅机制
library;
export 'event_manager.dart';
export 'event_args.dart';

// 为方便使用，提供全局单例实例
import 'event_manager.dart';

/// 全局事件管理器实例
final eventManager = EventManager.instance;