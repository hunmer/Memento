import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../controllers/checkin_list_controller.dart';
import '../models/checkin_item.dart';
import '../widgets/checkin_record_dialog.dart';
import '../screens/checkin_record_screen.dart';
import 'package:intl/intl.dart';

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
  }

  void _handleStateChanged() {
    if (mounted) {
      // 使用 SchedulerBinding 确保在下一帧渲染前更新状态
      // 这样可以避免在布局过程中触发状态更新导致的异常
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
        title: const Text('打卡'),
        actions: [
          IconButton(
            icon: Icon(controller.isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              controller.toggleEditMode();
              _handleStateChanged();
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
          // 顶部统计信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  '总项目',
                  '${statistics['totalItems']}',
                  Icons.list_alt,
                ),
                _buildStatCard(
                  context,
                  '今日打卡数',
                  '${statistics['todayCheckins'] ?? 0}',
                  Icons.today,
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // 分组列表
          Expanded(
            child:
                groupListItems.isEmpty
                    ? _buildEmptyState(context)
                    : ReorderableListView.builder(
                      buildDefaultDragHandles: false, // 禁用默认拖拽手柄
                      itemCount: groupListItems.length,
                      onReorder: (oldIndex, newIndex) {
                        if (controller.isEditMode) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }

                            // 获取所有项目
                            final allItems = <CheckinItem>[];
                            final groupOrder = <String>[];

                            // 记录原始分组顺序
                            for (var groupData in groupListItems) {
                              final group = groupData['group'] as String;
                              groupOrder.add(group);
                              allItems.addAll(
                                (groupData['items'] as List<dynamic>)
                                    .cast<CheckinItem>(),
                              );
                            }

                            // 重新排序分组
                            final movedGroup = groupOrder.removeAt(oldIndex);
                            groupOrder.insert(newIndex, movedGroup);

                            // 按新的分组顺序重新组织项目
                            final newItems = <CheckinItem>[];
                            for (var group in groupOrder) {
                              for (var item in allItems) {
                                if (item.group == group) {
                                  newItems.add(item);
                                }
                              }
                            }

                            // 更新 checkinItems
                            controller.checkinItems.clear();
                            controller.checkinItems.addAll(newItems);
                            _handleStateChanged();
                          });
                        }
                      },
                      itemBuilder: (context, groupIndex) {
                        final groupData = groupListItems[groupIndex];
                        final group = groupData['group'] as String;
                        final items =
                            (groupData['items'] as List<dynamic>)
                                .cast<CheckinItem>();
                        final completedCount =
                            groupData['completedCount'] as int;
                        final total = groupData['total'] as int;
                        final isExpanded =
                            controller.expandedGroups[group] ?? true;

                        return Card(
                          key: ValueKey('group_${group}_$groupIndex'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          elevation: 2,
                          child: Column(
                            children: [
                              // 分组标题
                              ListTile(
                                title: Text(
                                  group,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$completedCount/$total 已完成',
                                  style: TextStyle(
                                    color:
                                        completedCount == total
                                            ? Colors.green
                                            : Theme.of(context).hintColor,
                                  ),
                                ),
                                leading: const Icon(Icons.folder),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (controller.isEditMode) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          controller
                                              .showGroupManagementDialog();
                                        },
                                      ),
                                      // 分组拖拽手柄
                                      ReorderableDragStartListener(
                                        index: groupIndex,
                                        child: const Icon(Icons.drag_handle),
                                      ),
                                    ],
                                    IconButton(
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                      onPressed: () {
                                        controller.expandedGroups[group] =
                                            !isExpanded;
                                        _handleStateChanged();
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // 分组内的打卡项目
                              if (isExpanded)
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: _buildItemList(
                                    items,
                                    group,
                                    groupIndex,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.showAddCheckinItemDialog();
          _handleStateChanged();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 构建分组内项目列表（支持拖拽排序）
  Widget _buildItemList(List<CheckinItem> items, String group, int groupIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              controller.isEditMode
                  ? _buildReorderableList(items, group, constraints)
                  : _buildNormalList(items),
        );
      },
    );
  }

  Widget _buildNormalList(List<CheckinItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemTile(items[index], false),
    );
  }

  Widget _buildReorderableList(
    List<CheckinItem> items,
    String group,
    BoxConstraints constraints,
  ) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: constraints.maxWidth,
        child: ReorderableListView.builder(
          key: ValueKey('inner_reorderable_$group'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: items.length,
          itemBuilder:
              (context, index) => Container(
                key: ValueKey('${group}_item_${items[index].id}_$index'),
                child: _buildItemTile(items[index], true, index),
              ),
          proxyDecorator:
              (child, index, animation) => Material(
                elevation: 2,
                color: Colors.transparent,
                child: child,
              ),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              // 更新 controller 中的 checkinItems
              controller.updateItemsOrder(group, items);
            });
          },
        ),
      ),
    );
  }

  // 构建单个打卡项目的 ListTile
  Widget _buildItemTile(CheckinItem item, bool isEditMode, [int? index]) {
    Widget trailing;

    if (isEditMode) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => controller.showItemOptionsDialog(item),
          ),
          if (index != null)
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
        ],
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text(''),
            onPressed: () async {
              final record = await showDialog<CheckinRecord>(
                context: context,
                builder: (context) => CheckinRecordDialog(checkinItem: item),
              );
              if (record != null) {
                await item.addCheckinRecord(record);
                _handleStateChanged();
              }
            },
            style: TextButton.styleFrom(foregroundColor: item.color),
          ),
        ],
      );
    }

    final tile = ListTile(
      leading: Icon(item.icon, color: item.color),
      title: Row(
        children: [
          Expanded(child: Text(item.name)),
          // 仅在非编辑模式下显示周打卡记录
          if (!isEditMode) _buildWeekCircles(item),
        ],
      ),
      onTap:
          isEditMode
              ? null
              : () async {
                if (item.isCheckedToday()) {
                  // 获取今天的所有打卡记录并取消第一个
                  final todayRecords = item.getTodayRecords();
                  if (todayRecords.isNotEmpty) {
                    // 找到对应的记录键
                    DateTime? recordKey;
                    item.checkInRecords.forEach((key, value) {
                      if (value == todayRecords.first) {
                        recordKey = key;
                      }
                    });

                    if (recordKey != null) {
                      await item.cancelCheckinRecord(recordKey!);
                    }
                  }
                }
                _handleStateChanged();

                // 打开详情页面
                if (mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CheckinRecordScreen(checkinItem: item),
                    ),
                  );
                  _handleStateChanged();
                }
              },
      trailing: trailing,
    );

    // 编辑模式下添加视觉反馈
    if (isEditMode) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(51), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text('没有打卡项目', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加新的打卡项目',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCircles(CheckinItem item) {
    final today = DateTime.now();
    final dateFormat = DateFormat('d');
    final weekDays = List.generate(
      7,
      (index) => today.subtract(Duration(days: 3 - index)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          weekDays.map((date) {
            // 检查该日期是否有打卡记录
            final hasRecord = item.checkInRecords.keys.any(
              (key) =>
                  key.year == date.year &&
                  key.month == date.month &&
                  key.day == date.day,
            );
            final isToday =
                date.day == today.day &&
                date.month == today.month &&
                date.year == today.year;

            return Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    hasRecord
                        ? Colors.green
                        : (isToday
                            ? Colors.blue.withAlpha(77)
                            : Colors.grey.withAlpha(51)),
                border:
                    isToday ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Stack(
                clipBehavior: Clip.none, // 允许子组件超出边界
                children: [
                  Center(
                    child: Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color:
                            hasRecord || isToday ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 获取当日记录数量
                  Builder(
                    builder: (context) {
                      // 计算当日记录数量
                      final recordCount =
                          item.checkInRecords.entries
                              .where(
                                (entry) =>
                                    entry.key.year == date.year &&
                                    entry.key.month == date.month &&
                                    entry.key.day == date.day,
                              )
                              .length;

                      // 如果记录数量大于1，显示红点和数量
                      if (recordCount > 1) {
                        return Positioned(
                          right: -6, // 向右偏移以显示在圆圈外
                          bottom: -6, // 向下偏移以显示在圆圈外
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                recordCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // 如果没有多条记录，不显示任何内容
                    },
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
