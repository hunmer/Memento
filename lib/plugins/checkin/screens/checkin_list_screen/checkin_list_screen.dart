import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../controllers/checkin_list_controller.dart';
import '../../l10n/checkin_localizations.dart';
import 'components/empty_state.dart';
import 'components/checkin_item_card.dart';

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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = controller.filteredItems;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[50],
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(CheckinLocalizations.of(context).name),
        actions: [
          // 排序按钮
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () async {
              await controller.showGroupSortDialog();
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: controller.showGroupManagementDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 分组过滤器
          _buildFilterBar(),

          // 打卡项目列表
          Expanded(
            child:
                filteredItems.isEmpty
                    ? const EmptyState()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: StaggeredGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          children:
                              filteredItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return StaggeredGridTile.fit(
                                  crossAxisCellCount:
                                      item.cardStyle == CheckinCardStyle.small
                                          ? 1
                                          : 2,
                                  child: CheckinItemCard(
                                    item: item,
                                    index: index,
                                    itemIndex: index,
                                    controller: controller,
                                    onStateChanged: _handleStateChanged,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     await controller.showAddCheckinItemDialog(
      //       group:
      //           controller.selectedGroup == '全部'
      //               ? null
      //               : controller.selectedGroup,
      //     );
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildFilterBar() {
    final groups = controller.groups;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group == controller.selectedGroup;
          return ChoiceChip(
            label: Text(group),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectGroup(group);
              }
            },
            showCheckmark: false,
            labelStyle: TextStyle(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }
}
