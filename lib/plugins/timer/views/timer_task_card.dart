import 'dart:async';
import 'package:flutter/material.dart';
import '../models/timer_task.dart';
import '../models/timer_item.dart';

class TimerTaskCard extends StatefulWidget {
  final TimerTask task;
  final Function(TimerTask) onTap;
  final Function(TimerTask) onEdit;
  final Function(TimerTask) onReset;
  final Function(TimerTask) onDelete;

  const TimerTaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
  }) : super(key: key);

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
    final activeTimer = task.activeTimer;
    final isRunning = task.isRunning;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: task.color.withOpacity(0.5), width: 2),
      ),
      child: InkWell(
        onTap: () => widget.onTap(task),
        onLongPress: () => _showContextMenu(context, task),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 计时器类型标签
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    task.timerItems.map((timer) {
                      return _buildTimerTypeChip(timer);
                    }).toList(),
              ),

              const Spacer(),

              // 进度条
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(task.color),
              ),
              const SizedBox(height: 8),

              // 时间显示
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 显示当前活动的计时器或总进度
                  Text(
                    activeTimer != null
                        ? '${activeTimer.name}: ${activeTimer.formattedRemainingTime}'
                        : _formatDuration(task.completedDuration),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  // 控制按钮
                  _buildControlButton(task),
                ],
              ),
            ],
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
      label: Text(
        timer.name,
        style: const TextStyle(fontSize: 12, color: Colors.white),
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
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 100,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              widget.onEdit(task);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('重置'),
            onTap: () {
              Navigator.pop(context);
              widget.onReset(task);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('删除'),
            onTap: () {
              Navigator.pop(context);
              widget.onDelete(task);
            },
          ),
        ),
      ],
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
}
