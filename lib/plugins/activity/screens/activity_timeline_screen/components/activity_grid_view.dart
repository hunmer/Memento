import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  DateTime? _lastEnteredTime;  // 添加变量跟踪最后一次进入的时间块
  bool _isDragging = false;
  bool _isMouseDown = false;

  // 存储已使用的颜色，用于确保颜色有明显区别
  final Map<String, Color> _tagColorCache = {};

  // 检查时间是否与现有活动重叠
  bool _isTimeOverlapping(DateTime time) {
    return widget.activities.any((activity) {
      return time.isAfter(activity.startTime) && 
             time.isBefore(activity.endTime) ||
             time.isAtSameMomentAs(activity.startTime) ||
             time.isAtSameMomentAs(activity.endTime);
    });
  }

  // 检查时间范围是否与现有活动重叠
  bool _isRangeOverlapping(DateTime start, DateTime end) {
    return widget.activities.any((activity) {
      return (start.isBefore(activity.endTime) && end.isAfter(activity.startTime)) ||
             start.isAtSameMomentAs(activity.startTime) ||
             end.isAtSameMomentAs(activity.endTime);
    });
  }
  
  final GlobalKey _gridKey = GlobalKey();

  // 计算网格索引对应的时间
  // 注意：网格显示的时间从每小时的05分钟开始（如0:05, 1:05...），而不是从00分钟开始
  // 这是为了让用户更容易看到时间段的开始，但在实际创建活动时，我们需要将开始时间向前调整5分钟
  DateTime _getTimeFromIndex(int hourIndex, int minuteIndex) {
    return DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      hourIndex,
      minuteIndex * 5 + 5,  // 实际时间从05开始，每格5分钟
    );
  }

  // 从标签生成颜色，确保与之前的颜色有明显区别
  Color _getColorFromTags(List<String> tags) {
    if (tags.isEmpty) {
      return Colors.blue;
    }

    // 根据第一个标签生成颜色
    final tag = tags.first;
    
    // 检查是否已经为这个标签缓存了颜色
    if (_tagColorCache.containsKey(tag)) {
      return _tagColorCache[tag]!;
    }
    
    // 生成新颜色
    Color newColor = _generateDistinctColor(tag);
    
    // 缓存这个颜色
    _tagColorCache[tag] = newColor;
    
    return newColor;
  }
  
  // 生成与现有颜色有明显区别的新颜色
  Color _generateDistinctColor(String tag) {
    // 使用标签的哈希值作为基础
    double baseHue = (tag.hashCode % 360).abs().toDouble();
    double saturation = 0.6;
    double lightness = 0.5;
    
    // 如果没有缓存的颜色，直接返回基础颜色
    if (_tagColorCache.isEmpty) {
      return HSLColor.fromAHSL(1.0, baseHue, saturation, lightness).toColor();
    }
    
    // 尝试找到一个与现有颜色有足够差异的颜色
    const int maxAttempts = 10;
    const double minHueDifference = 40.0; // 色相差异至少40度
    
    Color bestColor = HSLColor.fromAHSL(1.0, baseHue, saturation, lightness).toColor();
    double bestDifference = 0;
    
    for (int i = 0; i < maxAttempts; i++) {
      // 在基础色相上增加一个偏移
      double hueOffset = (360 / maxAttempts) * i;
      double newHue = (baseHue + hueOffset) % 360;
      
      // 创建候选颜色
      Color candidateColor = HSLColor.fromAHSL(1.0, newHue, saturation, lightness).toColor();
      
      // 计算与现有颜色的最小差异
      double minDifference = _calculateMinColorDifference(candidateColor);
      
      // 如果找到更好的颜色，更新最佳颜色
      if (minDifference > bestDifference) {
        bestDifference = minDifference;
        bestColor = candidateColor;
        
        // 如果差异已经足够大，可以提前返回
        if (bestDifference >= minHueDifference) {
          break;
        }
      }
    }
    
    return bestColor;
  }
  
  // 计算一个颜色与所有缓存颜色的最小差异
  double _calculateMinColorDifference(Color newColor) {
    if (_tagColorCache.isEmpty) return 360.0;
    
    double minDifference = 360.0;
    HSLColor newHSL = HSLColor.fromColor(newColor);
    
    for (Color existingColor in _tagColorCache.values) {
      HSLColor existingHSL = HSLColor.fromColor(existingColor);
      
      // 计算色相差异（考虑环形色相空间）
      double hueDiff = (newHSL.hue - existingHSL.hue).abs();
      if (hueDiff > 180) hueDiff = 360 - hueDiff;
      
      // 也考虑饱和度和亮度的差异
      double satDiff = (newHSL.saturation - existingHSL.saturation).abs();
      double lightDiff = (newHSL.lightness - existingHSL.lightness).abs();
      
      // 综合差异，主要权重给色相
      double totalDiff = hueDiff * 0.8 + satDiff * 0.1 + lightDiff * 0.1;
      
      if (totalDiff < minDifference) {
        minDifference = totalDiff;
      }
    }
    
    return minDifference;
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
      return Colors.grey.withValues(alpha: 0.3); // 增加灰色不透明度，使禁用状态更明显
    }

    // 检查是否在选择范围内
    if (_isDragging && _selectionStart != null && _lastEnteredTime != null) {
      final start = _selectionStart!;
      final end = _lastEnteredTime!;
      if ((time.isAfter(start) && time.isBefore(end)) ||
          (time.isAfter(end) && time.isBefore(start)) ||
          time.isAtSameMomentAs(start) ||
          time.isAtSameMomentAs(end)) {
        return Colors.lightBlue.withValues(alpha: 0.3);
      }
    }

    // 检查是否有活动在这个时间点
    final activity = _getActivityAtTime(time);
    if (activity != null) {
      // 优先使用活动的颜色，如果没有则根据标签生成颜色
      return activity.color ?? _getColorFromTags(activity.tags);
    }

    return Colors.grey.withValues(alpha: 0.1);
  }

  void _onGridDragEnd() {
    if (_isDragging && _selectionStart != null && _lastEnteredTime != null) {
      // 确定实际的开始和结束时间
      final rawStart = _selectionStart!.isBefore(_lastEnteredTime!)
          ? _selectionStart!
          : _lastEnteredTime!;
      final rawEnd =
          _selectionStart!.isBefore(_lastEnteredTime!)
          ? _lastEnteredTime!
          : _selectionStart!;

      // 由于网格时间从每小时的05分钟开始，我们需要将开始时间向前调整5分钟
      // 同时也要将结束时间向前调整5分钟，保持时间段的完整性
      // 例如：如果选择了8:05-10:05，实际应该是8:00-10:00
      final start = rawStart.subtract(const Duration(minutes: 5));
      final end = rawEnd.subtract(const Duration(minutes: 5));

      // 调用回调函数，传入调整后的开始时间和结束时间
      widget.onUnrecordedTimeTap(start, end);
    }
    setState(() {
      _isDragging = false;
      _isMouseDown = false; // 确保鼠标/触摸状态也被重置
      _selectionStart = null;
      _selectionEnd = null;
      _lastEnteredTime = null; // 重置最后进入的时间
    });

    // 通知选择范围清空
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(null, null);
    }
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(null, null);
    }
  }

  // 不再需要根据鼠标位置计算时间，直接使用网格的时间
  
  // 处理网格的鼠标悬停或触摸移动事件
  void _handleGridHover(DateTime time) {
    // 如果是鼠标事件，需要检查鼠标是否按下
    // 如果是触摸事件（通过onPanUpdate或onLongPressMoveUpdate触发），则直接更新
    if (_isMouseDown || _isDragging) {
      // 检查时间点是否已经有活动
      if (_isTimeOverlapping(time)) {
        return; // 如果时间点已经有活动，不允许选择
      }
      
      if (!_isDragging) {
        // 第一次进入拖动状态，设置起始时间
        setState(() {
          _isDragging = true;
          _selectionStart = time;
          _lastEnteredTime = time;  // 初始化最后进入的时间
          _selectionEnd = time;
        });
      } else {
        // 已经在拖动状态，更新最后进入的时间块
        final now = DateTime.now();
        final currentTime = time.isAfter(now) ? now : time;
        
        // 检查当前选择范围是否与现有活动重叠
        if (_selectionStart != null) {
          DateTime start = _selectionStart!.isBefore(currentTime) ? _selectionStart! : currentTime;
          DateTime end = _selectionStart!.isBefore(currentTime) ? currentTime : _selectionStart!;
          
          // 如果选择范围与现有活动重叠，不更新选择范围
          if (_isRangeOverlapping(start, end)) {
            return;
          }
        }
        
        // 只有当进入新的时间块时才更新
        if (_lastEnteredTime != currentTime) {
          setState(() {
            _lastEnteredTime = currentTime;
            _selectionEnd = currentTime;
          });
          
          // 通知选择范围变化
          if (widget.onSelectionChanged != null) {
            widget.onSelectionChanged!(_selectionStart, _selectionEnd);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          _isMouseDown = true;
        });
      },
      onPointerMove: (PointerMoveEvent event) {
        if (!_isMouseDown) return;
        // 获取指针位置对应的网格
        final RenderBox? renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final result = BoxHitTestResult();
          // 将全局坐标转换为本地坐标
          final localPosition = renderBox.globalToLocal(event.position);
          // 执行命中测试
          if (renderBox.hitTest(result, position: localPosition)) {
            // 遍历所有命中的对象
            for (final hit in result.path) {
              // 检查是否找到了带有时间数据的Container
              if (hit.target is RenderMetaData) {
                final metadata = hit.target as RenderMetaData;
                if (metadata.metaData is DateTime) {
                  final time = metadata.metaData as DateTime;
                  // 使用获取到的时间更新选择范围
                  _handleGridHover(time);
                  break;
                }
              }
            }
          }
      }
      },
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
                          '${(index * 5 + 5) % 60}'.padLeft(2, '0'),  // 显示从05开始，但在创建活动时会向前调整5分钟
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
                                  child: GestureDetector(
                                    onTap: () {
                                      final activity = _getActivityAtTime(time);
                                      if (activity != null) {
                                        widget.onActivityTap(activity);
                                      }
                                    },
                                    child: MetaData(
                                      metaData: time,
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
                                            color: Colors.grey.withValues(
                                              alpha: 0.2,
                                            ),
                                          width: 0.5,
                                        ),
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
