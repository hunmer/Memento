import 'package:flutter/material.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';
import 'package:Memento/core/event/event.dart';

class ShortcutEventArgs extends EventArgs {
  final String action;
  ShortcutEventArgs({required this.action}) : super(action);
}

/// 管理应用程序快捷方式的全局服务
class AppShortcutManager {
  static final AppShortcutManager _instance = AppShortcutManager._internal();
  factory AppShortcutManager() => _instance;
  AppShortcutManager._internal();

  /// 初始化快捷方式监听
  void initialize() {
    try {
      FlutterShortcut.initialize(debug: true);
      FlutterShortcut.listenAction((action) {
        debugPrint('Shortcut action received: $action');
        eventManager.broadcast(
          'shortcut_action',
          ShortcutEventArgs(action: action),
        );
      });
      // FlutterShortcut.setShortcutItems(
      //   shortcutItems: <ShortcutItem>[
      //     const ShortcutItem(
      //       id: "1",
      //       action: 'shortcut.scan',
      //       shortLabel: 'Scan code',
      //       icon: 'assets/icon/icon.png',
      //     ),
      //     const ShortcutItem(
      //       id: "2",
      //       action: 'shortcut.messages',
      //       shortLabel: 'Messages',
      //       icon: "messages",
      //       shortcutIconAsset: ShortcutIconAsset.nativeAsset,
      //     ),
      //   ],
      // );
      eventManager.subscribe('shortcut_action', _handleAction);
    } catch (e) {
      debugPrint('Failed to initialize shortcut listener: $e');
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
        debugPrint('Unknown shortcut action: $action');
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
      debugPrint('Added shortcut: $id ($action)');
    } catch (e) {
      debugPrint('Failed to add shortcut: $e');
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
      debugPrint('Updated shortcut: $id');
    } catch (e) {
      debugPrint('Failed to update shortcut: $e');
      rethrow;
    }
  }

  /// 批量设置快捷方式
  void setShortcuts(List<ShortcutItem> items) {
    try {
      FlutterShortcut.setShortcutItems(shortcutItems: items);
      debugPrint('Set ${items.length} shortcuts');
    } catch (e) {
      debugPrint('Failed to set shortcuts: $e');
      rethrow;
    }
  }

  /// 清除所有快捷方式
  void clearShortcuts() {
    try {
      FlutterShortcut.clearShortcutItems();
      debugPrint('Cleared all shortcuts');
    } catch (e) {
      debugPrint('Failed to clear shortcuts: $e');
      rethrow;
    }
  }
}
