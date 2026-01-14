import 'package:flutter/material.dart';

/// 通用组件展示主界面
class WidgetsGalleryScreen extends StatelessWidget {
  const WidgetsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通用组件示例'),
      ),
      body: ListView(
        children: [
          // Picker 类组件
          _buildSectionHeader(context, 'Picker 选择器类'),
          _buildListItem(
            context,
            icon: Icons.palette,
            title: '颜色选择器',
            subtitle: 'ColorPickerSection',
            route: '/widgets_gallery/color_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.extension,
            title: '图标选择器',
            subtitle: 'IconPickerDialog',
            route: '/widgets_gallery/icon_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.face,
            title: '头像选择器',
            subtitle: 'AvatarPicker',
            route: '/widgets_gallery/avatar_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.circle,
            title: '圆形图标选择器',
            subtitle: 'CircleIconPicker',
            route: '/widgets_gallery/circle_icon_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.calendar_today,
            title: '日历条日期选择器',
            subtitle: 'CalendarStripDatePicker',
            route: '/widgets_gallery/calendar_strip_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.image,
            title: '图片选择器',
            subtitle: 'ImagePickerDialog',
            route: '/widgets_gallery/image_picker',
          ),
          _buildListItem(
            context,
            icon: Icons.location_on,
            title: '位置选择器',
            subtitle: 'LocationPicker',
            route: '/widgets_gallery/location_picker',
          ),

          const Divider(),

          // 编辑器类组件
          _buildSectionHeader(context, '编辑器类'),
          _buildListItem(
            context,
            icon: Icons.edit_document,
            title: 'Memento 编辑器',
            subtitle: 'MementoEditor',
            route: '/widgets_gallery/memento_editor',
          ),

          const Divider(),

          // 选择器类组件
          _buildSectionHeader(context, '选择器类'),
          _buildListItem(
            context,
            icon: Icons.table_chart,
            title: '数据选择器',
            subtitle: 'DataSelectorSheet',
            route: '/widgets_gallery/data_selector',
          ),
          _buildListItem(
            context,
            icon: Icons.group_work,
            title: '组选择器对话框',
            subtitle: 'GroupSelectorDialog',
            route: '/widgets_gallery/group_selector',
          ),
          _buildListItem(
            context,
            icon: Icons.group,
            title: '简单组选择器',
            subtitle: 'SimpleGroupSelector',
            route: '/widgets_gallery/simple_group_selector',
          ),

          const Divider(),

          // 日历类组件
          _buildSectionHeader(context, '日历类'),
          _buildListItem(
            context,
            icon: Icons.event,
            title: '增强日历',
            subtitle: 'EnhancedCalendar',
            route: '/widgets_gallery/enhanced_calendar',
          ),

          const Divider(),

          // 文件预览类
          _buildSectionHeader(context, '文件预览类'),
          _buildListItem(
            context,
            icon: Icons.preview,
            title: '文件预览',
            subtitle: 'FilePreviewScreen',
            route: '/widgets_gallery/file_preview',
          ),

          const Divider(),

          // 标签管理类
          _buildSectionHeader(context, '标签管理类'),
          _buildListItem(
            context,
            icon: Icons.label,
            title: '标签管理器',
            subtitle: 'TagManagerDialog',
            route: '/widgets_gallery/tag_manager',
          ),

          const Divider(),

          // 统计图表类
          _buildSectionHeader(context, '统计图表类'),
          _buildListItem(
            context,
            icon: Icons.bar_chart,
            title: '统计图表',
            subtitle: 'Statistics',
            route: '/widgets_gallery/statistics',
          ),

          const Divider(),

          // 对话框类
          _buildSectionHeader(context, '对话框类'),
          _buildListItem(
            context,
            icon: Icons.comment,
            title: '自定义对话框',
            subtitle: 'CustomDialog',
            route: '/widgets_gallery/custom_dialog',
          ),
          const Divider(),

          // 弹窗类
          _buildSectionHeader(context, '弹窗类'),
          _buildListItem(
            context,
            icon: Icons.vertical_align_bottom,
            title: '平滑底部弹窗',
            subtitle: 'SmoothBottomSheet',
            route: '/widgets_gallery/smooth_bottom_sheet',
          ),

          const Divider(),

          // 导航类
          _buildSectionHeader(context, '导航类'),
          _buildListItem(
            context,
            icon: Icons.menu,
            title: '应用抽屉',
            subtitle: 'AppDrawer',
            route: '/widgets_gallery/app_drawer',
          ),

          const Divider(),

          // 桌面小组件
          _buildSectionHeader(context, '桌面小组件'),
          _buildListItem(
            context,
            icon: Icons.widgets,
            title: '桌面小组件',
            subtitle: 'HomeWidgets - 各种桌面小组件示例',
            route: '/widgets_gallery/home_widgets',
          ),
          const Divider(),

          // 其他组件
          _buildSectionHeader(context, '其他组件'),
          _buildListItem(
            context,
            icon: Icons.apps,
            title: '小组件配置编辑器',
            subtitle: 'WidgetConfigEditor',
            route: '/widgets_gallery/widget_config_editor',
          ),
          _buildListItem(
            context,
            icon: Icons.tune,
            title: '预设编辑表单',
            subtitle: 'PresetEditForm',
            route: '/widgets_gallery/preset_edit_form',
          ),
          _buildListItem(
            context,
            icon: Icons.navigation,
            title: 'Super Cupertino 导航包装',
            subtitle: 'SuperCupertinoNavigationWrapper',
            route: '/widgets_gallery/super_cupertino_navigation',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
