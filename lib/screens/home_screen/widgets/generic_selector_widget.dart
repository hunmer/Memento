import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

/// 通用选择器小组件
///
/// 用于显示通过数据选择器配置的小组件
/// 支持两种状态：
/// 1. 未配置：显示"点击配置"占位提示
/// 2. 已配置：使用 dataRenderer 渲染选择的数据
///
/// 注意：此组件不处理点击事件，点击事件由 HomeCard 处理
class GenericSelectorWidget extends StatelessWidget {
  /// 小组件定义
  final HomeWidget widgetDefinition;

  /// 小组件配置
  final Map<String, dynamic> config;

  const GenericSelectorWidget({
    super.key,
    required this.widgetDefinition,
    required this.config,
  });

  /// 获取包含widgetSize的有效配置
  Map<String, dynamic> _getEffectiveConfig(Map<String, dynamic> baseConfig) {
    // 如果config中已有widgetSize，直接返回
    if (baseConfig.containsKey('widgetSize')) {
      return baseConfig;
    }

    // 使用默认尺寸
    return {...baseConfig, 'widgetSize': widgetDefinition.defaultSize};
  }

  @override
  Widget build(BuildContext context) {
    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[GenericSelectorWidget] 解析配置失败: $e');
    }

    // 判断是否已配置
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      return _buildUnconfiguredWidget(context);
    }

    // 检查是否有公共小组件配置
    if (selectorConfig.usesCommonWidget) {
      return _buildCommonWidget(context, selectorConfig);
    }

    // 恢复 SelectorResult
    final originalResult = selectorConfig.toSelectorResult();
    if (originalResult == null) {
      return _buildErrorWidget(context, '无法解析选择的数据');
    }

    // 如果提供了 dataSelector，使用它转换数据
    final result = _transformResult(originalResult);

    // 使用 dataRenderer 渲染数据
    if (widgetDefinition.dataRenderer != null) {
      try {
        // 将widgetSize注入config
        final effectiveConfig = _getEffectiveConfig(config);
        return widgetDefinition.dataRenderer!(context, result, effectiveConfig);
      } catch (e) {
        debugPrint('[GenericSelectorWidget] dataRenderer 失败: $e');
        return _buildErrorWidget(context, '渲染失败');
      }
    }

    // 如果未提供 dataRenderer，显示默认视图
    return _buildDefaultConfiguredWidget(context, result);
  }

  /// 转换 SelectorResult，使用 dataSelector 处理数据
  SelectorResult _transformResult(SelectorResult original) {
    // 如果有 dataSelector 函数，使用它转换数据数组
    debugPrint(
      '[GenericSelectorWidget] dataSelector: ${widgetDefinition.dataSelector}',
    );
    debugPrint(
      '[GenericSelectorWidget] original.data: ${original.data} (isList: ${original.data is List})',
    );

    if (widgetDefinition.dataSelector != null && original.data is List) {
      final dataArray = original.data as List<dynamic>;
      final transformedData = widgetDefinition.dataSelector!(dataArray);
      debugPrint(
        '[GenericSelectorWidget] transformedData: $transformedData (isMap: ${transformedData is Map<String, dynamic>})',
      );

      return SelectorResult(
        pluginId: original.pluginId,
        selectorId: original.selectorId,
        path: original.path,
        data: transformedData,
      );
    }

    // 默认行为：将数组转换为合并的 Map
    if (original.data is List) {
      final dataArray = original.data as List<dynamic>;
      final mergedData = <String, dynamic>{};

      for (final item in dataArray) {
        if (item is Map<String, dynamic>) {
          mergedData.addAll(item);
        }
      }

      return SelectorResult(
        pluginId: original.pluginId,
        selectorId: original.selectorId,
        path: original.path,
        data: mergedData,
      );
    }

    return original;
  }

  /// 构建公共小组件
  Widget _buildCommonWidget(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
  ) {
    try {
      final widgetId = selectorConfig.commonWidgetId!;
      final props = selectorConfig.commonWidgetProps!;
      final size = config['widgetSize'] as HomeWidgetSize? ??
          widgetDefinition.defaultSize;

      // 获取 widgetItem.id 作为 key，确保小组件被正确创建并触发 initState
      final widgetItemId = config['_widgetItemId'] as String?;

      // 将字符串 ID 转换为枚举值
      final commonWidgetId = CommonWidgetsRegistry.fromString(widgetId);
      if (commonWidgetId == null) {
        return _buildErrorWidget(context, '未知的公共组件: $widgetId');
      }

      final child = CommonWidgetBuilder.build(
        context,
        commonWidgetId,
        props,
        size,
      );

      // 使用 widgetItemId 作为 key，确保每个小组件实例都是唯一的
      // 这样当小组件被添加或替换时，Flutter 会创建新的组件实例并触发 initState
      if (widgetItemId != null) {
        return KeyedSubtree(
          key: ValueKey(widgetItemId),
          child: child,
        );
      }

      return child;
    } catch (e) {
      debugPrint('[GenericSelectorWidget] 构建公共组件失败: $e');
      return _buildErrorWidget(context, '渲染公共组件失败');
    }
  }

  /// 构建未配置状态的占位小组件
  Widget _buildUnconfiguredWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '点击配置',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建默认的已配置视图（当未提供 dataRenderer 时）
  Widget _buildDefaultConfiguredWidget(
    BuildContext context,
    SelectorResult result,
  ) {
    final theme = Theme.of(context);
    final color = widgetDefinition.color ?? theme.colorScheme.primary;

    // 尝试从 result.data 获取标题
    String title = '已配置';
    String? subtitle;

    if (result.data is Map) {
      final dataMap = result.data as Map;
      title = dataMap['title']?.toString() ?? title;
      subtitle = dataMap['subtitle']?.toString() ?? dataMap['url']?.toString();
    } else if (result.path.isNotEmpty) {
      title = result.path.last.selectedItem.title;
      subtitle = result.path.last.selectedItem.subtitle;
    }

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widgetDefinition.icon, size: 24, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widgetDefinition.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建错误状态的小组件
  Widget _buildErrorWidget(BuildContext context, String message) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
