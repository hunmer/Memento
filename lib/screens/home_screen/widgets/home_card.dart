import 'dart:io';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';
import '../managers/home_widget_registry.dart';
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
    final cardContent = Stack(
      children: [
        Card(
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: item is HomeWidgetItem
              ? _buildWidgetCard(context, item as HomeWidgetItem)
              : _buildFolderCard(context, item as HomeFolderItem),
        ),
        // 编辑模式下显示拖拽手柄
        if (isEditMode && dragHandle != null)
          Positioned(
            top: 4,
            right: 4,
            child: dragHandle!,
          ),
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
                        : Theme.of(context).cardColor.withOpacity(0.8),
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

    // 编辑模式下不添加手势检测器，避免与拖拽冲突
    if (isEditMode) {
      return cardContent;
    }

    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context),
      onLongPress: onLongPress,
      child: cardContent,
    );
  }

  /// 构建小组件卡片
  Widget _buildWidgetCard(BuildContext context, HomeWidgetItem widgetItem) {
    final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

    if (widgetDef == null) {
      return _buildErrorCard(context, '小组件未找到: ${widgetItem.widgetId}');
    }

    try {
      // 获取背景配置
      final backgroundColor = widgetItem.config['backgroundColor'] != null
          ? Color(widgetItem.config['backgroundColor'] as int)
          : null;
      final backgroundImagePath = widgetItem.config['backgroundImage'] as String?;

      Widget content = widgetDef.build(context, widgetItem.config);

      // 如果有背景颜色或背景图,添加装饰容器
      if (backgroundColor != null || backgroundImagePath != null) {
        content = Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            image: backgroundImagePath != null && File(backgroundImagePath).existsSync()
                ? DecorationImage(
                    image: FileImage(File(backgroundImagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: content,
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
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
                  Icon(
                    folder.icon,
                    size: 40,
                    color: folder.color,
                  ),
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

  /// 构建错误卡片
  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 处理点击事件
  void _handleTap(BuildContext context) {
    if (item is HomeWidgetItem) {
      final widgetItem = item as HomeWidgetItem;
      final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

      if (widgetDef != null) {
        // 打开对应的插件
        final plugin = globalPluginManager.getPlugin(widgetDef.pluginId);
        if (plugin != null) {
          globalPluginManager.openPlugin(context, plugin);
        }
      }
    } else if (item is HomeFolderItem) {
      // 打开文件夹对话框（稍后实现）
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
