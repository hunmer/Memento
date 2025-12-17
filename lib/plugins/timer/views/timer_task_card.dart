import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/timer/views/timer_task_details_page.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';

class TimerTaskCard extends StatefulWidget {
  final TimerTask task;
  final Function(TimerTask) onTap;
  final Function(TimerTask) onEdit;
  final Function(TimerTask) onReset;
  final Function(TimerTask) onDelete;

  const TimerTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
  });

  @override
  _TimerTaskCardState createState() => _TimerTaskCardState();
}

class _TimerTaskCardState extends State<TimerTaskCard> {
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // 默认阴影
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: task.color.withValues(alpha: isRunning ? 0.8 : 0.5),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () async {
            final returnedTask = await NavigationHelper.openContainer<TimerTask>(
              context,
              (context) => TimerTaskDetailsPage(
                task: task,
                onReset: () => widget.onReset(task),
                onResume: () {
                  task.start();
                  setState(() {});
                },
              ),
              transitionDuration: const Duration(milliseconds: 300),
            );
            if (returnedTask != null) {
              // 处理返回的任务
              setState(() {});
            }
          },
          onLongPress: () => _showContextMenu(context, task),
          child: Container(
            constraints: BoxConstraints(minHeight: 100), // 添加最小高度约束
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 确保Column只占用最小空间
                children: [
                  // 任务图标和名称
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: task.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(task.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 重复次数显示
                  if (widget.task.repeatCount > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.repeat,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '重复 ${widget.task.remainingRepeatCount}/${widget.task.repeatCount} 次',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // 计时器类型标签和状态
                  Wrap(
                    spacing: 4,
                    runSpacing: 8,
                    children:
                        task.timerItems.map((timer) {
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
                                    color: Colors.grey[300],
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        timer.completedDuration.inSeconds /
                                        timer.duration.inSeconds,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
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
                  const SizedBox(height: 12),
                  // 控制按钮
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _buildControlButton(task),
                  ),
                ],
              ),
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
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            timer.name,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(width: 4),
          if (timer.repeatCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '×${timer.getCurrentRepeatCount()}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Text(
              _formatTimerDisplay(timer),
              style: const TextStyle(fontSize: 12, color: Colors.white),
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
    if (task.isRunning) {
      return IconButton(
        icon: const Icon(Icons.pause, color: Colors.red),
        onPressed: () {
          task.pause();
          setState(() {});
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else if (task.isCompleted) {
      return IconButton(
        icon: const Icon(Icons.replay, color: Colors.green),
        onPressed: () {
          task.reset();
          setState(() {});
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.green),
        onPressed: () {
          task.start();
          setState(() {});
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
  }

  void _showContextMenu(BuildContext context, TimerTask task) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('app_edit'.tr),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text('timer_reset'.tr),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReset(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text('app_delete'.tr),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(task);
                },
              ),
            ],
          ),
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
}
