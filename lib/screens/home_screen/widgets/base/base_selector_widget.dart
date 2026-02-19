/// 选择器小组件基类
///
/// 封装了以下重复逻辑：
/// - 配置解析（SelectorWidgetConfig）
/// - 未配置状态处理
/// - EventListenerContainer 包装
/// - 公共小组件渲染（优先使用 savedProps，不依赖 availableWidgets）
/// - Custom 尺寸处理
///
/// 子类只需实现：
/// - eventListeners: 事件监听列表
/// - widgetTag: 调试标签前缀
/// - buildDefaultWidget: 默认视图（非公共小组件时）
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

/// 选择模式枚举
enum SelectionMode {
  single,   // 单选
  multiple,  // 多选
}

/// 选择器小组件基类
abstract class BaseSelectorWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const BaseSelectorWidget({
    super.key,
    required this.config,
    required this.widgetDefinition,
  });

  /// 子类必须提供的事件监听列表
  List<String> get eventListeners;

  /// 子类必须提供的调试标签前缀
  String get widgetTag;

  /// 子类必须实现的默认视图构建器
  /// 当未使用公共小组件时调用
  Widget buildDefaultWidget(BuildContext context, SelectorResult result);

  /// 单选还是多选（默认为单选）
  SelectionMode get selectionMode => SelectionMode.single;

  @override
  State<BaseSelectorWidget> createState() => _BaseSelectorWidgetState();
}

class _BaseSelectorWidgetState extends State<BaseSelectorWidget> {
  SelectorWidgetConfig? _selectorConfig;

  @override
  void initState() {
    super.initState();
    _parseSelectorConfig();
  }

  /// 解析选择器配置
  void _parseSelectorConfig() {
    try {
      if (widget.config.containsKey('selectorWidgetConfig')) {
        _selectorConfig = SelectorWidgetConfig.fromJson(
          widget.config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[${widget.widgetTag}] 解析配置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 解析选择器配置
    if (_selectorConfig == null) {
      _parseSelectorConfig();
    }

    // 未配置状态
    if (_selectorConfig == null || !_selectorConfig!.isConfigured) {
      return HomeWidget.buildUnconfiguredWidget(context);
    }

    // 检查是否使用了公共小组件
    if (_selectorConfig!.usesCommonWidget) {
      return _buildCommonWidget(context, _selectorConfig!);
    }

    // 默认视图
    final originalResult = _selectorConfig!.toSelectorResult();
    if (originalResult == null) {
      return HomeWidget.buildErrorWidget(context, '无法解析选择的数据');
    }

    // 子类需要实现 buildDefaultWidget 方法
    return EventListenerContainer(
      events: widget.eventListeners,
      onEvent: () => setState(() {}),
      child: widget.buildDefaultWidget(context, originalResult),
    );
  }

  /// 构建公共小组件
  Widget _buildCommonWidget(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
  ) {
    final commonWidgetId = selectorConfig.commonWidgetId!;
    final size =
        widget.config['widgetSize'] as HomeWidgetSize? ??
        widget.widgetDefinition.defaultSize;

    // 获取元数据
    final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
    }

    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

    return EventListenerContainer(
      events: widget.eventListeners,
      onEvent: () => setState(() {}),
      child: _buildCommonWidgetContent(
        context,
        selectorConfig,
        widgetIdEnum,
        size,
        metadata,
      ),
    );
  }

  /// 构建公共小组件内容（使用保存的 props，不依赖 availableWidgets）
  Widget _buildCommonWidgetContent(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
    CommonWidgetId widgetIdEnum,
    HomeWidgetSize size,
    CommonWidgetMetadata metadata,
  ) {
    // 优先使用保存的 commonWidgetProps
    if (selectorConfig.commonWidgetProps != null) {
      final props = Map<String, dynamic>.from(selectorConfig.commonWidgetProps!);
      _addCustomSizeProps(props, size);
      return CommonWidgetBuilder.build(
        context,
        widgetIdEnum,
        props,
        size,
        inline: true,
      );
    }

    // 如果没有保存的 props，尝试动态获取（兼容旧数据）
    final selectedData = selectorConfig.selectedData;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取选择的数据');
    }

    // 从 selectedData 中提取实际的数据
    Map<String, dynamic> data = _extractDataFromSelectedData(selectedData);

    if (widget.widgetDefinition.commonWidgetsProvider != null) {
      return FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: widget.widgetDefinition.commonWidgetsProvider!(data),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return HomeWidget.buildErrorWidget(context, '加载组件数据失败');
          }

          final availableWidgets = snapshot.data ?? {};
          final latestProps = availableWidgets[widgetIdEnum.name];

          if (latestProps == null) {
            return HomeWidget.buildErrorWidget(
              context,
              '未知的公共组件类型: ${widgetIdEnum.name}',
            );
          }

          final props = Map<String, dynamic>.from(latestProps);
          _addCustomSizeProps(props, size);
          return CommonWidgetBuilder.build(
            context,
            widgetIdEnum,
            props,
            size,
            inline: true,
          );
        },
      );
    }

    return HomeWidget.buildErrorWidget(context, '无法加载组件数据');
  }

  /// 从 selectedData 中提取数据（根据单选/多选模式）
  Map<String, dynamic> _extractDataFromSelectedData(
    Map<String, dynamic> selectedData,
  ) {
    if (!selectedData.containsKey('data')) {
      return {};
    }

    final dataArray = selectedData['data'];
    if (dataArray is! List || dataArray.isEmpty) {
      return {};
    }

    if (widget.selectionMode == SelectionMode.single) {
      // 单选模式：返回 dataArray[0]
      final rawData = dataArray[0];
      if (rawData is Map<String, dynamic>) {
        return rawData;
      } else if (rawData != null && rawData is Map) {
        return Map<String, dynamic>.from(rawData);
      }
      return {};
    } else {
      // 多选模式：返回 {'items': dataArray}
      return {'items': List<Map<String, dynamic>>.from(dataArray)};
    }
  }

  /// 添加自定义尺寸的 props
  void _addCustomSizeProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    if (size == const CustomSize(width: -1, height: -1)) {
      props['customWidth'] = widget.config['customWidth'] as int?;
      props['customHeight'] = widget.config['customHeight'] as int?;
    }
  }
}
