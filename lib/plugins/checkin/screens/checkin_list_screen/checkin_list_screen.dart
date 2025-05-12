import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../../controllers/checkin_list_controller.dart';
import '../../l10n/checkin_localizations.dart';
import 'components/statistics_section.dart';
import 'components/empty_state.dart';
import 'components/group_list_view.dart';

class CheckinListScreen extends StatefulWidget {
  final CheckinListController controller;

  const CheckinListScreen({super.key, required this.controller});

  @override
  State<CheckinListScreen> createState() => _CheckinListScreenState();
}

class _CheckinListScreenState extends State<CheckinListScreen> {
  late CheckinListController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    // 恢复最后一次排序设置
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.restoreLastSortSetting();
      if (mounted) setState(() {});
    });
  }

  void _handleStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupListItems = controller.buildGroupListItems();
    final statistics = controller.getStatistics();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(CheckinLocalizations.of(context)?.checkinPluginName ?? '打卡'),
        actions: [
          // 排序按钮
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () async {
              await controller.showGroupSortDialog();
              if (mounted) setState(() {});
            },
            tooltip: '排序',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: controller.showGroupManagementDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部统计信息
          StatisticsSection(statistics: statistics),

          // 分组列表
          Expanded(
            child: groupListItems.isEmpty
                ? EmptyState()
                : GroupListView(
                    groupListItems: groupListItems,
                    controller: controller,
                    onStateChanged: _handleStateChanged,
                  ),
          ),
        ],
      ),
    );
  }
}