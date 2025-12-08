import 'dart:io';
import 'package:Memento/core/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'folder_dialog.dart';

/// 主页卡片组件
///
/// 显示一个小组件或文件夹的卡片
class HomeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isWidgetItem = item is HomeWidgetItem;

    // 编辑模式下不使用交互，直接返回卡片内容
    if (isEditMode) {
      return _buildCardContent(context, isWidgetItem);
    }

    // 小组件卡片使用 OpenContainer 实现展开动画
    if (isWidgetItem) {
      final widgetItem = item as HomeWidgetItem;
      final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

      return OpenContainer<bool>(
        transitionType: ContainerTransitionType.fade,
        transitionDuration: const Duration(milliseconds: 400),
        openBuilder: (BuildContext context, VoidCallback _) {
          if (widgetDef != null) {
            final plugin = globalPluginManager.getPlugin(widgetDef.pluginId);
            if (plugin != null) {
              return Scaffold(body: plugin.buildMainView(context));
            }
          }
          return Scaffold(body: const Center(child: Text('无法打开插件')));
        },
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        closedColor: Colors.transparent,
        openElevation: 0,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return GestureDetector(
            onTap: onTap ?? openContainer,
            onLongPress: onLongPress,
            child: _buildCardContent(context, true),
          );
        },
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
                    : BorderSide.none,
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

      Widget content = widgetDef.build(context, widgetItem.config);

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
  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
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
