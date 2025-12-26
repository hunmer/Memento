import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';

/// 路由信息数据模型
class RouteInfo {
  final String path;
  final String name;
  final String plugin;
  final IconData? icon;

  const RouteInfo({
    required this.path,
    required this.name,
    this.plugin = '核心',
    this.icon,
  });
}

/// 路由查看器对话框
class RouteViewerDialog extends StatefulWidget {
  const RouteViewerDialog({super.key});

  @override
  State<RouteViewerDialog> createState() => _RouteViewerDialogState();

  /// 显示路由查看器对话框
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: const RouteViewerDialog(),
          ),
        );
      },
    );
  }
}

class _RouteViewerDialogState extends State<RouteViewerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// 预定义的路由分组数据
  final Map<String, List<RouteInfo>> _routesByPlugin = {
    '核心功能': [
      const RouteInfo(path: '/', name: '首页', icon: Icons.home),
      const RouteInfo(path: '/settings', name: '设置', icon: Icons.settings),
      const RouteInfo(path: '/js_console', name: 'JS 控制台', icon: Icons.code),
      const RouteInfo(path: '/data_selector_test', name: '数据选择器测试', icon: Icons.assignment),
      const RouteInfo(path: '/swipe_action_test', name: '滑动操作测试', icon: Icons.swipe),
      const RouteInfo(path: '/widgets_gallery', name: '组件库', icon: Icons.widgets),
      const RouteInfo(path: '/form_fields_test', name: '表单字段测试', icon: Icons.input),
    ],
    '插件': [
      const RouteInfo(path: '/chat', name: '聊天', icon: Icons.chat),
      const RouteInfo(path: '/diary', name: '日记', icon: Icons.book),
      const RouteInfo(path: '/diary_detail', name: '日记详情', icon: Icons.bookmark),
      const RouteInfo(path: '/activity', name: '活动', icon: Icons.event),
      const RouteInfo(path: '/checkin', name: '打卡', icon: Icons.check_circle),
      const RouteInfo(path: '/agent_chat', name: 'Agent 聊天', icon: Icons.smart_toy),
      const RouteInfo(path: '/bill', name: '记账', icon: Icons.account_balance_wallet),
      const RouteInfo(path: '/calendar', name: '日历', icon: Icons.calendar_month),
      const RouteInfo(path: '/calendar_album', name: '相册', icon: Icons.photo_library),
      const RouteInfo(path: '/contact', name: '联系人', icon: Icons.contacts),
      const RouteInfo(path: '/database', name: '数据库', icon: Icons.storage),
      const RouteInfo(path: '/day', name: '每日', icon: Icons.today),
      const RouteInfo(path: '/goods', name: '商品', icon: Icons.shopping_bag),
      const RouteInfo(path: '/habits', name: '习惯', icon: Icons.track_changes),
      const RouteInfo(path: '/nodes', name: '节点', icon: Icons.account_tree),
      const RouteInfo(path: '/notes', name: '笔记', icon: Icons.note),
      const RouteInfo(path: '/openai', name: 'OpenAI', icon: Icons.auto_awesome),
      const RouteInfo(path: '/scripts_center', name: '脚本中心', icon: Icons.code),
      const RouteInfo(path: '/store', name: '商店', icon: Icons.store),
      const RouteInfo(path: '/timer', name: '计时器', icon: Icons.timer),
      const RouteInfo(path: '/todo', name: '待办', icon: Icons.checklist),
      const RouteInfo(path: '/tracker', name: '追踪', icon: Icons.trending_up),
      const RouteInfo(path: '/tts', name: '语音服务', icon: Icons.record_voice_over),
      const RouteInfo(path: '/floating_ball', name: '悬浮球', icon: Icons.circle),
    ],
    '小组件配置': [
      const RouteInfo(path: '/calendar_month_selector', name: '日历月视图配置', icon: Icons.calendar_view_month),
      const RouteInfo(path: '/tracker_goal_selector', name: '目标选择配置', icon: Icons.flag),
      const RouteInfo(path: '/tracker_goal_progress_selector', name: '目标进度配置', icon: Icons.linear_scale),
      const RouteInfo(path: '/habit_timer_selector', name: '习惯计时器配置', icon: Icons.timer),
      const RouteInfo(path: '/bill_shortcuts_selector', name: '快捷记账配置', icon: Icons.add_card),
      const RouteInfo(path: '/activity_weekly_config', name: '活动周视图配置', icon: Icons.date_range),
      const RouteInfo(path: '/activity_daily_config', name: '活动日视图配置', icon: Icons.event_note),
      const RouteInfo(path: '/habits_weekly_config', name: '习惯周视图配置', icon: Icons.date_range),
      const RouteInfo(path: '/habit_group_list_selector', name: '习惯分组配置', icon: Icons.list_alt),
      const RouteInfo(path: '/calendar_album_weekly_selector', name: '相册周视图配置', icon: Icons.photo_album),
      const RouteInfo(path: '/checkin_item_selector', name: '打卡项选择', icon: Icons.check_box),
      const RouteInfo(path: '/todo_list_selector', name: '待办列表选择', icon: Icons.playlist_add_check),
      const RouteInfo(path: '/todo_task_detail', name: '待办任务详情', icon: Icons.task_alt),
      const RouteInfo(path: '/todo_add', name: '添加待办', icon: Icons.add_task),
      const RouteInfo(path: '/tag_statistics', name: '标签统计', icon: Icons.tag),
    ],
    '错误页面': [
      const RouteInfo(path: '/calendar_month/event', name: '日历事件详情', icon: Icons.event),
      const RouteInfo(path: '/habit_timer_dialog', name: '习惯计时器', icon: Icons.timer),
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 根据搜索过滤路由
  Map<String, List<RouteInfo>> _filterRoutes(String query) {
    if (query.isEmpty) return _routesByPlugin;

    final lowerQuery = query.toLowerCase();
    final filtered = <String, List<RouteInfo>>{};

    for (final entry in _routesByPlugin.entries) {
      final filteredRoutes = entry.value.where((route) {
        return route.path.toLowerCase().contains(lowerQuery) ||
            route.name.toLowerCase().contains(lowerQuery) ||
            route.plugin.toLowerCase().contains(lowerQuery);
      }).toList();

      if (filteredRoutes.isNotEmpty) {
        filtered[entry.key] = filteredRoutes;
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = _filterRoutes(_searchQuery);

    return SuperCupertinoNavigationWrapper(
      title: const Text('路由查看器'),
      largeTitle: '路由查看器',
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: '搜索路由...',
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
      },
      body: filteredRoutes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未找到匹配的路由',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: filteredRoutes.entries.expand((entry) {
                return [
                  _buildSectionHeader(entry.key),
                  ...entry.value.map((route) => _buildRouteTile(route)),
                  const SizedBox(height: 16),
                ];
              }).toList(),
            ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 构建路由项
  Widget _buildRouteTile(RouteInfo route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          route.icon ?? Icons.route,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(route.name),
        subtitle: Text(
          route.path,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('路由: ${route.path}'),
              action: SnackBarAction(
                label: '复制',
                onPressed: () {},
              ),
            ),
          );
          try {
            Navigator.pushNamed(context, route.path);
          } catch (e) {
            debugPrint('导航到 ${route.path} 失败: $e');
          }
        },
      ),
    );
  }
}
