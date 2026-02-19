import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/models/home_stack_item.dart';
import 'package:Memento/screens/home_screen/models/widget_grid_metrics.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/widget_grid_scope.dart';
import 'package:Memento/plugins/diary/utils/diary_utils.dart';
import 'package:Memento/plugins/diary/screens/diary_editor_screen.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'folder_dialog.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

/// 主页卡片组件
///
/// 显示一个小组件或文件夹的卡片，支持 OpenContainer 风格的页面转场动画
class HomeCard extends StatefulWidget {
  final HomeItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isEditMode;
  final bool isBatchMode;
  final Widget? dragHandle;

  const HomeCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isEditMode = false,
    this.isBatchMode = false,
    this.dragHandle,
  });

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  /// 用于 OpenContainer 动画的 GlobalKey
  final GlobalKey _cardKey = GlobalKey();

  /// 缓存上一次的网格尺寸，用于检测变化
  WidgetGridMetrics? _lastMetrics;

  /// 标记是否已经初始化
  bool _initialized = false;

  HomeItem get item => widget.item;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onLongPress => widget.onLongPress;
  bool get isSelected => widget.isSelected;
  bool get isEditMode => widget.isEditMode;
  bool get isBatchMode => widget.isBatchMode;
  Widget? get dragHandle => widget.dragHandle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查网格尺寸是否变化
    final metrics = WidgetGridScope.maybeOf(context);

    // 第一次初始化时，只缓存 metrics，不触发重建
    if (!_initialized) {
      _lastMetrics = metrics;
      _initialized = true;
      if (metrics != null) {
        debugPrint('[HomeCard] 🔄 首次初始化: itemId=${widget.item.id.substring(0, 8)}..., '
            'cellWidth=${metrics.cellWidth.toStringAsFixed(1)}');
      }
      return;
    }

    // 后续变化时，如果 metrics 变化了，触发重建
    if (metrics != _lastMetrics) {
      debugPrint('[HomeCard] 🔄 检测到网格尺寸变化: itemId=${widget.item.id.substring(0, 8)}...');
      if (metrics != null && _lastMetrics != null) {
        debugPrint('[HomeCard]    旧: cellWidth=${_lastMetrics!.cellWidth.toStringAsFixed(1)}');
        debugPrint('[HomeCard]    新: cellWidth=${metrics.cellWidth.toStringAsFixed(1)}');
      }
      _lastMetrics = metrics;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeItem currentItem = item;

    if (isEditMode) {
      return _buildCardContent(context, currentItem);
    }

    if (currentItem is HomeStackItem) {
      // HomeStackItem 的点击事件由内部的 carousel 处理
      // 这里只处理长按事件，不处理点击事件
      return GestureDetector(
        key: _cardKey,
        onLongPress: onLongPress,
        child: _buildCardContent(context, currentItem),
      );
    }

    if (currentItem is HomeWidgetItem) {
      return GestureDetector(
        key: _cardKey,
        onTap: onTap ?? () => _openWidgetPlugin(context),
        onLongPress: onLongPress,
        child: _buildCardContent(context, currentItem),
      );
    }

    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context),
      onLongPress: onLongPress,
      child: _buildCardContent(context, currentItem),
    );
  }

  Widget _buildStackCard(BuildContext context, HomeStackItem stackItem) {
    return _HomeStackCarousel(
      stack: stackItem,
      isEditMode: isEditMode,
      itemBuilder: (child) => _buildWidgetCard(context, child),
      onActiveIndexChanged: (index) {
        if (!isEditMode) {
          HomeLayoutManager().updateStackActiveIndex(stackItem.id, index);
        }
      },
      // 传递点击回调，使用轮播组件内部的索引
      onItemTap: (index) {
        final sanitizedIndex = index.clamp(0, stackItem.children.length - 1);
        final target = stackItem.children[sanitizedIndex];
        _openWidgetPlugin(context, target);
      },
    );
  }

  Widget _buildCardContent(BuildContext context, HomeItem currentItem) {
    final isWidgetLike =
        currentItem is HomeWidgetItem || currentItem is HomeStackItem;
    final Widget content =
        currentItem is HomeWidgetItem
            ? _buildWidgetCard(context, currentItem)
            : currentItem is HomeStackItem
            ? _buildStackCard(context, currentItem)
            : _buildFolderCard(context, currentItem as HomeFolderItem);
    return Stack(
      children: [
        Card(
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isSelected
                    ? BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                    : BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
          ),
          color: isWidgetLike ? Colors.transparent : null,
          child: content,
        ),
        if (isEditMode && dragHandle != null)
          Positioned(top: 4, right: 4, child: dragHandle!),
        if (isBatchMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                      : null,
            ),
          ),
      ],
    );
  }

  Widget _buildWidgetCard(BuildContext context, HomeWidgetItem widgetItem) {
    final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

    if (widgetDef == null) {
      // 如果小组件未找到，可能是插件还在初始化中，显示加载状态
      return _buildLoadingCard(context);
    }

    try {
      // 获取全局透明度设置
      final layoutManager = HomeLayoutManager();
      final globalWidgetOpacity = layoutManager.globalWidgetOpacity;
      final globalBackgroundOpacity =
          layoutManager.globalWidgetBackgroundOpacity;

      // 获取背景配置 - 使用默认的主题卡片颜色
      final defaultColor = Theme.of(context).cardColor;
      final backgroundColor = defaultColor.withValues(
        alpha: defaultColor.a * globalBackgroundOpacity,
      );

      final backgroundImagePath =
          widgetItem.config['backgroundImage'] as String?;

      // 获取网格尺寸信息
      final metrics = WidgetGridScope.maybeOf(context);

      // 计算实际像素尺寸
      final pixelSize = widgetItem.size.getPixelSize(metrics);

      // 计算基于像素尺寸的有效尺寸类别
      final pixelCategory = widgetItem.size.getEffectiveCategory(metrics);

      // 调试输出
      debugPrint('[HomeCard] 📦 构建小组件: '
          'widgetId=${widgetItem.widgetId}, '
          'gridSize=${widgetItem.size.width}x${widgetItem.size.height}, '
          'pixelSize=${pixelSize.width.toStringAsFixed(1)}x${pixelSize.height.toStringAsFixed(1)}, '
          'gridCategory=${widgetItem.size.category.name}, '
          'pixelCategory=${pixelCategory.name}, '
          'hasMetrics=${metrics != null}');

      // 将 widgetItem.id 和像素尺寸注入到 config 中
      // 这确保当小组件被添加或替换时，会创建新的组件实例并触发 initState
      // 同时小组件可以获取实际的像素尺寸用于响应式布局
      final configWithIdAndSize = {
        ...widgetItem.config,
        '_widgetItemId': widgetItem.id,
        '_pixelWidth': pixelSize.width,
        '_pixelHeight': pixelSize.height,
        '_gridMetrics': metrics,
        '_pixelCategory': pixelCategory, // 基于像素尺寸的有效类别
      };

      Widget content = widgetDef.build(
        context,
        configWithIdAndSize,
        widgetItem.size,
      );

      // 总是添加背景装饰容器（因为总是有背景颜色）
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image:
              backgroundImagePath != null &&
                      File(backgroundImagePath).existsSync()
                  ? DecorationImage(
                    image: FileImage(File(backgroundImagePath)),
                    fit: BoxFit.cover,
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );

      // 应用整体小组件透明度（影响整个卡片包括内容）
      if (globalWidgetOpacity < 1.0) {
        content = Opacity(opacity: globalWidgetOpacity, child: content);
      }

      return ClipRRect(borderRadius: BorderRadius.circular(12), child: content);
    } catch (e) {
      return _buildErrorCard(context, '加载失败: $e');
    }
  }

  /// 构建文件夹卡片
  Widget _buildFolderCard(BuildContext context, HomeFolderItem folder) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              flex: 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(folder.icon, size: 40, color: folder.color),
                  if (folder.children.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${folder.children.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              flex: 1,
              child: Text(
                folder.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载中卡片
  /// 占满小组件的实际尺寸，并带有渐显和加载动画效果
  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, opacity, child) {
              return Opacity(opacity: opacity, child: child);
            },
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 打开小组件对应的插件（使用 OpenContainer 风格动画，iOS 支持左滑返回）
  void _openWidgetPlugin(BuildContext context, [HomeWidgetItem? target]) async {
    final widgetItem = target ?? (item as HomeWidgetItem);
    final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

    if (widgetDef == null) return;

    // 特殊处理：今日日记快捷入口
    if (widgetItem.widgetId == 'diary_today_quick') {
      await _openTodayDiaryEditor(context);
      return;
    }

    // 检查是否为选择器小组件
    if (widgetDef.isSelectorWidget) {
      await _handleSelectorWidgetTap(context, widgetItem, widgetDef);
      return;
    }

    // 普通小组件：打开插件主视图
    final plugin = globalPluginManager.getPlugin(widgetDef.pluginId);
    if (plugin != null) {
      // 记录插件打开历史
      globalPluginManager.recordPluginOpen(plugin);
      // 使用 OpenContainer 风格导航，从卡片位置展开到全屏（iOS 支持左滑返回）
      NavigationHelper.openContainerWithHero(
        context,
        (_) => plugin.buildMainView(context),
        heroTag: 'widget_${widgetItem.id}',
        sourceKey: _cardKey,
        transitionDuration: const Duration(milliseconds: 300),
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
      );
    }
  }


  Future<void> _openTodayDiaryEditor(BuildContext context) async {
    try {
      // 获取 DiaryPlugin 实例
      final plugin = globalPluginManager.getPlugin('diary');
      if (plugin == null) {
        Toast.error('日记插件未加载');
        return;
      }

      final diaryPlugin = plugin as DiaryPlugin;
      final today = DateTime.now();
      final normalizedDate = DateTime(today.year, today.month, today.day);

      // 加载今日日记（如果存在）
      final todayEntry = await DiaryUtils.loadDiaryEntry(normalizedDate);

      // 打开编辑器
      NavigationHelper.push(
        context,
        DiaryEditorScreen(
          date: normalizedDate,
          storage: diaryPlugin.storage,
          initialTitle: todayEntry?.title ?? '',
          initialContent: todayEntry?.content ?? '',
        ),
      );
    } catch (e) {
      debugPrint('[HomeCard] 打开今日日记编辑器失败: $e');
      Toast.error('打开失败: $e');
    }
  }

  /// 处理选择器小组件的点击事件
  Future<void> _handleSelectorWidgetTap(
    BuildContext context,
    HomeWidgetItem widgetItem,
    HomeWidget widgetDef,
  ) async {
    debugPrint('[HomeCard] ========== _handleSelectorWidgetTap 开始 ==========');
    debugPrint('[HomeCard] widgetId: ${widgetItem.widgetId}');
    debugPrint('[HomeCard] isSelectorWidget: ${widgetDef.isSelectorWidget}');
    debugPrint('[HomeCard] navigationHandler: ${widgetDef.navigationHandler}');

    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (widgetItem.config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          widgetItem.config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
        debugPrint('[HomeCard] selectorConfig: $selectorConfig');
        debugPrint('[HomeCard] isConfigured: ${selectorConfig.isConfigured}');
      } else {
        debugPrint('[HomeCard] config 中没有 selectorWidgetConfig');
      }
    } catch (e) {
      debugPrint('[HomeCard] 解析选择器配置失败: $e');
    }

    // 判断是否已配置
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      debugPrint('[HomeCard] 未配置，打开数据选择器');
      // 未配置：打开数据选择器
      await _showDataSelector(context, widgetItem, widgetDef);
    } else {
      debugPrint('[HomeCard] 已配置，执行导航处理器');
      // 已配置：执行导航处理器
      SelectorResult result = selectorConfig.toSelectorResult()!;

      // 如果有 dataSelector 且 data 是 List，需要转换数据
      // 注意：如果使用公共小组件，data 可能已经被 dataSelector 转换过了
      if (widgetDef.dataSelector != null && result.data is List) {
        final dataArray = result.data as List<dynamic>;
        final transformedData = widgetDef.dataSelector!(dataArray);
        result = SelectorResult(
          pluginId: result.pluginId,
          selectorId: result.selectorId,
          path: result.path,
          data: transformedData,
        );
        debugPrint('[HomeCard] 转换后的 result.data: ${result.data}');
      }

      debugPrint('[HomeCard] result: $result');
      debugPrint('[HomeCard] result.data: ${result.data}');
      debugPrint('[HomeCard] result.data type: ${result.data.runtimeType}');

      // 检查是否可以执行导航
      final canNavigate = result.data != null && widgetDef.navigationHandler != null;
      debugPrint('[HomeCard] canNavigate: $canNavigate (data != null: ${result.data != null}, navigationHandler != null: ${widgetDef.navigationHandler != null})');

      if (canNavigate) {
        try {
          debugPrint('[HomeCard] 调用 navigationHandler...');
          widgetDef.navigationHandler!(context, result);
          debugPrint('[HomeCard] navigationHandler 调用完成');
        } catch (e) {
          debugPrint('[HomeCard] 导航处理器执行失败: $e');
          Toast.error('打开失败: $e');
        }
      } else {
        // 如果没有导航处理器，给出提示
        debugPrint('[HomeCard] 无法导航：data=${result.data}, navigationHandler=${widgetDef.navigationHandler}');
        if (result.data == null) {
          Toast.error('数据为空，无法打开');
        }
      }
    }
  }

  /// 显示数据选择器并保存选择结果
  Future<void> _showDataSelector(
    BuildContext context,
    HomeWidgetItem widgetItem,
    HomeWidget widgetDef,
  ) async {
    if (widgetDef.selectorId == null) {
      Toast.error('选择器ID未配置');
      return;
    }

    try {
      // 打开数据选择器
      final result = await pluginDataSelectorService.showSelector(
        context,
        widgetDef.selectorId!,
      );

      // 检查结果
      if (result == null || result.cancelled) {
        return;
      }

      // 如果有 dataSelector，使用它转换数据后再保存
      var finalResult = result;
      if (widgetDef.dataSelector != null && result.data is List) {
        final dataArray = result.data as List<dynamic>;
        final transformedData = widgetDef.dataSelector!(dataArray);
        finalResult = SelectorResult(
          pluginId: result.pluginId,
          selectorId: result.selectorId,
          path: result.path,
          data: transformedData,
        );
      }

      // 保存选择结果到配置
      final selectorConfig = SelectorWidgetConfig.fromSelectorResult(
        finalResult,
      );
      final updatedConfig = Map<String, dynamic>.from(widgetItem.config);
      updatedConfig['selectorWidgetConfig'] = selectorConfig.toJson();

      // 更新小组件
      final updatedItem = widgetItem.copyWith(config: updatedConfig);
      final layoutManager = HomeLayoutManager();
      layoutManager.updateItem(widgetItem.id, updatedItem);
      await layoutManager.saveLayout();

      Toast.success('配置已保存');

      // 刷新界面
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[HomeCard] 显示选择器失败: $e');
      Toast.error('选择器打开失败: $e');
    }
  }

  /// 处理点击事件（用于文件夹）
  void _handleTap(BuildContext context) {
    if (item is HomeFolderItem) {
      _openFolderDialog(context, item as HomeFolderItem);
    }
  }

  /// 打开文件夹对话框
  void _openFolderDialog(BuildContext context, HomeFolderItem folder) {
    showDialog(
      context: context,
      builder: (context) => FolderDialog(folder: folder),
    );
  }
}

