/// 上次活动小组件数据提供者
library;

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'utils.dart';

/// 上次活动小组件数据提供者
///
/// 返回最近一个活动的数据，用于上次活动小组件
Future<Map<String, Map<String, dynamic>>> provideLastActivityWidgets(
  Map<String, dynamic> config,
) async {
  final plugin =
      PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
  if (plugin == null) return {};

  // 获取最近的活动
  final lastActivity = await plugin.activityService.getLastActivity();
  if (lastActivity == null) {
    return {
      'activityLastActivity': {
        'hasActivity': false,
        'message': '暂无活动记录',
      },
    };
  }

  final now = DateTime.now();
  final endTime = lastActivity.endTime;
  final timeDiff = now.difference(endTime);

  // 格式化时间差
  String timeAgo;
  if (timeDiff.inMinutes < 1) {
    timeAgo = '刚刚';
  } else if (timeDiff.inHours < 1) {
    timeAgo = '${timeDiff.inMinutes}分钟前';
  } else if (timeDiff.inDays < 1) {
    timeAgo = '${timeDiff.inHours}小时前';
  } else {
    timeAgo = '${timeDiff.inDays}天前';
  }

  // 活动标题
  final title =
      lastActivity.title.trim().isEmpty ? '未命名活动' : lastActivity.title;

  // 计算持续时长
  final duration = lastActivity.endTime.difference(lastActivity.startTime);
  final durationText = formatDurationForDisplay(duration.inMinutes);

  // 构建副标题信息
  final List<String> subtitleParts = [];

  // 添加心情
  if (lastActivity.mood != null && lastActivity.mood!.isNotEmpty) {
    subtitleParts.add(lastActivity.mood!);
  }

  // 添加标签
  if (lastActivity.tags.isNotEmpty) {
    subtitleParts.add(lastActivity.tags.join(', '));
  }

  // 添加持续时长
  subtitleParts.add(durationText);

  // 活动颜色
  final color = lastActivity.color?.value ?? 0xFFE91E63;

  return {
    'activityLastActivity': {
      'hasActivity': true,
      'timeAgo': timeAgo,
      'title': title,
      'subtitle': subtitleParts.join(' · '),
      'color': color,
      'duration': durationText,
      'mood': lastActivity.mood ?? '',
      'tags': lastActivity.tags,
    },
  };
}
