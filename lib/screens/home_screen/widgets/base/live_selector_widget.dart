/// 实时数据选择器基类
///
/// 封装 StatefulBuilder + EventListenerContainer + FutureBuilder 模式
/// 适用于需要从 provider 实时获取数据的小组件
///
/// 子类只需实现：
/// - eventListeners: 事件监听列表
/// - getLiveData: 实时数据获取函数
/// - buildCommonWidget: 公共小组件构建器（可选）
/// - buildLoading/buildEmpty/buildError: 状态构建器（可覆盖）
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

/// 实时数据选择器基类
///
/// 封装以下重复逻辑：
/// - StatefulBuilder + EventListenerContainer + FutureBuilder 模式
/// - 实时数据获取
/// - Loading/Empty/Error 状态处理
/// - 公共小组件渲染（live data 优先）
/// - Props 合并（savedProps + liveData）
/// - Custom 尺寸处理
///
/// 子类只需实现：
/// - eventListeners: 事件监听列表
/// - getLiveData: 实时数据获取函数
/// - buildCommonWidget: 公共小组件构建器（默认使用 CommonWidgetBuilder）
/// - 状态构建方法可按需覆盖
abstract class LiveSelectorWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const LiveSelectorWidget({
    super.key,
    required this.config,
    required this.widgetDefinition,
  });

  /// 子类必须提供的事件监听列表
  List<String> get eventListeners;

  /// 子类必须提供的实时数据提供函数
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config);

  /// 子类必须提供的调试标签前缀
  String get widgetTag;

  /// 子类可以覆盖的公共小组件构建器
  /// 默认使用 CommonWidgetBuilder.build()
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

  /// 子类可以覆盖的加载状态构建器
  Widget buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 子类可以覆盖的空数据状态构建器
  Widget buildEmpty(BuildContext context) {
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
            Icon(
              Icons.info_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无数据',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 子类可以覆盖的错误状态构建器
  Widget buildError(BuildContext context, String message) {
    return HomeWidget.buildErrorWidget(context, message);
  }

  @override
  State<LiveSelectorWidget> createState() => _LiveSelectorWidgetState();
}

class _LiveSelectorWidgetState extends State<LiveSelectorWidget> {
  /// 缓存上一次的 config，用于检测变化
  Map<String, dynamic>? _lastConfig;

  @override
  void didUpdateWidget(covariant LiveSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当 config 改变时（例如 _pixelCategory 改变），需要触发重建
    if (widget.config != oldWidget.config) {
      _lastConfig = widget.config;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 StatefulBuilder + EventListenerContainer + FutureBuilder 模式
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: widget.eventListeners,
          onEvent: () => setState(() {}),
          child: FutureBuilder<Map<String, dynamic>>(
            future: widget.getLiveData(widget.config),
            builder: (context, snapshot) {
              // 加载状态
              if (snapshot.connectionState == ConnectionState.waiting) {
                return widget.buildLoading(context);
              }

              // 错误状态
              if (snapshot.hasError) {
                return widget.buildError(context, snapshot.error.toString());
              }

              // 空数据状态
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return widget.buildEmpty(context);
              }

              // 使用实时数据渲染
              return _buildWithLiveData(context, snapshot.data!);
            },
          ),
        );
      },
    );
  }

  /// 使用实时数据构建组件
  Widget _buildWithLiveData(
    BuildContext context,
    Map<String, dynamic> liveData,
  ) {
    final widgetDefinition = widget.widgetDefinition;
    final config = widget.config;

    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[${widget.widgetTag}] 解析配置失败: $e');
    }

    // 获取小组件尺寸
    final size = config['widgetSize'] as HomeWidgetSize? ??
        widgetDefinition.defaultSize;

    // 检查是否使用公共小组件
    if (selectorConfig?.usesCommonWidget == true) {
      return _buildCommonWidget(
        context,
        selectorConfig!,
        liveData,
        size,
      );
    }

    // 使用 dataRenderer 渲染
    if (widgetDefinition.dataRenderer != null) {
      return _buildWithDataRenderer(context, config, size, selectorConfig);
    }

    // 没有公共小组件也没有 dataRenderer，显示错误
    return HomeWidget.buildErrorWidget(context, '未配置渲染方式');
  }

  /// 构建公共小组件（使用实时数据）
  Widget _buildCommonWidget(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
    Map<String, dynamic> liveData,
    HomeWidgetSize size,
  ) {
    final commonWidgetId = selectorConfig.commonWidgetId!;

    // 将字符串 ID 转换为枚举值
    final commonWidgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
    if (commonWidgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
    }

    // 使用实时数据（从 liveData 中获取对应的小组件数据）
    final widgetData = liveData[commonWidgetId] as Map<String, dynamic>?;

    if (widgetData == null) {
      return HomeWidget.buildErrorWidget(context, '数据不存在');
    }

    // 合并保存的配置和实时数据（实时数据优先覆盖保存的配置）
    final mergedProps = _mergeProps(
      selectorConfig.commonWidgetProps ?? {},
      widgetData,
    );

    // 添加 custom 尺寸的实际宽高到 props 中
    final finalProps = Map<String, dynamic>.from(mergedProps);
    if (size == const CustomSize(width: -1, height: -1)) {
      finalProps['customWidth'] = widget.config['customWidth'] as int?;
      finalProps['customHeight'] = widget.config['customHeight'] as int?;
    }

    // 传递 _pixelCategory 以支持响应式布局
    // 从 widget.config 中获取 _pixelCategory（由 HomeCard 注入）
    final pixelCategory = widget.config['_pixelCategory'] as SizeCategory?;
    if (pixelCategory != null) {
      finalProps['_pixelCategory'] = pixelCategory;
    }

    return widget.buildCommonWidget(
      context,
      commonWidgetIdEnum,
      finalProps,
      size,
    );
  }

  /// 使用 dataRenderer 渲染
  Widget _buildWithDataRenderer(
    BuildContext context,
    Map<String, dynamic> config,
    HomeWidgetSize size,
    SelectorWidgetConfig? selectorConfig,
  ) {
    final originalResult = selectorConfig?.toSelectorResult();
    if (originalResult == null) {
      return HomeWidget.buildErrorWidget(context, '无法解析选择的数据');
    }

    // 如果有 dataSelector，使用它转换数据
    var result = originalResult;
    if (widget.widgetDefinition.dataSelector != null && originalResult.data is List) {
      final dataArray = originalResult.data as List<dynamic>;
      final transformedData = widget.widgetDefinition.dataSelector!(dataArray);
      result = SelectorResult(
        pluginId: originalResult.pluginId,
        selectorId: originalResult.selectorId,
        path: originalResult.path,
        data: transformedData,
      );
    }

    // 将 widgetSize 注入 config
    final effectiveConfig = {
      ...config,
      'widgetSize': size,
    };

    try {
      return widget.widgetDefinition.dataRenderer!(context, result, effectiveConfig);
    } catch (e) {
      debugPrint('[${widget.widgetTag}] dataRenderer 失败: $e');
      return HomeWidget.buildErrorWidget(context, '渲染失败');
    }
  }

  /// 合并保存的配置和实时数据
  ///
  /// 实时数据优先覆盖保存的配置
  Map<String, dynamic> _mergeProps(
    Map<String, dynamic> savedProps,
    Map<String, dynamic> liveData,
  ) {
    return {
      ...savedProps,
      ...liveData,
    };
  }
}
