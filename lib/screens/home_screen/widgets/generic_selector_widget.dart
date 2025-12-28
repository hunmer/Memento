import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

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

    // 恢复 SelectorResult
    final result = selectorConfig.toSelectorResult();
    if (result == null) {
      return _buildErrorWidget(context, '无法解析选择的数据');
    }

    // 使用 dataRenderer 渲染数据
    if (widgetDefinition.dataRenderer != null) {
      try {
        return widgetDefinition.dataRenderer!(context, result, config);
      } catch (e) {
        debugPrint('[GenericSelectorWidget] dataRenderer 失败: $e');
        return _buildErrorWidget(context, '渲染失败');
      }
    }

    // 如果未提供 dataRenderer，显示默认视图
    return _buildDefaultConfiguredWidget(context, result);
  }

  /// 构建未配置状态的占位小组件
  Widget _buildUnconfiguredWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 4),
            Text(
              widgetDefinition.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
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
