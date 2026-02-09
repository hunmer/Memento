/// 笔记插件 - 快捷创建组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'utils.dart' show notesColor, extractFolderData;

/// 注册快捷创建小组件（1x1 文件夹快捷创建组件）
void registerQuickCreateWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_folder_quick_create',
      pluginId: 'notes',
      name: 'notes_quickCreate'.tr,
      description: 'notes_quickCreateDesc'.tr,
      icon: Icons.add_circle_outline,
      color: notesColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      selectorId: 'notes.folder',
      dataRenderer: _renderQuickCreateData,
      navigationHandler: _navigateToQuickCreate,
      dataSelector: extractFolderData,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('notes_folder_quick_create')!,
          config: config,
        );
      },
    ),
  );
}

/// 渲染快捷创建小组件数据
Widget _renderQuickCreateData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final theme = Theme.of(context);
  final folderData = result.data as Map<String, dynamic>;

  final name = folderData['name'] as String? ?? '未命名文件夹';
  final folderPath = folderData['folderPath'] as String? ?? '';
  final iconCodePoint = folderData['icon'] as int?;
  final colorValue = folderData['color'] as int?;

  final folderIcon =
      iconCodePoint != null
          ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
          : Icons.folder;
  final folderColor = colorValue != null ? Color(colorValue) : notesColor;

  final displayName = folderPath.isNotEmpty ? folderPath : name;

  return SizedBox.expand(
    child: Container(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标在中间，标题在下边，图标右上角带加号 badge
            Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                Icon(folderIcon, size: 40, color: folderColor),
                // 图标右上角加号 badge
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: folderColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primaryContainer,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 导航到快捷创建笔记
void _navigateToQuickCreate(
  BuildContext context,
  SelectorResult result,
) {
  // 从 result.data 获取 folderId
  final folderData = result.data as Map<String, dynamic>?;
  final folderId = folderData?['id'] as String? ?? 'root';

  // 通过路由跳转到笔记编辑页面
  NavigationHelper.pushNamed(
    context,
    '/notes/create',
    arguments: {'folderId': folderId},
  );
}
