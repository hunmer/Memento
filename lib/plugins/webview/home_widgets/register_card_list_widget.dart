/// WebView插件 - 网址列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/webview/models/webview_card.dart';

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.colorfulShortcutsGrid;

/// 网址快捷方式颜色映射（根据卡片ID生成一致的背景色）
List<int> _cardColors = [
  0xFF4285F4, // Google Blue
  0xFFEA4335, // Google Red
  0xFFFBBC05, // Google Yellow
  0xFF34A853, // Google Green
  0xFF6366F1, // Indigo
  0xFF8B5CF6, // Violet
  0xFFEC4899, // Pink
  0xFFF43F5E, // Rose
  0xFF14B8A6, // Teal
  0xFFF59E0B, // Amber
  0xFF3B82F6, // Blue
  0xFF10B981, // Emerald
  0xFF8B4513, // SaddleBrown
  0xFF4682B4, // SteelBlue
  0xFF2E8B57, // SeaGreen
];

/// 获取卡片颜色（根据卡片ID哈希值生成）
int _getCardColor(String cardId) {
  final hash = cardId.hashCode;
  return _cardColors[hash.abs() % _cardColors.length];
}

/// 图标名称映射（将卡片图标映射到 Material Icons）
IconData _mapCardIcon(String? iconName, CardType cardType) {
  // 如果卡片有自定义图标，优先使用
  if (iconName != null && iconName.isNotEmpty) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'settings':
        return Icons.settings;
      case 'notification':
        return Icons.notifications;
      case 'database':
        return Icons.storage;
      case 'cloud':
        return Icons.cloud;
      case 'smartphone':
        return Icons.smartphone;
      case 'schedule':
        return Icons.schedule;
      case 'event':
        return Icons.event;
      case 'chat':
        return Icons.chat;
      case 'email':
        return Icons.email;
      case 'share':
        return Icons.share;
      case 'search':
        return Icons.search;
      case 'filter':
        return Icons.filter_list;
      case 'sort':
        return Icons.sort;
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'home':
        return Icons.home;
      case 'apps':
        return Icons.apps;
      case 'dashboard':
        return Icons.dashboard;
      case 'analytics':
        return Icons.analytics;
    }
  }

  // 根据卡片类型返回默认图标
  return cardType == CardType.localFile ? Icons.folder : Icons.language;
}

/// 图标名称映射（将 IconData 映射到字符串）
String _mapIconDataToString(IconData iconData) {
  // Material Icons 名称映射
  if (iconData == Icons.language) return 'language';
  if (iconData == Icons.folder) return 'folder';
  if (iconData == Icons.code) return 'code';
  if (iconData == Icons.play_arrow) return 'play_arrow';
  if (iconData == Icons.settings) return 'settings';
  if (iconData == Icons.notifications) return 'notification';
  if (iconData == Icons.storage) return 'database';
  if (iconData == Icons.cloud) return 'cloud';
  if (iconData == Icons.smartphone) return 'smartphone';
  if (iconData == Icons.schedule) return 'schedule';
  if (iconData == Icons.event) return 'event';
  if (iconData == Icons.chat) return 'chat_bubble';
  if (iconData == Icons.email) return 'mail';
  if (iconData == Icons.share) return 'send';
  if (iconData == Icons.search) return 'search';
  if (iconData == Icons.filter_list) return 'collections';
  if (iconData == Icons.sort) return 'sort';
  if (iconData == Icons.add) return 'add';
  if (iconData == Icons.edit) return 'edit';
  if (iconData == Icons.delete) return 'delete';
  if (iconData == Icons.star) return 'star';
  if (iconData == Icons.favorite) return 'favorite';
  if (iconData == Icons.check) return 'check';
  if (iconData == Icons.close) return 'close';
  if (iconData == Icons.arrow_forward) return 'send';
  if (iconData == Icons.home) return 'home';
  if (iconData == Icons.apps) return 'collections';
  if (iconData == Icons.dashboard) return 'dashboard';
  if (iconData == Icons.analytics) return 'analytics';

  return 'language';
}

