/// 日历相册插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerWeeklyAlbumWidget] - 4x1 本周相册组件
/// - [registerPhotoCarouselWidget] - 2x2/4x2/4x3 图片轮播组件
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_weekly_album_widget.dart';
import 'register_photo_carousel_widget.dart';

/// 注册所有日历相册插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerWeeklyAlbumWidget(registry);
  registerPhotoCarouselWidget(registry);
}
