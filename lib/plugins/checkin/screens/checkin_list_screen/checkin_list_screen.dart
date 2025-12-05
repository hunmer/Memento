import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import '../../controllers/checkin_list_controller.dart';
import '../../l10n/checkin_localizations.dart';
import '../../widgets/checkin_record_dialog.dart';
import 'components/empty_state.dart';
import 'components/checkin_item_card.dart';

class CheckinListScreen extends StatefulWidget {
  final CheckinListController controller;
  /// 可选的打卡项目ID，用于从小组件跳转时自动打开打卡记录对话框
  final String? initialItemId;
  /// 可选的目标日期（格式：YYYY-MM-DD），用于打开指定日期的打卡记录
  final String? targetDate;

  const CheckinListScreen({
    super.key,
    required this.controller,
    this.initialItemId,
    this.targetDate,
  });

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

      // 如果指定了 initialItemId，则自动打开对应的打卡记录对话框
      if (widget.initialItemId != null && mounted) {
        _showCheckinDialogForItem(widget.initialItemId!, widget.targetDate);
      }
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

    return SuperCupertinoNavigationWrapper(
      title: Text(CheckinLocalizations.of(context).name),
      largeTitle: '签到记录',
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
      enableLargeTitle: false,
      automaticallyImplyLeading: false,
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

  /// 根据 itemId 显示打卡记录对话框
  void _showCheckinDialogForItem(String itemId, [String? targetDate]) {
    // 查找对应的打卡项目
    final item = controller.checkinItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('未找到ID为 $itemId 的打卡项目'),
    );

    // 解析目标日期
    DateTime? selectedDate;
    if (targetDate != null && targetDate.isNotEmpty) {
      try {
        final parts = targetDate.split('-');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {
        debugPrint('解析日期失败: $targetDate, 错误: $e');
      }
    }

    // 延迟一帧以确保界面完全加载
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => CheckinRecordDialog(
          item: item,
          controller: controller,
          onCheckinCompleted: _handleStateChanged,
          selectedDate: selectedDate,
        ),
      );
    });
  }
}