/// 将网址列表转换为 ColorfulShortcutsGrid 数据格式
Map<String, dynamic> _provideCardsGridData() {
  try {
    final plugin = PluginManager.instance.getPlugin('webview');
    if (plugin == null) {
      debugPrint('[CardListWidget] webview 插件未注册');
      return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
    }

    // 使用反射访问 cardManager
    final cardManager = (plugin as dynamic).cardManager;
    if (cardManager == null) {
      debugPrint('[CardListWidget] cardManager 为 null');
      return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
    }

    final cards = cardManager?.cards as List<dynamic>? ?? [];
    debugPrint('[CardListWidget] 获取到 ${cards.length} 个网址卡片');

    // 转换卡片为快捷方式数据
    final shortcuts = <Map<String, dynamic>>[];
    for (final card in cards) {
      final cardInfo = card as dynamic;
      final cardId = cardInfo.id as String;
      final title = cardInfo.title as String;
      final type = cardInfo.type as CardType;

      // 获取图标
      final iconData = _mapCardIcon(
        cardInfo.iconCodePoint != null
            ? _getIconNameByCodePoint(cardInfo.iconCodePoint as int)
            : null,
        type,
      );
      final iconString = _mapIconDataToString(iconData);

      shortcuts.add({
        'iconName': iconString,
        'label': title,
        'color': _getCardColor(cardId),
      });
    }

    // 根据卡片数量决定列数
    int columns = 2;
    if (shortcuts.length <= 2) {
      columns = 2;
    } else if (shortcuts.length <= 4) {
      columns = 2;
    } else if (shortcuts.length <= 6) {
      columns = 3;
    } else {
      columns = 4;
    }

    return {
      'shortcuts': shortcuts,
      'columns': columns,
      'itemHeight': 100.0,
      'spacing': 14.0,
      'borderRadius': 40.0,
    };
  } catch (e) {
    debugPrint('[CardListWidget] 提供数据失败: $e');
    return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
  }
}

/// 根据 iconCodePoint 获取图标名称
String? _getIconNameByCodePoint(int codePoint) {
  // 常用图标码点映射
  if (codePoint == Icons.language.codePoint) return 'language';
  if (codePoint == Icons.folder.codePoint) return 'folder';
  if (codePoint == Icons.code.codePoint) return 'code';
  if (codePoint == Icons.play_arrow.codePoint) return 'play_arrow';
  if (codePoint == Icons.settings.codePoint) return 'settings';
  if (codePoint == Icons.notifications.codePoint) return 'notification';
  if (codePoint == Icons.storage.codePoint) return 'database';
  if (codePoint == Icons.cloud.codePoint) return 'cloud';
  if (codePoint == Icons.smartphone.codePoint) return 'smartphone';
  if (codePoint == Icons.schedule.codePoint) return 'schedule';
  if (codePoint == Icons.event.codePoint) return 'event';
  if (codePoint == Icons.chat_bubble.codePoint) return 'chat_bubble';
  if (codePoint == Icons.mail.codePoint) return 'mail';
  if (codePoint == Icons.send.codePoint) return 'send';
  if (codePoint == Icons.search.codePoint) return 'search';
  if (codePoint == Icons.collections.codePoint) return 'collections';
  if (codePoint == Icons.sort.codePoint) return 'sort';
  if (codePoint == Icons.add.codePoint) return 'add';
  if (codePoint == Icons.edit.codePoint) return 'edit';
  if (codePoint == Icons.delete.codePoint) return 'delete';
  if (codePoint == Icons.star.codePoint) return 'star';
  if (codePoint == Icons.favorite.codePoint) return 'favorite';
  if (codePoint == Icons.check.codePoint) return 'check';
  if (codePoint == Icons.close.codePoint) return 'close';
  if (codePoint == Icons.home.codePoint) return 'home';
  if (codePoint == Icons.dashboard.codePoint) return 'dashboard';
  if (codePoint == Icons.analytics.codePoint) return 'analytics';
  return null;
}

/// 公共小组件数据提供者
class WebViewWidgetsProvider {
  /// 提供公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final gridData = _provideCardsGridData();
    debugPrint('[CardListWidget] provideCommonWidgets 返回数据: ${gridData.keys.toList()}');
    return {'colorfulShortcutsGrid': gridData};
  }
}

/// 网址列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 colorfulShortcutsGrid 公共小组件，支持实时更新
class _CardListLiveWidget extends LiveSelectorWidget {
  const _CardListLiveWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'card_added',
    'card_deleted',
    'card_updated',
    'card_toggled_pinned',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    // 直接返回完整的 provider 数据（Map<String, Map<String, dynamic>>）
    // LiveSelectorWidget 会根据 commonWidgetId 从中提取对应的数据
    return await WebViewWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'CardListWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 注册网址列表小组件（公共小组件，使用 ColorfulShortcutsGrid）
void registerCardListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'webview_card_list',
      pluginId: 'webview',
      name: 'webview_cardListWidgetName'.tr,
      description: 'webview_cardListWidgetDesc'.tr,
      icon: Icons.grid_view,
      color: const Color(0xFF4285F4), // Google Blue
      defaultSize: const Large3Size(),
      supportedSizes: const [Large3Size(), LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return WebViewWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _CardListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('webview_card_list')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(Map<String, dynamic> config) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': defaultWidgetType.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
