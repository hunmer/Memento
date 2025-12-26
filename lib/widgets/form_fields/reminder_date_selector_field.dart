import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

/// 提醒日期选择器类型
enum ReminderDateType {
  none, // 无
  daily, // 每天
  weekly, // 每周
  monthly, // 每月
}

/// 提醒日期选择数据模型
class ReminderDateData {
  final ReminderDateType type;
  final List<int> selectedDays; // 1-7(周) 或 1-31(月)
  final TimeOfDay? time;

  const ReminderDateData({
    required this.type,
    this.selectedDays = const [],
    this.time,
  });

  // 用于表单序列化的 Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'selectedDays': selectedDays,
      'time': time != null ? _timeOfDayToString(time!) : null,
    };
  }

  // 从 Map 解析
  static ReminderDateData fromMap(Map<String, dynamic> map) {
    return ReminderDateData(
      type: ReminderDateType.values[map['type'] as int? ?? 0],
      selectedDays: (map['selectedDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      time: map['time'] != null
          ? TimeOfDay.fromDateTime(
              DateTime.parse('1970-01-01 ${map['time']}'),
            )
          : null,
    );
  }

  // 检查是否为空/未设置
  bool get isEmpty => time == null || selectedDays.isEmpty;

  // 获取显示文本
  String getDisplayText(TimeOfDay time) {
    final timeStr = _timeOfDayToString(time);
    switch (type) {
      case ReminderDateType.none:
        return '无';
      case ReminderDateType.daily:
        return '每天 $timeStr';
      case ReminderDateType.weekly:
        if (selectedDays.length == 7) {
          return '每天 $timeStr';
        }
        final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
        final days = selectedDays.map((d) => weekDays[d - 1]).join('、');
        return '周$days $timeStr';
      case ReminderDateType.monthly:
        if (selectedDays.length == 31) {
          return '每天 $timeStr';
        }
        final days = selectedDays.map((d) => '$d').join('、');
        return '每月$days日 $timeStr';
    }
  }

  // 复制并修改类型
  ReminderDateData copyWithType(ReminderDateType newType) {
    return ReminderDateData(
      type: newType,
      selectedDays: newType == ReminderDateType.daily || newType == ReminderDateType.none ? [] : _getDefaultDays(newType),
      time: newType == ReminderDateType.none ? null : time,
    );
  }

  // 复制并修改选中天
  ReminderDateData copyWithSelectedDays(List<int> newDays) {
    return ReminderDateData(
      type: type,
      selectedDays: newDays,
      time: time,
    );
  }

  // 复制并修改时间
  ReminderDateData copyWithTime(TimeOfDay? newTime) {
    return ReminderDateData(
      type: type,
      selectedDays: selectedDays,
      time: newTime,
    );
  }

  static List<int> _getDefaultDays(ReminderDateType type) {
    switch (type) {
      case ReminderDateType.none:
      case ReminderDateType.daily:
        return [];
      case ReminderDateType.weekly:
        return [1, 2, 3, 4, 5, 6, 7];
      case ReminderDateType.monthly:
        return List.generate(31, (i) => i + 1);
    }
  }
}

// 辅助函数：将 TimeOfDay 转换为字符串
String _timeOfDayToString(TimeOfDay time) {
  final now = DateTime.now();
  final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// 提醒日期选择器字段
///
/// 支持每天/每周/每月三种模式：
/// - 每天：仅时间选择
/// - 每周：展示7天，可切换选择，默认全选
/// - 每月：展示31天，可切换选择，默认全选
class ReminderDateSelectorField extends StatelessWidget {
  final String name;
  final ReminderDateData? initialValue;
  final ValueChanged<ReminderDateData>? onChanged;
  final bool required;
  final String? validationMessage;

  const ReminderDateSelectorField({
    super.key,
    required this.name,
    this.initialValue,
    this.onChanged,
    this.required = false,
    this.validationMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 周名称
    final List<String> weekDays = ['一', '二', '三', '四', '五', '六', '日'];

    return WrappedFormField(
      name: name,
      initialValue: initialValue ?? const ReminderDateData(
        type: ReminderDateType.daily,
        selectedDays: [1, 2, 3, 4, 5, 6, 7],
      ),
      onChanged: (value) {
        onChanged?.call(value as ReminderDateData);
      },
      builder: (context, value, setValue) {
        final currentValue = value as ReminderDateData;

        // 切换类型
        void changeType(ReminderDateType newType) {
          setValue(currentValue.copyWithType(newType));
        }

        // 切换日期选中状态
        void toggleDay(int day) {
          final isSelected = currentValue.selectedDays.contains(day);
          final newDays = isSelected
              ? currentValue.selectedDays.where((d) => d != day).toList()
              : [...currentValue.selectedDays, day]..sort();
          setValue(currentValue.copyWithSelectedDays(newDays));
        }

        // 切换全选/全不选
        void toggleAll() {
          final defaultDays = ReminderDateData._getDefaultDays(currentValue.type);
          if (currentValue.selectedDays.length == defaultDays.length) {
            setValue(currentValue.copyWithSelectedDays([]));
          } else {
            setValue(currentValue.copyWithSelectedDays(defaultDays));
          }
        }

        // 选择时间
        Future<void> selectTime() async {
          final time = await showTimePicker(
            context: context,
            initialTime: currentValue.time ?? TimeOfDay.now(),
          );
          if (time != null) {
            setValue(currentValue.copyWithTime(time));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型选择器
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<ReminderDateType>(
                    segments: const [
                      ButtonSegment(
                        value: ReminderDateType.none,
                        label: Text('无'),
                      ),
                      ButtonSegment(
                        value: ReminderDateType.daily,
                        label: Text('每天'),
                      ),
                      ButtonSegment(
                        value: ReminderDateType.weekly,
                        label: Text('每周'),
                      ),
                      ButtonSegment(
                        value: ReminderDateType.monthly,
                        label: Text('每月'),
                      ),
                    ],
                    selected: {currentValue.type},
                    onSelectionChanged: (Set<ReminderDateType> newSelection) {
                      changeType(newSelection.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 日期选择区域（非 daily 且 非 none 时显示）
            if (currentValue.type != ReminderDateType.daily && currentValue.type != ReminderDateType.none) ...[
              // 星期/日期选择 + 全选按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentValue.type == ReminderDateType.weekly ? '选择星期' : '选择日期',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: toggleAll,
                    child: Text(
                      currentValue.selectedDays.length == ReminderDateData._getDefaultDays(currentValue.type).length
                          ? '全不选'
                          : '全选',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 每周模式：单行滚动；每月模式：多行网格
              if (currentValue.type == ReminderDateType.weekly)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = currentValue.selectedDays.contains(day);
                      return FilterChip(
                        label: Text(weekDays[index]),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        onSelected: (_) => toggleDay(day),
                      );
                    },
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(31, (index) {
                    final day = index + 1;
                    final isSelected = currentValue.selectedDays.contains(day);
                    return FilterChip(
                      label: Text('$day'),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      onSelected: (_) => toggleDay(day),
                    );
                  }),
                ),
              const SizedBox(height: 12),
            ],

            // 时间选择（非 none 时显示）
            if (currentValue.type != ReminderDateType.none)
              Row(
                children: [
                  Text(
                    '提醒时间',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      currentValue.time != null
                          ? _timeOfDayToString(currentValue.time!)
                          : '选择时间',
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
