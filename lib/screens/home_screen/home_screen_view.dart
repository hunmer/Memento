import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/app_drawer.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'home_screen_controller.dart';
import 'managers/home_layout_manager.dart';
import 'managers/home_widget_registry.dart';
import 'models/home_folder_item.dart';
import 'models/home_item.dart';
import 'models/home_widget_item.dart';
import 'models/home_stack_item.dart';
import 'models/home_widget_size.dart';
import 'models/plugin_widget_config.dart';
import 'models/layout_config.dart';
import 'widgets/add_widget_dialog.dart';
import 'widgets/background_settings_page.dart';
import 'widgets/create_folder_dialog.dart';
import 'widgets/home_grid.dart';
import 'widgets/layout_manager_dialog.dart';
import 'widgets/selector_widget_types.dart';
import 'widgets/widget_settings_dialog.dart';
import 'widgets/stack_direction_dialog.dart';

/// 主屏幕视图 - 负责 UI 构建
class HomeScreenView extends StatelessWidget {
  final HomeScreenController controller;
  final TabController? tabController;

  const HomeScreenView({super.key, required this.controller, this.tabController});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !controller.isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (controller.isEditMode && !didPop) {
          controller.toggleEditMode();
          Toast.info('已退出编辑模式', duration: const Duration(seconds: 1));
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        extendBodyBehindAppBar: controller.currentBackgroundPath != null,
        drawer: const AppDrawer(),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: controller.currentBackgroundPath != null
                  ? _buildBackgroundImage()
                  : const SizedBox.expand(key: ValueKey('no_background')),
            ),
            // 主内容
            controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.savedLayouts.isEmpty
                    ? _buildHomeContent(context)
                    : Positioned.fill(
                        child: Column(
                          children: [
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) => _handleScrollNotification(notification, context),
                                child: () {
                                      final tc = tabController;
                                      if (tc == null ||
                                          tc.length != controller.savedLayouts.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return ExtendedTabBarView(
                                        controller: tc,
                                        cacheExtent: 1,
                                        children: controller.savedLayouts.map((layout) {
                                          return _buildTabPage(context, layout.id);
                                        }).toList(),
                                      );
                                    }(),
                              ),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Center(child: _buildTabBar(context)),
      backgroundColor: controller.currentBackgroundPath != null ? Colors.transparent : null,
      elevation: controller.currentBackgroundPath != null ? 0 : null,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: [
        if (controller.isBatchMode) ...[
          if (controller.selectedItemIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: () => _showMoveToFolderDialog(context),
              tooltip: '移动到',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmBatchDelete(context),
              tooltip: '删除',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.exitBatchMode();
            },
            tooltip: '退出选择',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWidgetDialog(context),
            tooltip: '添加组件',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
            tooltip: '更多选项',
          ),
        ],
      ],
    );
  }

  /// 构建背景图
  Widget _buildBackgroundImage() {
    return Stack(
      key: ValueKey(controller.currentBackgroundPath),
      fit: StackFit.expand,
      children: [
        Image.file(File(controller.currentBackgroundPath!), fit: controller.currentBackgroundFit),
        if (controller.currentBackgroundBlur > 0)
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: controller.currentBackgroundBlur,
              sigmaY: controller.currentBackgroundBlur,
            ),
            child: Container(color: Colors.transparent),
          ),
      ],
    );
  }

  /// 构建主页内容
  Widget _buildHomeContent(BuildContext context) {
    return Opacity(
      opacity: controller.globalWidgetOpacity,
      child: ListenableBuilder(
        listenable: controller.layoutManager,
        builder: (context, child) {
          final isCenter = controller.layoutManager.gridAlignment == 'center';
          final alignment = isCenter ? Alignment.center : Alignment.topCenter;

          return Padding(
            padding: EdgeInsets.only(
              top: !isCenter && controller.currentBackgroundPath != null
                  ? MediaQuery.of(context).padding.top
                  : 0,
            ),
            child: HomeGrid(
              items: controller.layoutManager.items,
              crossAxisCount: controller.layoutManager.gridCrossAxisCount,
              isEditMode: controller.isEditMode,
              isBatchMode: controller.isBatchMode,
              selectedItemIds: controller.selectedItemIds,
              alignment: alignment,
              onReorder: controller.layoutManager.reorder,
              onAddToFolder: (itemId, folderId) {
                controller.layoutManager.moveToFolder(itemId, folderId);
                Toast.success('已添加到文件夹');
              },
              onItemTap: controller.isBatchMode
                  ? (item) => controller.toggleItemSelection(item.id)
                  : null,
              onItemLongPress: (item) => _handleCardLongPress(context, item),
              onQuickCreateLayout: _createQuickLayout,
              onMergeIntoStack: _handleStackMerge,
            ),
          );
        },
      ),
    );
  }

  /// 构建 TabBar
  Widget _buildTabBar(BuildContext context) {
    if (tabController == null || controller.savedLayouts.isEmpty) {
      return Text(
        controller.currentLayoutName.isEmpty ? 'app_home'.tr : controller.currentLayoutName,
      );
    }
    return _DragAwareTabBar(
      tabController: tabController!,
      layouts: controller.savedLayouts,
      onTap: (index) => controller.onPageChanged(index, () {}),
      onHoverSwitch: _handleTabSwitchByDrag,
      isDragActive: () => controller.isDraggingItem,
    );
  }

  Future<void> _handleTabSwitchByDrag(int index) async {
    final tc = tabController;
    if (tc == null) {
      return;
    }
    if (index < 0 || index >= tc.length) {
      return;
    }
    if (tc.index == index) {
      return;
    }
    tc.animateTo(index);
    controller.onPageChanged(index, () {});
  }

  /// 构建单个 Tab 页面
  Widget _buildTabPage(BuildContext context, String layoutId) {
    final items = _getItemsForLayout(layoutId);
    return _buildHomeContentForItems(context, layoutId: layoutId, items: items, key: ValueKey('page_$layoutId'));
  }

  /// 获取指定布局对应的 items
  List<HomeItem> _getItemsForLayout(String layoutId) {
    return controller.getItemsForLayout(layoutId);
  }

  /// 为指定 items 构建主页内容
  Widget _buildHomeContentForItems(BuildContext context, {required String layoutId, required List<HomeItem> items, Key? key}) {
    return Opacity(
      key: key,
      opacity: controller.globalWidgetOpacity,
      child: ListenableBuilder(
        listenable: controller.layoutManager,
        builder: (context, child) {
          // 动态获取最新的 items（从缓存或 layoutManager）
          final latestItems = controller.getItemsForLayout(layoutId);

          return LayoutBuilder(
            builder: (context, constraints) {
              // 如果是空布局，使用目标布局的结构显示骨架屏
              if (latestItems.isEmpty) {
                debugPrint('Build skeleton for layout: $layoutId, current: ${controller.currentLayoutName}');
                return FutureBuilder<({List<HomeWidgetSize> structure, int crossAxisCount})>(
                  future: controller.getLayoutStructureById(layoutId),
                  builder: (context, snapshot) {
                    debugPrint('FutureBuilder snapshot: ${snapshot.connectionState}, data: ${snapshot.data?.structure.length}');
                    final layoutStructure = snapshot.data;
                    if (layoutStructure == null || layoutStructure.structure.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildSkeletonFromStructure(context, layoutStructure.structure, layoutStructure.crossAxisCount);
                  },
                );
              }

              final isCenter = controller.layoutManager.gridAlignment == 'center';
              final alignment = isCenter ? Alignment.center : Alignment.topCenter;

              return Padding(
                padding: EdgeInsets.only(
                  top: !isCenter && controller.currentBackgroundPath != null
                      ? MediaQuery.of(context).padding.top
                      : 0,
                ),
                child: HomeGrid(
                  items: latestItems,
                  layoutId: layoutId,
                  crossAxisCount: controller.layoutManager.gridCrossAxisCount,
                  isEditMode: controller.isEditMode,
                  isBatchMode: controller.isBatchMode,
                  selectedItemIds: controller.selectedItemIds,
                  alignment: alignment,
                  onReorder: controller.layoutManager.reorder,
                  onAddToFolder: (itemId, folderId) {
                    controller.layoutManager.moveToFolder(itemId, folderId);
                    Toast.success('已添加到文件夹');
                  },
                  onItemTap: controller.isBatchMode
                      ? (item) => controller.toggleItemSelection(item.id)
                      : null,
                  onItemLongPress: (item) => _handleCardLongPress(context, item),
                  onQuickCreateLayout: _createQuickLayout,
                  onMergeIntoStack: _handleStackMerge,
                  onDragStarted: controller.handleDragStart,
                  onDragEnded: controller.handleDragEnded,
                  onCrossLayoutDrop:
                      (draggedId, targetLayoutId, targetIndex) =>
                          controller.moveDraggedItemToLayout(
                            draggedId,
                            targetLayoutId,
                            targetIndex,
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 从当前布局结构构建骨架屏
  Widget _buildSkeletonFromStructure(BuildContext context, List<HomeWidgetSize> structure, int crossAxisCount) {
    final isCenter = controller.layoutManager.gridAlignment == 'center';
    final alignment = isCenter ? Alignment.center : Alignment.topCenter;

    // 转换为骨架 items
    final skeletonItems = structure.map((size) {
      return HomeWidgetItem(
        id: 'skeleton_${UniqueKey().toString()}',
        widgetId: 'skeleton',
        size: size == HomeWidgetSize.custom ? HomeWidgetSize.small : size,
        config: {},
      );
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        top: !isCenter && controller.currentBackgroundPath != null
            ? kToolbarHeight + 8
            : 0,
      ),
      child: HomeGrid(
        items: skeletonItems,
        crossAxisCount: crossAxisCount,
        isEditMode: controller.isEditMode,
        isBatchMode: controller.isBatchMode,
        selectedItemIds: controller.selectedItemIds,
        alignment: alignment,
        showSkeleton: true,
        onReorder: null,
        onAddToFolder: null,
        onItemTap: null,
        onItemLongPress: null,
        onQuickCreateLayout: null,
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final isCenter = controller.layoutManager.gridAlignment == 'center';

    return Padding(
      padding: EdgeInsets.only(
        top: !isCenter && controller.currentBackgroundPath != null
            ? kToolbarHeight + 8
            : 0,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'screens_noWidgetsYet'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'screens_clickPlusToAdd'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理滚动通知
  bool _handleScrollNotification(ScrollNotification notification, BuildContext context) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.forward ||
          notification.direction == ScrollDirection.reverse) {
        final context = notification.context;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final page = tabController?.index ?? 0;
            if (page != controller.currentPageIndex) {
              controller.onPageChanged(page, () {});
            }
          }
        }
      }
    }
    if (notification is ScrollEndNotification) {
      if (tabController != null) {
        final page = tabController!.index;
        if (page != controller.currentPageIndex) {
          controller.onPageChanged(page, () {});
        }
      }
    }
    return false;
  }

  // ==================== 对话框方法 ====================

  void _showAddWidgetDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddWidgetDialog());
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const CreateFolderDialog());
  }

  void _showGridSizeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => _GridSizeDialog(layoutManager: controller.layoutManager),
    );
  }

  void _confirmClearLayout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_confirmClear'.tr),
        content: Text('screens_confirmClearAllWidgets'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.layoutManager.clear();
              Toast.success('screens_allWidgetsCleared'.tr);
            },
            child: Text('screens_confirm'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuickLayout(Map<String, String> data) async {
    final name = data['name']!;
    final type = data['type']!;

    try {
      controller.layoutManager.clear();
      if (type == '1x1') {
        await _addAllWidgetsOfSize(HomeWidgetSize.small);
      } else if (type == '2x2') {
        await _addAllWidgetsOfSize(HomeWidgetSize.large);
      }
      await controller.layoutManager.saveCurrentLayoutAs(name);
      // 重新加载布局列表，确保包含新创建的布局
      await controller.reloadLayouts();
      Toast.success('布局"$name"已创建');
    } catch (e) {
      Toast.error('创建失败：$e');
    }
  }

  Future<void> _addAllWidgetsOfSize(HomeWidgetSize size) async {
    final registry = HomeWidgetRegistry();
    final allWidgets = registry.getAllWidgets();
    final widgets = allWidgets.where((widget) => widget.supportedSizes.contains(size)).toList();

    for (final widget in widgets) {
      final item = HomeWidgetItem(
        id: controller.layoutManager.generateId(),
        widgetId: widget.id,
        size: size,
        config: {},
      );
      controller.layoutManager.addItem(item);
    }
  }

  void _showSaveLayoutDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_saveCurrentLayout'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'screens_layoutName'.tr,
            hintText: 'screens_layoutNameHint'.tr,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr)),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Toast.error('screens_pleaseEnterLayoutName'.tr);
                return;
              }
              Navigator.pop(context);
              try {
                await controller.layoutManager.saveCurrentLayoutAs(name);
                await controller.initializeLayout();
                Toast.success('screens_layoutSaved'.trParams({'name': name}));
              } catch (e) {
                Toast.error('${'screens_saveFailed'.tr}: $e');
              }
            },
            child: Text('screens_save'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _showLayoutManagerDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => LayoutManagerDialog(
        onLayoutChanged: () async {
          // 布局删除时重新加载并切换到第一个
          await controller.reloadLayouts();
        },
      ),
    );
    // 对话框关闭后重新初始化（处理新建布局的情况）
    await controller.initializeLayout();
  }

  Future<void> _showThemeSettings(BuildContext context) async {
    await NavigationHelper.push(context, const BackgroundSettingsPage());
    await controller.loadCurrentBackground();
  }

  void _handleCardLongPress(BuildContext context, HomeItem item) {
    if (controller.isEditMode) return;

    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item is HomeWidgetItem) ...[
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('screens_widgetSettings'.tr),
              onTap: () {
                Navigator.pop(context);
                _showWidgetSettings(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: Text('screens_adjustSize'.tr),
              onTap: () {
                Navigator.pop(context);
                _showSizeAdjuster(context, item);
              },
            ),
            if (controller.isSelectorWidget(item))
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text('screens_reselectData'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _reselectWidgetData(context, item);
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text('screens_replaceWidget'.tr),
              onTap: () {
                Navigator.pop(context);
                _replaceWidget(context, item);
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteItem(context, item);
            },
          ),
        ],
      ),
    );
  }

  void _reselectWidgetData(BuildContext context, HomeWidgetItem item) async {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null || widget.selectorId == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    // 检查是否为公共小组件
    String? currentCommonWidgetId;
    if (item.config.containsKey('selectorWidgetConfig')) {
      try {
        final oldSelectorConfig = SelectorWidgetConfig.fromJson(
          item.config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
        currentCommonWidgetId = oldSelectorConfig.commonWidgetId;
      } catch (_) {
        // 忽略解析错误
      }
    }

    // 如果是公共小组件，打开公共小组件选择页面
    if (currentCommonWidgetId != null) {
      // 获取完整的选择器配置
      SelectorWidgetConfig? initialSelectorConfig;
      try {
        initialSelectorConfig = SelectorWidgetConfig.fromJson(
          item.config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      } catch (_) {
        // 忽略解析错误
      }

      final _ = await Navigator.pushNamed(
        context,
        '/common_widget_selector',
        arguments: {
          'pluginWidget': widget,
          'replaceWidgetItemId': item.id,
          'initialCommonWidgetId': currentCommonWidgetId,
          'initialSelectorConfig': initialSelectorConfig,
          'originalSize': item.size,
          'originalConfig': item.config,
        },
      );
      return;
    }

    // 非公共小组件，使用原有的选择器逻辑
    final result = await pluginDataSelectorService.showSelector(context, widget.selectorId!);

    if (result == null || result.cancelled) {
      return; // 取消时不做任何操作
    }

    // 清除旧的选择器相关配置
    final updatedConfig = Map<String, dynamic>.from(item.config);
    updatedConfig.remove('selectorWidgetConfig');
    final keysToRemove = widget.dataSelector != null ? _getSelectorDataKeys(widget) : [];
    for (final key in keysToRemove) {
      updatedConfig.remove(key);
    }

    // 添加新的选择器配置
    final newConfig = _processSelectorResult(widget, result);
    updatedConfig.addAll(newConfig);

    final finalItem = item.copyWith(config: updatedConfig);

    // 一次性更新并强制刷新
    controller.layoutManager.updateItem(item.id, finalItem);
    await controller.layoutManager.saveLayout();

    Toast.success('数据已更新');
  }

  void _replaceWidget(BuildContext context, HomeWidgetItem item) {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    // 使用插件名称作为初始搜索关键词，过滤出同插件的其他小组件
    showDialog(
      context: context,
      builder: (context) => AddWidgetDialog(
        replaceWidgetItemId: item.id,
        initialSearchQuery: widget.pluginId,
      ),
    );
  }

  Future<bool> _handleStackMerge(
    BuildContext context,
    HomeItem targetItem,
    HomeItem draggedItem,
  ) async {
    final layoutManager = controller.layoutManager;
    if (!layoutManager.canMergeIntoStack(targetItem, draggedItem)) {
      Toast.warning('????????????');
      return false;
    }

    HomeStackDirection? direction;
    if (targetItem is! HomeStackItem) {
      direction = await showStackDirectionDialog(context);
      if (direction == null) {
        return false;
      }
    }

    final result = layoutManager.mergeIntoStack(
      targetItemId: targetItem.id,
      draggedItemId: draggedItem.id,
      direction: direction,
    );

    if (result == null) {
      Toast.error('??????????');
      return false;
    }

    await layoutManager.saveLayout();
    Toast.success('???????');
    return true;
  }

  List<String> _getSelectorDataKeys(dynamic widget) {
    return ['accountId', 'accountTitle', 'accountIcon', 'periodId', 'periodLabel', 'periodStart', 'periodEnd'];
  }

  Map<String, dynamic> _processSelectorResult(dynamic widget, SelectorResult result) {
    SelectorResult finalResult = result;
    Map<String, dynamic>? extractedData;

    if (widget.dataSelector != null && result.data is List) {
      final dataArray = result.data as List<dynamic>;
      final transformedData = widget.dataSelector!(dataArray);
      if (transformedData is Map<String, dynamic>) {
        extractedData = transformedData;
      }
      finalResult = SelectorResult(
        pluginId: result.pluginId,
        selectorId: result.selectorId,
        path: result.path,
        data: transformedData,
      );
    }

    final selectorConfig = SelectorWidgetConfig.fromSelectorResult(finalResult);
    final newConfig = <String, dynamic>{'selectorWidgetConfig': selectorConfig.toJson()};

    if (extractedData != null) {
      newConfig.addAll(extractedData);
    }

    return newConfig;
  }

  void _showWidgetSettings(BuildContext context, HomeWidgetItem item) async {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null || widget.availableStatsProvider == null) {
      Toast.warning('该小组件不支持自定义设置');
      return;
    }

    final availableItems = widget.availableStatsProvider!(context);
    if (availableItems.isEmpty) {
      Toast.warning('该小组件没有可配置的项目');
      return;
    }

    PluginWidgetConfig currentConfig;
    try {
      if (item.config.containsKey('pluginWidgetConfig')) {
        currentConfig = PluginWidgetConfig.fromJson(item.config['pluginWidgetConfig'] as Map<String, dynamic>);
      } else {
        currentConfig = PluginWidgetConfig();
      }
    } catch (e) {
      currentConfig = PluginWidgetConfig();
    }

    final result = await showDialog<PluginWidgetConfig>(
      context: context,
      builder: (context) => WidgetSettingsDialog(initialConfig: currentConfig, availableItems: availableItems),
    );

    if (result != null) {
      final updatedConfig = Map<String, dynamic>.from(item.config)..['pluginWidgetConfig'] = result.toJson();
      final updatedItem = item.copyWith(config: updatedConfig);
      controller.layoutManager.updateItem(item.id, updatedItem);
      await controller.layoutManager.saveLayout();
      Toast.success('设置已保存');
    }
  }

  void _showSizeAdjuster(BuildContext context, HomeWidgetItem item) {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    final supportedSizes = widget.supportedSizes;
    final hasCustom = supportedSizes.contains(HomeWidgetSize.custom);

    if (supportedSizes.length <= 1 && !hasCustom) {
      Toast.warning('该小组件不支持调整大小');
      return;
    }

    int customWidth = item.size == HomeWidgetSize.custom ? (item.config['customWidth'] as int? ?? 2) : 2;
    int customHeight = item.size == HomeWidgetSize.custom ? (item.config['customHeight'] as int? ?? 2) : 2;
    HomeWidgetSize? selectedSize = item.size;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('screens_selectWidgetSize'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...supportedSizes.map((size) {
                  final isSelected = size == selectedSize;
                  final sizeLabel = _getSizeLabel(size);
                  return RadioListTile<HomeWidgetSize>(
                    title: Text(sizeLabel),
                    subtitle: size == HomeWidgetSize.custom
                        ? Text('screens_customSizeDesc'.tr)
                        : Text('screens_widgetSize'.trParams({'width': size.width.toString(), 'height': size.height.toString()})),
                    value: size,
                    groupValue: selectedSize,
                    selected: isSelected,
                    onChanged: (HomeWidgetSize? newSize) {
                      if (newSize != null) {
                        setDialogState(() {
                          selectedSize = newSize;
                          if (newSize != HomeWidgetSize.custom) {
                            // 选择非自定义尺寸时，重置自定义尺寸为默认值
                            customWidth = 2;
                            customHeight = 2;
                          }
                        });
                      }
                    },
                  );
                }),
                if (hasCustom && selectedSize == HomeWidgetSize.custom) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('screens_customSizeAdjust'.tr, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _buildSizeSlider(context, '宽度', customWidth, (v) => setDialogState(() => customWidth = v.toInt()), (v) => setDialogState(() => customWidth = v.toInt())),
                  _buildSizeSlider(context, '高度', customHeight, (v) => setDialogState(() => customHeight = v.toInt()), (v) => setDialogState(() => customHeight = v.toInt())),
                  const SizedBox(height: 8),
                  Text('screens_customSizePreview'.trParams({'width': customWidth.toString(), 'height': customHeight.toString()}),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveWidgetSize(context, item, HomeWidgetSize.custom, customWidth, customHeight);
                      },
                      child: Text('screens_applyCustomSize'.tr),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr)),
              if (selectedSize != HomeWidgetSize.custom)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveWidgetSize(context, item, selectedSize!, customWidth, customHeight);
                  },
                  child: Text('screens_confirm'.tr),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSizeSlider(BuildContext context, String label, int value, ValueChanged<double> onChanged, ValueChanged<int> onChangedInt) {
    return Row(children: [
      Text(label),
      const SizedBox(width: 8),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          label: value.toString(),
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 32, child: Text(value.toString(), style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center)),
    ]);
  }

  String _getSizeLabel(HomeWidgetSize size) {
    switch (size) {
      case HomeWidgetSize.small: return 'screens_smallSize'.tr;
      case HomeWidgetSize.medium: return 'screens_mediumSize'.tr;
      case HomeWidgetSize.large: return 'screens_largeSize'.tr;
      case HomeWidgetSize.large3: return 'screens_large3Size'.tr;
      case HomeWidgetSize.wide: return 'screens_wideSize'.tr;
      case HomeWidgetSize.wide2: return 'screens_wide2Size'.tr;
      case HomeWidgetSize.wide3: return 'screens_wide3Size'.tr;
      case HomeWidgetSize.custom: return 'screens_customSize'.tr;
    }
  }

  Future<void> _saveWidgetSize(BuildContext context, HomeWidgetItem item, HomeWidgetSize newSize, int customWidth, int customHeight) async {
    final updatedConfig = Map<String, dynamic>.from(item.config);
    if (newSize == HomeWidgetSize.custom) {
      updatedConfig['customWidth'] = customWidth;
      updatedConfig['customHeight'] = customHeight;
    }
    final updatedItem = item.copyWith(size: newSize, config: updatedConfig);
    controller.layoutManager.updateItem(item.id, updatedItem);
    await controller.layoutManager.saveLayout();
    ToastService.instance.showToast('组件大小已更新');
  }

  void _confirmDeleteItem(BuildContext context, HomeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_confirmDelete'.tr),
        content: Text(controller.getDeleteConfirmMessage(item)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              controller.layoutManager.removeItem(item.id);
              await controller.layoutManager.saveLayout();
              ToastService.instance.showToast(
                '"${item is HomeWidgetItem ? HomeWidgetRegistry().getWidget(item.widgetId)?.name ?? '组件' : (item as HomeFolderItem).name}" ${'screens_deleted'.tr}',
              );
            },
            child: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmBatchDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_confirmDelete'.tr),
        content: Text('screens_confirmDeleteSelectedItems'.trParams({'count': controller.selectedItemIds.length.toString()})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (final itemId in controller.selectedItemIds) {
                controller.layoutManager.removeItem(itemId);
              }
              await controller.layoutManager.saveLayout();
              Toast.success('screens_itemsDeleted'.trParams({'count': controller.selectedItemIds.length.toString()}));
              controller.exitBatchMode();
            },
            child: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(BuildContext context) {
    final folders = controller.layoutManager.items
        .whereType<HomeFolderItem>()
        .where((folder) => !controller.selectedItemIds.contains(folder.id))
        .toList();

    if (folders.isEmpty) {
      Toast.warning('screens_noAvailableFolders'.tr);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_moveToFolder'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(folder.icon, color: folder.color),
                title: Text(folder.name),
                subtitle: Text('screens_itemCount'.trParams({'count': folder.children.length.toString()})),
                onTap: () {
                  Navigator.pop(context);
                  _moveSelectedItemsToFolder(context, folder.id);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_cancel'.tr))],
      ),
    );
  }

  void _moveSelectedItemsToFolder(BuildContext context, String folderId) async {
    for (final itemId in controller.selectedItemIds) {
      controller.layoutManager.moveToFolder(itemId, folderId);
    }
    await controller.layoutManager.saveLayout();
    Toast.success('screens_itemsMovedToFolder'.trParams({'count': controller.selectedItemIds.length.toString()}));
    controller.exitBatchMode();
  }

  void _showOptionsMenu(BuildContext context) {
    SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(controller.isEditMode ? Icons.check : Icons.edit),
              title: Text(controller.isEditMode ? '完成排序' : '自定义排序'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleEditMode();
                Toast.info(controller.isEditMode ? '长按拖拽可调整顺序' : '已退出编辑模式');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: const Text('批量编辑'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleBatchMode();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: Text('screens_createNewFolder'.tr),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: Text('screens_addWidget'.tr),
              onTap: () {
                Navigator.pop(context);
                _showAddWidgetDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text('screens_saveCurrentLayout'.tr),
              onTap: () {
                Navigator.pop(context);
                _showSaveLayoutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: Text('screens_manageLayouts'.tr),
              onTap: () {
                Navigator.pop(context);
                _showLayoutManagerDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text('screens_themeSettings'.tr),
              onTap: () {
                Navigator.pop(context);
                _showThemeSettings(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: Text('screens_gridSettings'.tr),
              subtitle: Text('${controller.layoutManager.gridCrossAxisCount} 列 · ${controller.layoutManager.gridAlignment == "top" ? 'screens_topDisplay'.tr : 'screens_centerDisplay'.tr}'),
              onTap: () {
                Navigator.pop(context);
                _showGridSizeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: Text('screens_clearLayout'.tr),
              onTap: () {
                Navigator.pop(context);
                _confirmClearLayout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 网格大小调节对话框
class _GridSizeDialog extends StatefulWidget {
  final HomeLayoutManager layoutManager;
  const _GridSizeDialog({required this.layoutManager});

  @override
  State<_GridSizeDialog> createState() => _GridSizeDialogState();
}

class _GridSizeDialogState extends State<_GridSizeDialog> {
  late int _currentSize;
  late String _currentAlignment;

  @override
  void initState() {
    super.initState();
    _currentSize = widget.layoutManager.gridCrossAxisCount;
    _currentAlignment = widget.layoutManager.gridAlignment;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('screens_gridSettings'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('screens_gridSize'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('screens_gridSizeDescription'.tr, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(children: [
              Text('screens_gridColumns'.trParams({'count': _currentSize.toString()}), style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(icon: const Icon(Icons.remove), onPressed: _currentSize > 1 ? () { setState(() { _currentSize--; widget.layoutManager.setGridCrossAxisCount(_currentSize); }); } : null),
              IconButton(icon: const Icon(Icons.add), onPressed: _currentSize < 10 ? () { setState(() { _currentSize++; widget.layoutManager.setGridCrossAxisCount(_currentSize); }); } : null),
            ]),
            Slider(
              value: _currentSize.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_currentSize',
              onChanged: (value) { setState(() { _currentSize = value.round(); widget.layoutManager.setGridCrossAxisCount(_currentSize); }); },
            ),
            const SizedBox(height: 8),
            Text('提示：数字越大，每行显示的组件越多', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('screens_displayPosition'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('screens_displayPositionDescription'.tr, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(value: 'top', label: Text('screens_topDisplay'.tr), icon: const Icon(Icons.vertical_align_top)),
                ButtonSegment<String>(value: 'center', label: Text('screens_centerDisplay'.tr), icon: const Icon(Icons.vertical_align_center)),
              ],
              selected: {_currentAlignment},
              onSelectionChanged: (Set<String> newSelection) { setState(() { _currentAlignment = newSelection.first; widget.layoutManager.setGridAlignment(_currentAlignment); }); },
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('screens_complete'.tr))],
    );
  }
}

class _DragAwareTabBar extends StatefulWidget {
  final TabController tabController;
  final List<LayoutConfig> layouts;
  final ValueChanged<int> onTap;
  final Future<void> Function(int index) onHoverSwitch;
  final bool Function() isDragActive;

  const _DragAwareTabBar({
    required this.tabController,
    required this.layouts,
    required this.onTap,
    required this.onHoverSwitch,
    required this.isDragActive,
  });

  @override
  State<_DragAwareTabBar> createState() => _DragAwareTabBarState();
}

class _DragAwareTabBarState extends State<_DragAwareTabBar> {
  int? _hoveredIndex;
  Timer? _switchTimer;

  @override
  void dispose() {
    _switchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedTabBar(
      controller: widget.tabController,
      isScrollable: true,
      indicatorSize: TabBarIndicatorSize.tab,
      onTap: widget.onTap,
      tabs: List.generate(widget.layouts.length, (index) {
        final layout = widget.layouts[index];
        final label = layout.name.isEmpty ? '默认' : layout.name;
        return DragTarget<String>(
          hitTestBehavior: HitTestBehavior.translucent,
          onWillAcceptWithDetails: (_) {
            if (!widget.isDragActive()) {
              return false;
            }
            _scheduleSwitch(index);
            return false;
          },
          onLeave: (_) => _cancelHover(index),
          onAcceptWithDetails: (_) => _cancelHover(index),
          builder: (context, candidateData, rejectedData) {
            final isHovering = _hoveredIndex == index && widget.isDragActive();
            return Tab(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration:
                    isHovering
                        ? BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        )
                        : null,
                child: Text(label),
              ),
            );
          },
        );
      }),
    );
  }

  void _scheduleSwitch(int index) {
    if (_hoveredIndex == index) {
      return;
    }
    setState(() {
      _hoveredIndex = index;
    });
    _switchTimer?.cancel();
    _switchTimer = Timer(const Duration(milliseconds: 800), () {
      widget.onHoverSwitch(index);
    });
  }

  void _cancelHover(int index) {
    if (_hoveredIndex == index) {
      setState(() {
        _hoveredIndex = null;
      });
    }
    _switchTimer?.cancel();
    _switchTimer = null;
  }
}
