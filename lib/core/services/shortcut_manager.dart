import 'package:flutter/material.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/utils/logger_util.dart';

class ShortcutEventArgs extends EventArgs {
  final String action;
  ShortcutEventArgs({required this.action}) : super(action);
}

/// 管理应用程序快捷方式的全局服务
class AppShortcutManager {
  static final AppShortcutManager _instance = AppShortcutManager._internal();
  factory AppShortcutManager() => _instance;
  AppShortcutManager._internal();

  final LoggerUtil? _logger = LoggerUtil();

  /// 初始化快捷方式监听
  void initialize() {
    try {
      FlutterShortcut.initialize(debug: true);
      FlutterShortcut.listenAction((action) {
        _logger?.log('Shortcut action received: $action', level: 'DEBUG');
        eventManager.broadcast(
          'shortcut_action',
          ShortcutEventArgs(action: action),
        );
      });
      FlutterShortcut.setShortcutItems(
        shortcutItems: <ShortcutItem>[
          const ShortcutItem(
            id: "1",
            action: 'shortcut.scan',
            shortLabel: 'Scan code',
            icon: 'assets/icon/icon.png',
          ),
          const ShortcutItem(
            id: "2",
            action: 'shortcut.messages',
            shortLabel: 'Messages',
            icon: "messages",
            shortcutIconAsset: ShortcutIconAsset.nativeAsset,
          ),
        ],
      );
      eventManager.subscribe('shortcut_action', _handleAction);
    } catch (e) {
      _logger?.log(
        'Failed to initialize shortcut listener: $e',
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // 处理消息更新事件
  void _handleAction(EventArgs args) {
    if (args is! ShortcutEventArgs) return;
    final action = args.action;
    debugPrint('Shortcut action received: $action');
    switch (action) {
      case 'shortcut.scan':
        // 处理扫码快捷方式
        break;
      case 'shortcut.messages':
        // 处理消息快捷方式
        break;
      default:
        _logger?.log('Unknown shortcut action: $action', level: 'WARNING');
    }
  }

  /// 添加新的快捷方式
  void addShortcut({
    required String id,
    required String action,
    required String shortLabel,
    String? icon,
    ShortcutIconAsset iconAsset = ShortcutIconAsset.flutterAsset,
  }) {
    try {
      FlutterShortcut.pushShortcutItem(
        shortcut: ShortcutItem(
          id: id,
          action: action,
          shortLabel: shortLabel,
          icon: icon,
          shortcutIconAsset: iconAsset,
        ),
      );
      _logger?.log('Added shortcut: $id ($action)', level: 'DEBUG');
    } catch (e) {
      _logger?.log('Failed to add shortcut: $e', level: 'ERROR');
      rethrow;
    }
  }

  /// 更新现有快捷方式
  void updateShortcut({
    required String id,
    String? action,
    String? shortLabel,
    String? icon,
    ShortcutIconAsset? iconAsset,
  }) {
    try {
      FlutterShortcut.updateShortcutItem(
        shortcut: ShortcutItem(
          id: id,
          action: action ?? '',
          shortLabel: shortLabel ?? '',
          icon: icon,
          shortcutIconAsset: iconAsset ?? ShortcutIconAsset.flutterAsset,
        ),
      );
      _logger?.log('Updated shortcut: $id', level: 'DEBUG');
    } catch (e) {
      _logger?.log('Failed to update shortcut: $e', level: 'ERROR');
      rethrow;
    }
  }

  /// 批量设置快捷方式
  void setShortcuts(List<ShortcutItem> items) {
    try {
      FlutterShortcut.setShortcutItems(shortcutItems: items);
      _logger?.log('Set ${items.length} shortcuts', level: 'DEBUG');
    } catch (e) {
      _logger?.log('Failed to set shortcuts: $e', level: 'ERROR');
      rethrow;
    }
  }

  /// 清除所有快捷方式
  void clearShortcuts() {
    try {
      FlutterShortcut.clearShortcutItems();
      _logger?.log('Cleared all shortcuts', level: 'DEBUG');
    } catch (e) {
      _logger?.log('Failed to clear shortcuts: $e', level: 'ERROR');
      rethrow;
    }
  }
}
