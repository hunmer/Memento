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
import 'package:Memento/screens/widgets_gallery/screens/home_widgets_gallery_screen.dart';
import 'package:Memento/screens/widgets_gallery/screens/half_circle_gauge_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/widget_config_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/preset_edit_form_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/super_cupertino_navigation_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/segmented_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/milestone_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circular_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_progress_with_dots_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/multi_tracker_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/line_chart_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/article_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_line_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_ring_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_bar_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/earnings_trend_card_example.dart';

/// 组件展示路由注册表
class WidgetGalleryRoutes implements RouteRegistry {
  @override
  String get name => 'WidgetGalleryRoutes';

  @override
  List<RouteDefinition> get routes => [
        // 组件展示主页
        RouteDefinition(
          path: '/widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen(), settings: settings),
          description: '组件展示主页',
        ),
        RouteDefinition(
          path: 'widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen(), settings: settings),
          description: '组件展示主页（别名）',
        ),

        // 各组件示例
        RouteDefinition(
          path: '/widgets_gallery/color_picker',
          handler: (settings) => RouteHelpers.createRoute(const ColorPickerExample(), settings: settings),
          description: '颜色选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const IconPickerExample(), settings: settings),
          description: '图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/avatar_picker',
          handler: (settings) => RouteHelpers.createRoute(const AvatarPickerExample(), settings: settings),
          description: '头像选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circle_icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const CircleIconPickerExample(), settings: settings),
          description: '圆形图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/calendar_strip_picker',
          handler: (settings) => RouteHelpers.createRoute(const CalendarStripPickerExample(), settings: settings),
          description: '日历条选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/image_picker',
          handler: (settings) => RouteHelpers.createRoute(const ImagePickerExample(), settings: settings),
          description: '图片选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/location_picker',
          handler: (settings) => RouteHelpers.createRoute(const LocationPickerExample(), settings: settings),
          description: '位置选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/backup_time_picker',
          handler: (settings) => RouteHelpers.createRoute(const BackupTimePickerExample(), settings: settings),
          description: '备份时间选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/memento_editor',
          handler: (settings) => RouteHelpers.createRoute(const MementoEditorExample(), settings: settings),
          description: '编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/data_selector',
          handler: (settings) => RouteHelpers.createRoute(const DataSelectorExample(), settings: settings),
          description: '数据选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/enhanced_calendar',
          handler: (settings) => RouteHelpers.createRoute(const EnhancedCalendarExample(), settings: settings),
          description: '增强日历示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/group_selector',
          handler: (settings) => RouteHelpers.createRoute(const GroupSelectorExample(), settings: settings),
          description: '分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/simple_group_selector',
          handler: (settings) => RouteHelpers.createRoute(const SimpleGroupSelectorExample(), settings: settings),
          description: '简单分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/tag_manager',
          handler: (settings) => RouteHelpers.createRoute(const TagManagerExample(), settings: settings),
          description: '标签管理器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/statistics',
          handler: (settings) => RouteHelpers.createRoute(const StatisticsExample(), settings: settings),
          description: '统计组件示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/custom_dialog',
          handler: (settings) => RouteHelpers.createRoute(const CustomDialogExample(), settings: settings),
          description: '自定义对话框示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/smooth_bottom_sheet',
          handler: (settings) => RouteHelpers.createRoute(const SmoothBottomSheetExample(), settings: settings),
          description: '底部面板示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/file_preview',
          handler: (settings) => RouteHelpers.createRoute(const FilePreviewExample(), settings: settings),
          description: '文件预览示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/app_drawer',
          handler: (settings) => RouteHelpers.createRoute(const AppDrawerExample(), settings: settings),
          description: '抽屉示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/home_widgets',
          handler: (settings) => RouteHelpers.createRoute(const HomeWidgetsGalleryScreen(), settings: settings),
          description: '桌面小组件示例列表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/half_circle_gauge_widget',
          handler: (settings) => RouteHelpers.createRoute(const HalfCircleGaugeWidgetExample(), settings: settings),
          description: '半圆仪表盘示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/widget_config_editor',
          handler: (settings) => RouteHelpers.createRoute(const WidgetConfigEditorExample(), settings: settings),
          description: '组件配置编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/preset_edit_form',
          handler: (settings) => RouteHelpers.createRoute(const PresetEditFormExample(), settings: settings),
          description: '预设编辑表单示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/super_cupertino_navigation',
          handler: (settings) => RouteHelpers.createRoute(const SuperCupertinoNavigationExample(), settings: settings),
          description: '导航示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/segmented_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const SegmentedProgressCardExample(), settings: settings),
          description: '分段进度条统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/milestone_card',
          handler: (settings) => RouteHelpers.createRoute(const MilestoneCardExample(), settings: settings),
          description: '里程碑追踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circular_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const CircularProgressCardExample(), settings: settings),
          description: '圆形进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/monthly_progress_with_dots_card',
          handler: (settings) => RouteHelpers.createRoute(const MonthlyProgressWithDotsCardExample(), settings: settings),
          description: '月度进度圆点卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/multi_tracker_card',
          handler: (settings) => RouteHelpers.createRoute(const MultiTrackerCardExample(), settings: settings),
          description: '多追踪器卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/line_chart_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const LineChartTrendCardExample(), settings: settings),
          description: '折线图趋势卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/article_list_card',
          handler: (settings) => RouteHelpers.createRoute(const ArticleListCardExample(), settings: settings),
          description: '文章列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/vertical_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const VerticalBarChartCardExample(), settings: settings),
          description: '垂直柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/trend_line_chart_widget',
          handler: (settings) => RouteHelpers.createRoute(const TrendLineChartWidgetExample(), settings: settings),
          description: '趋势折线图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const StackedBarChartCardExample(), settings: settings),
          description: '堆叠柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_bar_chart_widget',
          handler: (settings) => RouteHelpers.createRoute(const StackedBarChartWidgetExample(), settings: settings),
          description: '堆叠条形图组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_ring_chart',
          handler: (settings) => RouteHelpers.createRoute(const StackedRingChartExample(), settings: settings),
          description: '堆叠环形图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/monthly_bar_chart',
          handler: (settings) => RouteHelpers.createRoute(const MonthlyBarChartExample(), settings: settings),
          description: '月度柱状图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/earnings_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const EarningsTrendCardExample(), settings: settings),
          description: '收益趋势卡片',
        ),
      ];
}
