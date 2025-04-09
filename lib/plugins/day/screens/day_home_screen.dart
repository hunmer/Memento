import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../controllers/day_controller.dart';
import '../l10n/day_localizations.dart';
import '../widgets/memorial_day_card.dart';
import '../widgets/memorial_day_list_item.dart';
import '../widgets/edit_memorial_day_dialog.dart';
import '../models/memorial_day.dart';

class DayHomeScreen extends StatefulWidget {
  const DayHomeScreen({super.key});

  @override
  State<DayHomeScreen> createState() => _DayHomeScreenState();
}

class _DayHomeScreenState extends State<DayHomeScreen> {
  Future<void> _showEditDialog(BuildContext context, [MemorialDay? memorialDay]) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => EditMemorialDayDialog(memorialDay: memorialDay),
    );

    // 用户点击取消按钮
    if (result == 'cancel') {
      return;
    }
    
    // 用户点击删除按钮
    if (result == 'delete' && memorialDay != null) {
      if (!mounted) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(DayLocalizations.of(context).deleteMemorialDay),
          content: Text(DayLocalizations.of(context).deleteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(DayLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                DayLocalizations.of(context).delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _controller.deleteMemorialDay(memorialDay.id);
      }
    } else if (result != null && result is MemorialDay && mounted) {
      // 用户保存了更改
      if (memorialDay != null) {
        await _controller.updateMemorialDay(result);
      } else {
        await _controller.addMemorialDay(result);
      }
    }
  }

  late DayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DayController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DayController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(DayLocalizations.of(context).memorialDays),
              actions: [
                // 视图切换按钮
                // 排序模式切换按钮
                IconButton(
                  icon: Icon(controller.useCustomOrder ? Icons.sort : Icons.sort_by_alpha),
                  onPressed: controller.toggleSortMode,
                  tooltip: controller.useCustomOrder 
                    ? DayLocalizations.of(context).autoSort 
                    : DayLocalizations.of(context).manualSort,
                ),
                // 视图切换按钮
                IconButton(
                  icon: Icon(controller.isCardView ? Icons.view_list : Icons.view_module),
                  onPressed: controller.toggleView,
                  tooltip: controller.isCardView 
                    ? DayLocalizations.of(context).listView 
                    : DayLocalizations.of(context).cardView,
                ),
                // 添加纪念日按钮
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showEditDialog(context),
                  tooltip: DayLocalizations.of(context).addMemorialDay,
                ),
              ],
            ),
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(DayController controller) {
    if (controller.memorialDays.isEmpty) {
      return Center(
        child: Text(DayLocalizations.of(context).noMemorialDays),
      );
    }

    return controller.isCardView
        ? _buildCardView(controller.memorialDays)
        : _buildListView(controller.memorialDays);
  }

  Widget _buildCardView(List<MemorialDay> days) {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return MemorialDayCard(
          key: ValueKey(days[index].id),
          memorialDay: days[index],
          onTap: () => _showEditDialog(context, days[index]),
        );
      },
      onReorder: _controller.reorderMemorialDays,
      // 自定义拖拽装饰，移除边框
      dragWidgetBuilder: (index, child) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: Transform.scale(
            scale: 1.05,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildListView(List<MemorialDay> days) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return MemorialDayListItem(
          key: ValueKey(days[index].id),
          memorialDay: days[index],
          onTap: () => _showEditDialog(context, days[index]),
        );
      },
      onReorder: _controller.reorderMemorialDays,
      // 自定义拖拽装饰，移除边框
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              elevation: 0, // 无阴影
              color: Colors.transparent, // 透明背景
              borderRadius: BorderRadius.zero, // 无圆角
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }
}