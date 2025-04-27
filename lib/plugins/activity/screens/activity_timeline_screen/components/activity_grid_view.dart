import 'package:flutter/material.dart';
import '../../../models/activity_record.dart';

class ActivityGridView extends StatefulWidget {
  final List<ActivityRecord> activities;
  final Function(ActivityRecord) onActivityTap;
  final Function(DateTime, DateTime) onUnrecordedTimeTap;
  final Function(DateTime?, DateTime?)? onSelectionChanged;
  final DateTime selectedDate;

  const ActivityGridView({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onUnrecordedTimeTap,
    this.onSelectionChanged,
    required this.selectedDate,
  });

  @override
  State<ActivityGridView> createState() => _ActivityGridViewState();
}

class _ActivityGridViewState extends State<ActivityGridView> {
  DateTime? _selectionStart;
  DateTime? _selectionEnd;
  bool _isDragging = false;
  bool _isMouseDown = false;

  // 跟踪鼠标位置
  Offset? _lastMousePosition;
  final GlobalKey _gridKey = GlobalKey();

  // 计算网格索引对应的时间
  DateTime _getTimeFromIndex(int hourIndex, int minuteIndex) {
    return DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      hourIndex,
      minuteIndex * 5,
    );
  }

  // 从标签生成颜色
  Color _getColorFromTags(List<String> tags) {
    if (tags.isEmpty) {
      return Colors.blue;
    }

    // 根据第一个标签生成颜色
    final tag = tags.first;
    // 使用标签的哈希值来生成一个稳定的颜色
    final hue = (tag.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  // 获取该时间点对应的活动
  ActivityRecord? _getActivityAtTime(DateTime time) {
    for (final activity in widget.activities) {
      if ((time.isAfter(activity.startTime) &&
              time.isBefore(activity.endTime)) ||
          time.isAtSameMomentAs(activity.startTime) ||
          time.isAtSameMomentAs(activity.endTime)) {
        return activity;
      }
    }
    return null;
  }

  // 获取时间对应的网格颜色
  Color _getGridColor(DateTime time) {
    // 检查是否超过当前时间
    if (time.isAfter(DateTime.now())) {
      return Colors.grey.withOpacity(0.3); // 增加灰色不透明度，使禁用状态更明显
    }

    // 检查是否在选择范围内
    if (_isDragging && _selectionStart != null) {
      final selectionEnd = _selectionEnd ?? time;
      if ((time.isAfter(_selectionStart!) && time.isBefore(selectionEnd)) ||
          (time.isAfter(selectionEnd) && time.isBefore(_selectionStart!)) ||
          time.isAtSameMomentAs(_selectionStart!) ||
          time.isAtSameMomentAs(selectionEnd)) {
        return Colors.lightBlue.withOpacity(0.3);
      }
    }

    // 检查是否有活动在这个时间点
    final activity = _getActivityAtTime(time);
    if (activity != null) {
      // 优先使用活动的颜色，如果没有则根据标签生成颜色
      return activity.color ?? _getColorFromTags(activity.tags);
    }

    return Colors.grey.withOpacity(0.1);
  }

  void _onGridTapDown(DateTime time) {
    // 如果点击的时间超过当前时间，不允许选择
    if (time.isAfter(DateTime.now())) {
      return;
    }

    // 检查是否点击了已有活动
    final activity = _getActivityAtTime(time);
    if (activity != null) {
      // 如果点击的是已有活动，触发编辑回调
      widget.onActivityTap(activity);
      return;
    }

    // 如果点击的是空白区域，开始新的选择
    setState(() {
      _selectionStart = time;
      _selectionEnd = time;
      _isDragging = true;
    });

    // 通知选择范围变化
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectionStart, _selectionEnd);
    }
  }

  void _onGridDragUpdate(DateTime time) {
    if (_isDragging || _isMouseDown) {
      // 如果拖动到超过当前时间的位置，使用当前时间作为结束时间
      final now = DateTime.now();
      final endTime = time.isAfter(now) ? now : time;
      setState(() {
        _selectionEnd = endTime;
      });

      // 通知选择范围变化
      if (widget.onSelectionChanged != null && _selectionStart != null) {
        widget.onSelectionChanged!(_selectionStart, _selectionEnd);
      }
    }
  }

  void _onGridDragEnd() {
    if (_isDragging && _selectionStart != null && _selectionEnd != null) {
      final start =
          _selectionStart!.isBefore(_selectionEnd!)
              ? _selectionStart!
              : _selectionEnd!;
      final end =
          _selectionStart!.isBefore(_selectionEnd!)
              ? _selectionEnd!
              : _selectionStart!;
      widget.onUnrecordedTimeTap(start, end);
    }
    setState(() {
      _isDragging = false;
      _selectionStart = null;
      _selectionEnd = null;
    });

    // 通知选择范围清空
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(null, null);
    }
  }

  // 根据鼠标位置找到对应的时间
  DateTime? _getTimeFromOffset(Offset localPosition) {
    if (_gridKey.currentContext == null) return null;

    final RenderBox box =
        _gridKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = box.size;

    // 计算鼠标位置对应的行和列
    final double cellWidth = (size.width - 30) / 12; // 减去小时标签宽度，除以12个5分钟格子
    final double cellHeight = 33; // 每个格子高度

    // 计算小时和分钟
    final int hourIndex = (localPosition.dy / cellHeight).floor();
    if (hourIndex < 0 || hourIndex >= 24) return null;

    // 减去小时标签宽度
    final double adjustedX = localPosition.dx - 30;
    if (adjustedX < 0) return null;

    final int minuteIndex = (adjustedX / cellWidth).floor();
    if (minuteIndex < 0 || minuteIndex >= 12) return null;

    return _getTimeFromIndex(hourIndex, minuteIndex);
  }

  // 处理鼠标移动事件
  void _handleMouseMove(PointerMoveEvent event) {
    if (!_isMouseDown) return;

    final RenderBox box =
        _gridKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(event.position);
    _lastMousePosition = localPosition;

    final DateTime? time = _getTimeFromOffset(localPosition);
    if (time != null) {
      _onGridDragUpdate(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        final RenderBox box =
            _gridKey.currentContext!.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(event.position);
        _lastMousePosition = localPosition;

        final DateTime? time = _getTimeFromOffset(localPosition);
        if (time != null) {
          setState(() {
            _isMouseDown = true;
          });
          _onGridTapDown(time);
        }
      },
      onPointerMove: _handleMouseMove,
      onPointerUp: (PointerUpEvent event) {
        if (_isMouseDown) {
          setState(() {
            _isMouseDown = false;
          });
          _onGridDragEnd();
        }
      },
      child: Column(
        key: _gridKey,
        children: [
          // 分钟标尺
          Row(
            children: [
              // 左侧空白，对齐小时标签
              const SizedBox(width: 30),
              // 分钟标签
              Expanded(
                child: Row(
                  children: List.generate(12, (index) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          '${index * 5}'.padLeft(2, '0'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          // 网格主体
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hourHeight =
                    (constraints.maxHeight - 30) / 24; // 减去分钟标尺的高度
                return Column(
                  children: List.generate(24, (hourIndex) {
                    return Row(
                      children: [
                        // 小时标签
                        SizedBox(
                          width: 30,
                          child: Center(
                            child: Text(
                              '$hourIndex',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        // 每小时的12个5分钟格子
                        Expanded(
                          child: Row(
                            children: List.generate(12, (minuteIndex) {
                              final time = _getTimeFromIndex(
                                hourIndex,
                                minuteIndex,
                              );
                              return Expanded(
                                child: MouseRegion(
                                  cursor:
                                      _isDragging
                                          ? SystemMouseCursors.grabbing
                                          : SystemMouseCursors.click,
                                  child: GestureDetector(
                                    // 移动端长按事件
                                    onLongPressStart: (_) {
                                      // 检查是否点击了已有活动
                                      final activity = _getActivityAtTime(time);
                                      if (activity == null) {
                                        _onGridTapDown(time);
                                      }
                                    },
                                    onLongPressMoveUpdate:
                                        (_) => _onGridDragUpdate(time),
                                    onLongPressEnd: (_) => _onGridDragEnd(),
                                    child: Container(
                                      height: hourHeight - 2, // 减去margin的高度
                                      margin: const EdgeInsets.all(
                                        1.0,
                                      ), // 保持网格间隙
                                      decoration: BoxDecoration(
                                        color: _getGridColor(time),
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ), // 添加圆角
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
