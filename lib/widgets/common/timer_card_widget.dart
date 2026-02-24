import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/timer/views/timer_task_details_page.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// 计时器任务卡片小组件
///
/// 显示计时器任务卡片，支持播放/暂停/重置功能，
/// 可以通过配置参数自定义显示样式。
///
/// 特性：
/// - 显示任务图标和名称
/// - 显示计时器进度和状态
/// - 支持播放/暂停/重置控制
/// - 支持长按显示操作菜单
/// - 支持点击进入详情页
/// - 自定义颜色和样式
/// - 响应式布局适配
class TimerCardWidget extends StatefulWidget {
  /// 计时器任务数据
  final TimerTask task;

  /// 卡片点击回调
  final Function(TimerTask)? onTap;

  /// 编辑回调
  final Function(TimerTask)? onEdit;

  /// 重置回调
  final Function(TimerTask)? onReset;

  /// 删除回调
  final Function(TimerTask)? onDelete;

  /// 自定义边框颜色（可选）
  final Color? borderColor;

  /// 自定义背景颜色（可选）
  final Color? backgroundColor;

  /// 自定义文字颜色（可选）
  final Color? textColor;

  /// 是否显示操作按钮
  final bool showActionButtons;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 是否显示分组名称
  final bool showGroup;

  /// 是否使用网格布局（当计时器数量 >= 3 时）
  final bool useGridLayout;

  const TimerCardWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onReset,
    this.onDelete,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.showActionButtons = true,
    this.size = const MediumSize(),
    this.showGroup = false,
    this.useGridLayout = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory TimerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 如果 task 是 JSON 数据，需要解析
    TimerTask task;
    if (props['task'] is Map<String, dynamic>) {
      task = TimerTask.fromJson(props['task']);
    } else {
      // 假设 task 是 TimerTask 对象
      task = props['task'];
    }

    return TimerCardWidget(
      task: task,
      onTap:
          props['onTap'] != null
              ? (task) => (props['onTap'] as Function)(task)
              : null,
      onEdit:
          props['onEdit'] != null
              ? (task) => (props['onEdit'] as Function)(task)
              : null,
      onReset:
          props['onReset'] != null
              ? (task) => (props['onReset'] as Function)(task)
              : null,
      onDelete:
          props['onDelete'] != null
              ? (task) => (props['onDelete'] as Function)(task)
              : null,
      borderColor:
          props['borderColor'] != null
              ? Color(props['borderColor'] as int)
              : null,
      backgroundColor:
          props['backgroundColor'] != null
              ? Color(props['backgroundColor'] as int)
              : null,
      textColor:
          props['textColor'] != null ? Color(props['textColor'] as int) : null,
      showActionButtons: props['showActionButtons'] as bool? ?? true,
      size: size,
      showGroup: props['showGroup'] as bool? ?? false,
      useGridLayout: props['useGridLayout'] as bool? ?? false,
    );
  }

  @override
  State<TimerCardWidget> createState() => _TimerCardWidgetState();
}

