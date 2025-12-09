import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_definition.dart';

/// 日历选择视图
///
/// 用于在选择器中展示日历形式的选项（如日记条目）
class CalendarSelectionView extends StatefulWidget {
  /// 可选项列表（需要在 metadata 中包含 'date' 字段）
  final List<SelectableItem> items;

  /// 项目选中回调
  final ValueChanged<SelectableItem> onItemSelected;

  /// 选择模式
  final SelectionMode selectionMode;

  /// 已选中的项目 ID 集合（多选模式用）
  final Set<String>? selectedIds;

  /// 主题颜色
  final Color? themeColor;

  /// 空状态组件
  final Widget? emptyWidget;

  /// 空状态文本
  final String? emptyText;

  /// 日历格式
  final CalendarFormat initialFormat;

  /// 初始聚焦日期
  final DateTime? focusedDay;

  const CalendarSelectionView({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.selectionMode = SelectionMode.single,
    this.selectedIds,
    this.themeColor,
    this.emptyWidget,
    this.emptyText,
    this.initialFormat = CalendarFormat.month,
    this.focusedDay,
  });

  @override
  State<CalendarSelectionView> createState() => _CalendarSelectionViewState();
}

class _CalendarSelectionViewState extends State<CalendarSelectionView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late CalendarFormat _calendarFormat;

  // 日期 -> 项目列表 映射
  late Map<DateTime, List<SelectableItem>> _dateItemsMap;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay ?? DateTime.now();
    _calendarFormat = widget.initialFormat;
    _buildDateItemsMap();
  }

  @override
  void didUpdateWidget(CalendarSelectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _buildDateItemsMap();
    }
  }

  void _buildDateItemsMap() {
    _dateItemsMap = {};
    for (final item in widget.items) {
      final date = _extractDate(item);
      if (date != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        _dateItemsMap.putIfAbsent(normalizedDate, () => []).add(item);
      }
    }
  }

  DateTime? _extractDate(SelectableItem item) {
    // 尝试从 metadata 中获取日期
    if (item.metadata != null && item.metadata!['date'] != null) {
      final dateValue = item.metadata!['date'];
      if (dateValue is DateTime) {
        return dateValue;
      }
      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
    }
    // 尝试从 rawData 中获取
    if (item.rawData != null) {
      try {
        final dynamic rawData = item.rawData;
        if (rawData is Map && rawData['date'] != null) {
          final dateValue = rawData['date'];
          if (dateValue is DateTime) return dateValue;
          if (dateValue is String) return DateTime.tryParse(dateValue);
        }
      } catch (_) {}
    }
    return null;
  }

  List<SelectableItem> _getItemsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dateItemsMap[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.themeColor ?? theme.colorScheme.primary;

    return Column(
      children: [
        // 日历组件
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return _selectedDay != null && isSameDay(_selectedDay, day);
          },
          eventLoader: _getItemsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 6,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: effectiveColor),
              borderRadius: BorderRadius.circular(16),
            ),
            formatButtonTextStyle: TextStyle(color: effectiveColor),
          ),
        ),

        const Divider(height: 1),

        // 选中日期的项目列表
        Expanded(
          child: _selectedDay != null
              ? _buildDayItemsList(theme, effectiveColor)
              : _buildHintWidget(theme),
        ),
      ],
    );
  }

  Widget _buildDayItemsList(ThemeData theme, Color effectiveColor) {
    final dayItems = _getItemsForDay(_selectedDay!);

    if (dayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '该日期暂无数据',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: dayItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final item = dayItems[index];
        final isSelected = widget.selectedIds?.contains(item.id) ?? false;

        return ListTile(
          leading: _buildItemLeading(item, effectiveColor),
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: widget.selectionMode == SelectionMode.multiple
              ? Checkbox(
                  value: isSelected,
                  onChanged: item.selectable
                      ? (_) => widget.onItemSelected(item)
                      : null,
                  activeColor: effectiveColor,
                )
              : const Icon(Icons.chevron_right),
          selected: isSelected,
          selectedTileColor: effectiveColor.withOpacity(0.08),
          enabled: item.selectable,
          onTap: item.selectable ? () => widget.onItemSelected(item) : null,
        );
      },
    );
  }

  Widget _buildHintWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '请选择日期查看内容',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLeading(SelectableItem item, Color effectiveColor) {
    if (item.icon != null) {
      return CircleAvatar(
        backgroundColor: (item.color ?? effectiveColor).withOpacity(0.15),
        child: Icon(
          item.icon,
          color: item.color ?? effectiveColor,
          size: 20,
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: effectiveColor.withOpacity(0.15),
      child: Text(
        item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
