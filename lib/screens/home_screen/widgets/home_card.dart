import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../core/plugin_manager.dart';
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

  const HomeCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context),
      onLongPress: onLongPress,
      child: Card(
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
    );
  }

  /// 构建小组件卡片
  Widget _buildWidgetCard(BuildContext context, HomeWidgetItem widgetItem) {
    final widgetDef = HomeWidgetRegistry().getWidget(widgetItem.widgetId);

    if (widgetDef == null) {
      return _buildErrorCard(context, '小组件未找到: ${widgetItem.widgetId}');
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widgetDef.build(context, widgetItem.config),
      );
    } catch (e) {
      return _buildErrorCard(context, '加载失败: $e');
    }
  }

  /// 构建文件夹卡片
  Widget _buildFolderCard(BuildContext context, HomeFolderItem folder) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                folder.icon,
                size: 48,
                color: folder.color,
              ),
              if (folder.children.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${folder.children.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            folder.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
