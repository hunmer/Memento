/// 脚本中心插件 - 脚本列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.colorfulShortcutsGrid;

/// 脚本快捷方式颜色映射（根据脚本ID生成一致的背景色）
List<int> _scriptColors = [
  0xFF6366F1, // Indigo
  0xFF8B5CF6, // Violet
  0xFFEC4899, // Pink
  0xFFF43F5E, // Rose
  0xFF14B8A6, // Teal
  0xFFF59E0B, // Amber
  0xFF3B82F6, // Blue
  0xFF10B981, // Emerald
];

/// 获取脚本颜色（根据脚本ID哈希值生成）
int _getScriptColor(String scriptId) {
  final hash = scriptId.hashCode;
  return _scriptColors[hash.abs() % _scriptColors.length];
}

/// 图标名称映射（将脚本图标映射到 Material Icons）
IconData _mapScriptIcon(String iconName) {
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
    default:
      return Icons.code;
  }
}

/// 将脚本列表转换为 ColorfulShortcutsGrid 数据格式
Map<String, dynamic> _provideScriptsGridData() {
  try {
    final plugin = PluginManager.instance.getPlugin('scripts_center');
    if (plugin == null) {
      debugPrint('[ScriptsListWidget] scripts_center 插件未注册');
      return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
    }

    // 使用反射访问 scriptManager
    final scriptManager = (plugin as dynamic).scriptManager;
    if (scriptManager == null) {
      debugPrint('[ScriptsListWidget] scriptManager 为 null');
      return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
    }

    final scripts = scriptManager?.scripts as List<dynamic>? ?? [];
    debugPrint('[ScriptsListWidget] 获取到 ${scripts.length} 个脚本');

    // 转换脚本为快捷方式数据
    final shortcuts = <Map<String, dynamic>>[];
    for (final script in scripts) {
      final scriptInfo = script as dynamic;
      final scriptId = scriptInfo.id as String;
      final name = scriptInfo.name as String;
      final iconName = scriptInfo.icon as String? ?? 'code';
      final iconData = _mapScriptIcon(iconName);

      // 获取图标名称字符串
      String iconString = 'code';
      if (iconData == Icons.play_arrow) {
        iconString = 'play_arrow';
      } else if (iconData == Icons.settings) {
        iconString = 'settings';
      } else if (iconData == Icons.notifications) {
        iconString = 'notification';
      } else if (iconData == Icons.storage) {
        iconString = 'database';
      } else if (iconData == Icons.cloud) {
        iconString = 'cloud';
      } else if (iconData == Icons.smartphone) {
        iconString = 'smartphone';
      } else if (iconData == Icons.schedule) {
        iconString = 'schedule';
      } else if (iconData == Icons.event) {
        iconString = 'event';
      } else if (iconData == Icons.chat) {
        iconString = 'chat_bubble';
      } else if (iconData == Icons.email) {
        iconString = 'mail';
      } else if (iconData == Icons.share) {
        iconString = 'send';
      } else if (iconData == Icons.search) {
        iconString = 'search';
      } else if (iconData == Icons.filter_list) {
        iconString = 'collections';
      } else if (iconData == Icons.sort) {
        iconString = 'sort';
      } else if (iconData == Icons.add) {
        iconString = 'add';
      } else if (iconData == Icons.edit) {
        iconString = 'edit';
      } else if (iconData == Icons.delete) {
        iconString = 'delete';
      } else if (iconData == Icons.star) {
        iconString = 'star';
      } else if (iconData == Icons.favorite) {
        iconString = 'favorite';
      } else if (iconData == Icons.check) {
        iconString = 'check';
      } else if (iconData == Icons.close) {
        iconString = 'close';
      } else if (iconData == Icons.arrow_forward) {
        iconString = 'send';
      } else if (iconData == Icons.home) {
        iconString = 'home';
      } else if (iconData == Icons.apps) {
        iconString = 'collections';
      } else if (iconData == Icons.dashboard) {
        iconString = 'dashboard';
      } else if (iconData == Icons.analytics) {
        iconString = 'analytics';
      }

      shortcuts.add({
        'iconName': iconString,
        'label': name,
        'color': _getScriptColor(scriptId),
      });
    }

    // 根据脚本数量决定列数
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
    debugPrint('[ScriptsListWidget] 提供数据失败: $e');
    return {'shortcuts': <Map<String, dynamic>>[], 'columns': 2};
  }
}

/// 公共小组件数据提供者
class ScriptsCenterWidgetsProvider {
  /// 提供公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final gridData = _provideScriptsGridData();
    debugPrint('[ScriptsListWidget] provideCommonWidgets 返回数据: ${gridData.keys.toList()}');
    return {'colorfulShortcutsGrid': gridData};
  }
}

/// 脚本列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 colorfulShortcutsGrid 公共小组件，支持实时更新
class _ScriptsListLiveWidget extends LiveSelectorWidget {
  const _ScriptsListLiveWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'script_added',
    'script_deleted',
    'script_updated',
    'script_enabled',
    'script_disabled',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    // 直接返回完整的 provider 数据（Map<String, Map<String, dynamic>>）
    // LiveSelectorWidget 会根据 commonWidgetId 从中提取对应的数据
    return await ScriptsCenterWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'ScriptsListWidget';

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

/// 注册脚本列表小组件（公共小组件，使用 ColorfulShortcutsGrid）
void registerScriptsListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'scripts_list',
      pluginId: 'scripts_center',
      name: 'scripts_center_scriptsListWidgetName'.tr,
      description: 'scripts_center_scriptsListWidgetDesc'.tr,
      icon: Icons.grid_view,
      color: Colors.deepPurple,
      defaultSize: const Large3Size(),
      supportedSizes: const [Large3Size(), LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return ScriptsCenterWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _ScriptsListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('scripts_list')!,
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