class _HomeStackCarousel extends StatefulWidget {
  final HomeStackItem stack;
  final bool isEditMode;
  final Widget Function(HomeWidgetItem item) itemBuilder;
  final ValueChanged<int> onActiveIndexChanged;
  final ValueChanged<int>? onItemTap;

  const _HomeStackCarousel({
    required this.stack,
    required this.isEditMode,
    required this.itemBuilder,
    required this.onActiveIndexChanged,
    this.onItemTap,
  });

  @override
  State<_HomeStackCarousel> createState() => _HomeStackCarouselState();
}

class _HomeStackCarouselState extends State<_HomeStackCarousel>
    with SingleTickerProviderStateMixin {
  late InfiniteScrollController _controller;
  late int _currentIndex;
  late AnimationController _countdownController;
  static const Duration _autoScrollInterval = Duration(seconds: 6);
  static const double _dragTriggerDistance = 24;
  static const double _dragTriggerVelocity = 380;
  double _manualDragOffset = 0;
  bool _manualScrollInProgress = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = _sanitizeIndex(widget.stack.activeIndex);
    _controller = InfiniteScrollController(initialItem: _currentIndex);
    _countdownController = AnimationController(
      vsync: this,
      duration: _autoScrollInterval,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleAutoAdvance();
      }
    });
    _startCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _HomeStackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _sanitizeIndex(widget.stack.activeIndex);
    if (nextIndex != _currentIndex ||
        oldWidget.stack.children.length != widget.stack.children.length) {
      _currentIndex = nextIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.jumpToItem(_currentIndex);
        }
      });
    }

    if (_autoScrollEnabled) {
      _restartCountdown();
    } else {
      _stopCountdown();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  int _sanitizeIndex(int index) {
    if (widget.stack.children.isEmpty) {
      return 0;
    }
    return index.clamp(0, widget.stack.children.length - 1);
  }

  double _resolveExtent(BoxConstraints constraints) {
    final candidate =
        widget.stack.direction == HomeStackDirection.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
    if (candidate.isFinite && candidate > 0) {
      return candidate;
    }
    return 200;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stack.children.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.widgets_outlined)),
      );
    }

    if (widget.stack.children.length == 1) {
      return widget.itemBuilder(widget.stack.children.first);
    }

    final carousel = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final extent = _resolveExtent(constraints);
              return InfiniteCarousel.builder(
                controller: _controller,
                itemCount: widget.stack.children.length,
                itemExtent: extent,
                physics: const NeverScrollableScrollPhysics(),
                axisDirection:
                    widget.stack.direction == HomeStackDirection.horizontal
                        ? Axis.horizontal
                        : Axis.vertical,
                loop: true,
                onIndexChanged: (index) {
                  if (!mounted) return;
                  setState(() {
                    _currentIndex = index;
                  });
                  if (!widget.isEditMode) {
                    widget.onActiveIndexChanged(index);
                    _restartCountdown();
                  } else {
                    _stopCountdown();
                  }
                },
                itemBuilder: (context, itemIndex, realIndex) {
                  final child = widget.stack.children[itemIndex];
                  return widget.itemBuilder(child);
                },
              );
            },
          ),
        ),
        _buildDotsIndicator(),
        // 添加点击检测层，使用实际的 _currentIndex
        if (widget.onItemTap != null && !widget.isEditMode)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onItemTap!(_currentIndex),
            ),
          ),
      ],
    );

    final bool enableManualDrag = !widget.isEditMode;

    final gestureChild = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.horizontal
              ? (_) => _onManualDragStart()
              : null,
      onHorizontalDragUpdate:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.horizontal
              ? (details) => _onManualDragUpdate(details.primaryDelta ?? 0)
              : null,
      onHorizontalDragEnd:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.horizontal
              ? (details) => _onManualDragEnd(details.primaryVelocity ?? 0)
              : null,
      onVerticalDragStart:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.vertical
              ? (_) => _onManualDragStart()
              : null,
      onVerticalDragUpdate:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.vertical
              ? (details) => _onManualDragUpdate(details.primaryDelta ?? 0)
              : null,
      onVerticalDragEnd:
          enableManualDrag &&
                  widget.stack.direction == HomeStackDirection.vertical
              ? (details) => _onManualDragEnd(details.primaryVelocity ?? 0)
              : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: _handlePointerSignal,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: carousel,
        ),
      ),
    );

    return IgnorePointer(ignoring: widget.isEditMode, child: gestureChild);
  }

  Widget _buildDotsIndicator() {
    final total = widget.stack.children.length;
    if (total <= 1) {
      return const SizedBox.shrink();
    }
    final axis =
        widget.stack.direction == HomeStackDirection.horizontal
            ? Axis.horizontal
            : Axis.vertical;
    final children = List.generate(total, (index) {
      final isActive = (_currentIndex % total) == index;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        width: axis == Axis.horizontal ? 8 : 6,
        height: axis == Axis.horizontal ? 6 : 8,
        decoration: BoxDecoration(
          color:
              isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    });

    if (axis == Axis.horizontal) {
      return Positioned(
        bottom: 6,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    }

    return Positioned(
      right: 6,
      top: 0,
      bottom: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _stopCountdown();
    } else if (notification is ScrollEndNotification) {
      _restartCountdown();
    }
    return true;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (widget.stack.children.length <= 1) return;

    double delta;
    if (widget.stack.direction == HomeStackDirection.horizontal) {
      delta =
          event.scrollDelta.dx != 0
              ? event.scrollDelta.dx
              : event.scrollDelta.dy;
    } else {
      delta =
          event.scrollDelta.dy != 0
              ? event.scrollDelta.dy
              : event.scrollDelta.dx;
    }
    if (delta == 0) return;

    if (delta > 0) {
      _controller.nextItem();
    } else {
      _controller.previousItem();
    }
    _restartCountdown();
  }

  bool get _autoScrollEnabled =>
      !widget.isEditMode && widget.stack.children.length > 1;

  void _onManualDragStart() {
    _manualScrollInProgress = true;
    _manualDragOffset = 0;
    _stopCountdown();
  }

  void _onManualDragUpdate(double delta) {
    if (!_manualScrollInProgress) {
      return;
    }
    _manualDragOffset += delta;
  }

  void _onManualDragEnd(double velocity) {
    if (!_manualScrollInProgress) {
      return;
    }
    double signal = _manualDragOffset;
    if (signal.abs() < _dragTriggerDistance &&
        velocity.abs() >= _dragTriggerVelocity) {
      signal = velocity;
    }
    if (signal.abs() >= _dragTriggerDistance ||
        signal.abs() >= _dragTriggerVelocity) {
      if (signal > 0) {
        _controller.previousItem();
      } else if (signal < 0) {
        _controller.nextItem();
      }
    }
    _manualDragOffset = 0;
    _manualScrollInProgress = false;
    _restartCountdown();
  }

  void _startCountdownIfNeeded() {
    if (_autoScrollEnabled) {
      _countdownController
        ..reset()
        ..forward();
    }
  }

  void _restartCountdown() {
    _stopCountdown();
    _startCountdownIfNeeded();
  }

  void _stopCountdown() {
    if (_countdownController.isAnimating) {
      _countdownController.stop();
    }
    _countdownController.reset();
  }

  void _handleAutoAdvance() {
    if (!_autoScrollEnabled) {
      return;
    }
    _controller.nextItem();
    _restartCountdown();
  }
}
