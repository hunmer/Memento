import 'dart:io';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/plugins/diary/utils/diary_utils.dart';
import 'package:Memento/plugins/diary/screens/diary_editor_screen.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'folder_dialog.dart';

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

  HomeItem get item => widget.item;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onLongPress => widget.onLongPress;
  bool get isSelected => widget.isSelected;
  bool get isEditMode => widget.isEditMode;
  bool get isBatchMode => widget.isBatchMode;
  Widget? get dragHandle => widget.dragHandle;

  @override
  Widget build(BuildContext context) {
    final isWidgetItem = item is HomeWidgetItem;

    // 编辑模式下不使用交互，直接返回卡片内容
    if (isEditMode) {
      return _buildCardContent(context, isWidgetItem);
    }

    // 小组件卡片使用 OpenContainer 动画
    if (isWidgetItem) {
      return GestureDetector(
        key: _cardKey,
        onTap: onTap ?? () => _openWidgetPlugin(context),
        onLongPress: onLongPress,
        child: _buildCardContent(context, true),
      );
    }

    // 文件夹卡片使用 GestureDetector
    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context),
      onLongPress: onLongPress,
      child: _buildCardContent(context, isWidgetItem),
    );
  }

  /// 构建卡片内容（用于复用）
  Widget _buildCardContent(BuildContext context, bool isWidgetItem) {
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
          // 对小组件卡片使用透明的 Card 背景色，这样内部背景颜色的透明度
          // 能够作用到整体（否则会被 Card 自身的背景色遮挡）
          color: isWidgetItem ? Colors.transparent : null,
          child:
              isWidgetItem
                  ? _buildWidgetCard(context, item as HomeWidgetItem)
                  : _buildFolderCard(context, item as HomeFolderItem),
        ),
        // 编辑模式下显示拖拽手柄
        if (isEditMode && dragHandle != null)
          Positioned(top: 4, right: 4, child: dragHandle!),
        // 批量选择模式下显示选中标记
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

  /// 构建小组件卡片
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

      // 获取背景配置
      Color backgroundColor;
      if (widgetItem.config['backgroundColor'] != null) {
        // 用户设置了自定义背景颜色
        final originalColor = Color(
          widgetItem.config['backgroundColor'] as int,
        );
        backgroundColor = originalColor.withValues(
          alpha: originalColor.a * globalBackgroundOpacity,
        );
      } else {
        // 没有设置背景颜色，使用默认的主题卡片颜色
        final defaultColor = Theme.of(context).cardColor;
        backgroundColor = defaultColor.withValues(
          alpha: defaultColor.a * globalBackgroundOpacity,
        );
      }

      final backgroundImagePath =
          widgetItem.config['backgroundImage'] as String?;

      Widget content = widgetDef.build(
        context,
        widgetItem.config,
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
  void _openWidgetPlugin(BuildContext context) async {
    final widgetItem = item as HomeWidgetItem;
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

  /// 打开今日日记编辑界面
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

      // 如果有 dataSelector，需要转换数据
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
      if (result.data != null && widgetDef.navigationHandler != null) {
        try {
          debugPrint('[HomeCard] 调用 navigationHandler...');
          widgetDef.navigationHandler!(context, result);
          debugPrint('[HomeCard] navigationHandler 调用完成');
        } catch (e) {
          debugPrint('[HomeCard] 导航处理器执行失败: $e');
          Toast.error('打开失败: $e');
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
      final selectorConfig = SelectorWidgetConfig.fromSelectorResult(finalResult);
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
