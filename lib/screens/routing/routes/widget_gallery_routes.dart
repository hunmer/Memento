import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/screens/widgets_gallery/widgets_gallery_screen.dart';
import 'package:Memento/screens/widgets_gallery/screens/color_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/avatar_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circle_icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/calendar_strip_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/image_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/location_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/backup_time_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/memento_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/data_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/enhanced_calendar_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/simple_group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/tag_manager_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/statistics_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/custom_dialog_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/smooth_bottom_sheet_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/file_preview_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/app_drawer_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/half_circle_gauge_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/widget_config_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/preset_edit_form_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/super_cupertino_navigation_example.dart';

/// 组件展示路由注册表
class WidgetGalleryRoutes implements RouteRegistry {
  @override
  String get name => 'WidgetGalleryRoutes';

  @override
  List<RouteDefinition> get routes => [
        // 组件展示主页
        RouteDefinition(
          path: '/widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen()),
          description: '组件展示主页',
        ),
        RouteDefinition(
          path: 'widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen()),
          description: '组件展示主页（别名）',
        ),

        // 各组件示例
        RouteDefinition(
          path: '/widgets_gallery/color_picker',
          handler: (settings) => RouteHelpers.createRoute(const ColorPickerExample()),
          description: '颜色选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const IconPickerExample()),
          description: '图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/avatar_picker',
          handler: (settings) => RouteHelpers.createRoute(const AvatarPickerExample()),
          description: '头像选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circle_icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const CircleIconPickerExample()),
          description: '圆形图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/calendar_strip_picker',
          handler: (settings) => RouteHelpers.createRoute(const CalendarStripPickerExample()),
          description: '日历条选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/image_picker',
          handler: (settings) => RouteHelpers.createRoute(const ImagePickerExample()),
          description: '图片选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/location_picker',
          handler: (settings) => RouteHelpers.createRoute(const LocationPickerExample()),
          description: '位置选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/backup_time_picker',
          handler: (settings) => RouteHelpers.createRoute(const BackupTimePickerExample()),
          description: '备份时间选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/memento_editor',
          handler: (settings) => RouteHelpers.createRoute(const MementoEditorExample()),
          description: '编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/data_selector',
          handler: (settings) => RouteHelpers.createRoute(const DataSelectorExample()),
          description: '数据选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/enhanced_calendar',
          handler: (settings) => RouteHelpers.createRoute(const EnhancedCalendarExample()),
          description: '增强日历示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/group_selector',
          handler: (settings) => RouteHelpers.createRoute(const GroupSelectorExample()),
          description: '分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/simple_group_selector',
          handler: (settings) => RouteHelpers.createRoute(const SimpleGroupSelectorExample()),
          description: '简单分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/tag_manager',
          handler: (settings) => RouteHelpers.createRoute(const TagManagerExample()),
          description: '标签管理器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/statistics',
          handler: (settings) => RouteHelpers.createRoute(const StatisticsExample()),
          description: '统计组件示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/custom_dialog',
          handler: (settings) => RouteHelpers.createRoute(const CustomDialogExample()),
          description: '自定义对话框示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/smooth_bottom_sheet',
          handler: (settings) => RouteHelpers.createRoute(const SmoothBottomSheetExample()),
          description: '底部面板示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/file_preview',
          handler: (settings) => RouteHelpers.createRoute(const FilePreviewExample()),
          description: '文件预览示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/app_drawer',
          handler: (settings) => RouteHelpers.createRoute(const AppDrawerExample()),
          description: '抽屉示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/half_circle_gauge_widget',
          handler: (settings) => RouteHelpers.createRoute(const HalfCircleGaugeWidgetExample()),
          description: '半圆仪表盘示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/widget_config_editor',
          handler: (settings) => RouteHelpers.createRoute(const WidgetConfigEditorExample()),
          description: '组件配置编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/preset_edit_form',
          handler: (settings) => RouteHelpers.createRoute(const PresetEditFormExample()),
          description: '预设编辑表单示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/super_cupertino_navigation',
          handler: (settings) => RouteHelpers.createRoute(const SuperCupertinoNavigationExample()),
          description: '导航示例',
        ),
      ];
}