class _TimerCardWidgetState extends State<TimerCardWidget> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 每秒刷新一次UI，以更新计时器显示
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isRunning = task.isRunning;

    // 使用自定义颜色或默认值
    final effectiveBackgroundColor =
        widget.backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white);
    final effectiveBorderColor = widget.borderColor ?? task.color;
    final effectiveTextColor =
        widget.textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.grey.shade900);

    return Container(
      constraints: widget.size.getHeightConstraints(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // 默认阴影
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          // 激活状态的发光效果
          if (isRunning)
            BoxShadow(
              color: task.color.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
        color: effectiveBackgroundColor,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: effectiveBorderColor.withValues(
              alpha: isRunning ? 0.8 : 0.5,
            ),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (widget.onTap != null) {
              widget.onTap!(task);
            } else {
              await NavigationHelper.push(
                context,
                TimerTaskDetailsPage(taskId: task.id),
              );
              setState(() {});
            }
          },
          onLongPress: () => _showContextMenu(context, task),
          child: Padding(
            padding: widget.size.getPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 任务图标和名称
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(widget.size.getIconSize() * 0.3),
                      decoration: BoxDecoration(
                        color: task.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        task.icon,
                        color: Colors.white,
                        size: widget.size.getIconSize(),
                      ),
                    ),
                    SizedBox(width: widget.size.getSmallSpacing()),
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: widget.size.getTitleFontSize(),
                          fontWeight: FontWeight.bold,
                          color: effectiveTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.size.getSmallSpacing()),

                // 分组名称
                if (widget.showGroup)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.task.group,
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize() * 0.8,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),

                // 重复次数显示
                if (widget.task.repeatCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: widget.size.getSubtitleFontSize(),
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '重复 ${widget.task.remainingRepeatCount}/${widget.task.repeatCount} 次',
                          style: TextStyle(
                            fontSize: widget.size.getSubtitleFontSize(),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 计时器类型标签和状态 - 支持网格布局
                widget.useGridLayout
                    ? _buildGridLayout()
                    : Wrap(
                      spacing: widget.size.getSmallSpacing(),
                      runSpacing: widget.size.getSmallSpacing(),
                      children:
                          widget.task.timerItems.map((timer) {
                            if (timer.isRunning) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTimerTypeChip(timer),
                                  const SizedBox(height: 2),
                                  // 使用背景颜色显示进度
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          timer.completedDuration.inSeconds /
                                          timer.duration.inSeconds,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          color: task.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return _buildTimerTypeChip(timer);
                            }
                          }).toList(),
                    ),
                SizedBox(height: widget.size.getSmallSpacing()),
                // 控制按钮
                if (widget.showActionButtons)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _buildControlButton(task),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerTypeChip(TimerItem timer) {
    IconData icon;
    Color color;

    switch (timer.type) {
      case TimerType.countUp:
        icon = Icons.timer;
        color = Colors.blue;
        break;
      case TimerType.countDown:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case TimerType.pomodoro:
        icon = Icons.local_cafe;
        color = Colors.red;
        break;
    }

    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(
        icon,
        size: widget.size.getSubtitleFontSize() * 0.8,
        color: Colors.white,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            timer.name,
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize() * 0.8,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 4),
          if (timer.repeatCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '×${timer.getCurrentRepeatCount()}',
                style: TextStyle(
                  fontSize: widget.size.getSubtitleFontSize() * 0.6,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Text(
              _formatTimerDisplay(timer),
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize() * 0.8,
                color: Colors.white,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildControlButton(TimerTask task) {
    final iconSize = widget.size.getIconSize() * 0.8;

    if (task.isRunning) {
      return IconButton(
        icon: Icon(Icons.pause, color: Colors.red, size: iconSize),
        onPressed: () {
          task.pause();
          setState(() {});
          if (widget.onReset != null) {
            widget.onReset!(task);
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else if (task.isCompleted) {
      return IconButton(
        icon: Icon(Icons.replay, color: Colors.green, size: iconSize),
        onPressed: () {
          task.reset();
          setState(() {});
          if (widget.onReset != null) {
            widget.onReset!(task);
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.play_arrow, color: Colors.green, size: iconSize),
        onPressed: () {
          task.start();
          setState(() {});
          if (widget.onEdit != null) {
            widget.onEdit!(task);
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
  }

  void _showContextMenu(BuildContext context, TimerTask task) {
    if (!widget.showActionButtons) return;

    SmoothBottomSheet.show(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('app_edit'.tr),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) {
                  widget.onEdit!(task);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text('timer_reset'.tr),
              onTap: () {
                Navigator.pop(context);
                if (widget.onReset != null) {
                  widget.onReset!(task);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text('app_delete'.tr),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null) {
                  widget.onDelete!(task);
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatTimerDisplay(TimerItem timer) {
    if (timer.type == TimerType.countDown) {
      return _formatDuration(timer.remainingDuration);
    } else if (timer.isRunning) {
      return '${_formatDuration(timer.completedDuration)}/${_formatDuration(timer.duration)}';
    } else {
      return _formatDuration(timer.duration);
    }
  }

  /// 构建网格布局视图
  Widget _buildGridLayout() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: widget.size.getSmallSpacing(),
      mainAxisSpacing: widget.size.getSmallSpacing(),
      childAspectRatio: 1.0,
      children:
          widget.task.timerItems.map((item) => _buildGridItem(item)).toList(),
    );
  }

  /// 构建网格项
  Widget _buildGridItem(TimerItem item) {
    final progress =
        item.duration.inSeconds > 0
            ? item.completedDuration.inSeconds / item.duration.inSeconds
            : 0.0;

    // 根据类型确定颜色
    Color itemColor;
    switch (item.type) {
      case TimerType.pomodoro:
        itemColor = Colors.red;
        break;
      case TimerType.countUp:
        itemColor = Colors.blue;
        break;
      case TimerType.countDown:
        itemColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景圆环
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    strokeWidth: 6,
                  ),
                ),
                // 进度圆环
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : 0.001,
                    color: itemColor,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // 中间文字
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: widget.size.getSubtitleFontSize() * 0.8,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.type == TimerType.pomodoro)
                      Text(
                        '${item.currentCycle}/${item.cycles}',
                        style: TextStyle(
                          fontSize: widget.size.getSubtitleFontSize() * 0.6,
                          color: itemColor.withValues(alpha: 0.7),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimerDisplay(item),
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize() * 0.7,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 底部标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.type == TimerType.pomodoro
                  ? (item.isWorkPhase == true ? '工作' : '休息')
                  : (item.name.contains('Break') ? '休息' : '工作'),
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize() * 0.6,
                fontWeight: FontWeight.bold,
                color: itemColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
