import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'scripts_center_plugin.dart';
import 'models/script_info.dart';
import 'widgets/script_run_dialog.dart';
import 'package:get/get.dart';

/// 脚本中心插件的主页小组件注册
class ScriptsCenterHomeWidgets {
  /// 注册所有脚本中心插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'scripts_center_icon',
      pluginId: 'scripts_center',
      name: 'scripts_center_widgetName'.tr,
      description: 'scripts_center_widgetDescription'.tr,
      icon: Icons.code,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.code,
        color: Colors.deepPurple,
        name: 'scripts_center_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'scripts_center_overview',
      pluginId: 'scripts_center',
      name: 'scripts_center_overviewName'.tr,
      description: 'scripts_center_overviewDescription'.tr,
      icon: Icons.code_outlined,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));

    // 脚本快速执行小组件 - 选择器
    registry.register(HomeWidget(
      id: 'scripts_center_script_executor',
      pluginId: 'scripts_center',
      name: 'scripts_center_scriptExecutorName'.tr,
      description: 'scripts_center_scriptExecutorDescription'.tr,
      icon: Icons.play_circle_outline,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small, HomeWidgetSize.medium],
      category: 'home_categoryTools'.tr,
      selectorId: 'scripts_center.script',
      dataSelector: _extractScriptData,
      dataRenderer: _renderScriptData,
      navigationHandler: _executeScript,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('scripts_center_script_executor')!,
          config: config,
        );
      },
    ));
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractScriptData(List<dynamic> dataArray) {
    // dataArray 是选择器返回的选中项数组（单选模式只有一个元素）
    if (dataArray.isEmpty) {
      debugPrint('[ScriptSelector] dataArray 为空');
      return {};
    }

    final rawData = dataArray[0];
    debugPrint('[ScriptSelector] rawData 类型: ${rawData.runtimeType}');

    // 处理 Map 类型的数据
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    // 如果是 SelectableItem，从 rawData 字段提取
    if (rawData is Map && rawData.containsKey('rawData')) {
      final rawDataMap = rawData['rawData'];
      if (rawDataMap is Map<String, dynamic>) {
        return rawDataMap;
      }
    }

    debugPrint('[ScriptSelector] 无法提取数据: $rawData');
    return {};
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
      if (plugin == null) return [];

      final manager = plugin.scriptManager;
      final scripts = manager.scripts;
      final enabledCount = scripts.where((s) => s.enabled).length;
      final triggerCount = scripts.fold<int>(0, (sum, s) => sum + s.triggers.length);

      return [
        StatItemData(
          id: 'total_scripts',
          label: 'scripts_center_all'.tr,
          value: '${scripts.length}',
          highlight: scripts.isNotEmpty,
          color: Colors.deepPurple,
        ),
        StatItemData(
          id: 'enabled_scripts',
          label: 'scripts_center_enableScript'.tr,
          value: '$enabledCount',
          highlight: enabledCount > 0,
          color: Colors.green,
        ),
        StatItemData(
          id: 'total_triggers',
          label: 'scripts_center_addTrigger'.tr,
          value: '$triggerCount',
          highlight: triggerCount > 0,
          color: Colors.orange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'scripts_center',
        pluginName: 'scripts_center_name'.tr,
        pluginIcon: Icons.code,
        pluginDefaultColor: Colors.deepPurple,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }

  /// 渲染脚本数据（选择器小组件）
  static Widget _renderScriptData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final savedData = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};
    final scriptId = savedData['id'] as String? ?? '';
    final scriptName = savedData['name'] as String? ?? 'scripts_center_script'.tr;
    final scriptIconString = savedData['icon'] as String?;
    final hasInputs = savedData['hasInputs'] as bool? ?? false;

    return FutureBuilder<ScriptInfo?>(
      future: _loadLatestScript(scriptId),
      builder: (context, snapshot) {
        final script = snapshot.data;
        final displayName = script?.name ?? scriptName;
        final needsInputs = script?.hasInputs ?? hasInputs;
        final iconString = script?.icon ?? scriptIconString;
        final icon = _parseIcon(iconString);

        return _buildScriptWidget(
          context,
          displayName,
          needsInputs,
          icon,
        );
      },
    );
  }

  /// 解析图标字符串为 IconData
  static IconData _parseIcon(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return Icons.code;
    }

    // 尝试解析为十六进制数字（Material Icons codepoint）
    try {
      final codePoint = int.parse(iconString, radix: 16);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      // 解析失败，尝试图标名称映射
      return _iconNameMap[iconString] ?? Icons.code;
    }
  }

  /// 图标名称映射（常用图标）
  static const Map<String, IconData> _iconNameMap = {
    'code': Icons.code,
    'play_arrow': Icons.play_arrow,
    'play_circle': Icons.play_circle,
    'play_circle_outline': Icons.play_circle_outline,
    'settings': Icons.settings,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'notifications': Icons.notifications,
    'calendar_today': Icons.calendar_today,
    'schedule': Icons.schedule,
    'check_circle': Icons.check_circle,
    'error': Icons.error,
    'info': Icons.info,
    'warning': Icons.warning,
  };

  /// 从 scriptManager 加载最新脚本数据
  static Future<ScriptInfo?> _loadLatestScript(String scriptId) async {
    try {
      final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
      if (plugin == null || scriptId.isEmpty) return null;

      // 加载所有脚本并查找
      final scripts = await plugin.scriptManager.loadAllScripts();
      return scripts.firstWhere(
        (s) => s.id == scriptId,
        orElse: () => plugin.scriptManager.getScriptById(scriptId)!,
      );
    } catch (e) {
      debugPrint('加载脚本数据失败: $e');
      return null;
    }
  }

  /// 构建脚本执行小组件 UI
  static Widget _buildScriptWidget(
    BuildContext context,
    String scriptName,
    bool needsInputs,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间计算图标和文字大小
        final size = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final iconSize = size * 0.4;
        final fontSize = (size * 0.12).clamp(10.0, 14.0);
        final inputIconSize = iconSize * 0.3;

        return Center(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // 主内容：图标 + 名称
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: size * 0.05),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      scriptName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // 需要参数的提示图标
              if (needsInputs)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.input,
                      size: inputIconSize,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 执行脚本（点击处理器）
  static Future<void> _executeScript(
    BuildContext context,
    SelectorResult result,
  ) async {
    final data = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};

    final scriptId = data['id'] as String?;

    if (scriptId == null || scriptId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('scripts_center_scriptNotFound'.tr)),
      );
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
      if (plugin == null) return;

      // 加载脚本信息
      final scripts = await plugin.scriptManager.loadAllScripts();
      final script = scripts.firstWhere(
        (s) => s.id == scriptId,
        orElse: () => plugin.scriptManager.getScriptById(scriptId)!,
      );

      if (script.hasInputs) {
        // 显示参数输入对话框
        final navContext = navigatorKey.currentContext ?? context;
        final params = await showDialog<Map<String, dynamic>>(
          context: navContext,
          builder: (dialogContext) => ScriptRunDialog(
            script: script,
          ),
        );

        // 如果用户点击了取消，不执行脚本
        if (params == null) return;

        // 执行脚本并传递参数
        final execResult = await plugin.scriptExecutor.execute(
          script.id,
          args: params,
        );

        if (context.mounted) {
          if (execResult.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('scripts_center_scriptExecuted'.tr),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'scripts_center_scriptExecuteFailed'.tr}: ${execResult.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // 直接执行脚本
        final execResult = await plugin.scriptExecutor.execute(script.id);

        if (context.mounted) {
          if (execResult.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('scripts_center_scriptExecuted'.tr),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'scripts_center_scriptExecuteFailed'.tr}: ${execResult.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'scripts_center_scriptExecuteError'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
