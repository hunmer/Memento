import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statistics_models.dart';

/// 通用日期范围选择器
class DateRangeSelector extends StatefulWidget {
  final DateRangeState state;
  final List<DateRangeOption> availableRanges;
  final Function(DateRangeOption) onRangeChanged;
  final Function(DateTime, DateTime)? onCustomRangeChanged;
  final Function()? onRefresh;
  final bool showRefreshButton;
  final Widget? loadingWidget;

  const DateRangeSelector({
    super.key,
    required this.state,
    required this.availableRanges,
    required this.onRangeChanged,
    this.onCustomRangeChanged,
    this.onRefresh,
    this.showRefreshButton = false,
    this.loadingWidget,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final initialStart = widget.state.startDate ?? now;
    final initialEnd = widget.state.endDate ?? now;
    final validEnd = initialEnd.isAfter(lastDate) ? lastDate : initialEnd;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: initialStart, end: validEnd),
    );

    if (picked != null && widget.onCustomRangeChanged != null) {
      widget.onCustomRangeChanged!(
        picked.start,
        DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      );
    }
  }

  String _getRangeText(DateRangeOption range) {
    switch (range) {
      case DateRangeOption.today:
        return 'Today';
      case DateRangeOption.thisWeek:
        return 'This Week';
      case DateRangeOption.thisMonth:
        return 'This Month';
      case DateRangeOption.thisYear:
        return 'This Year';
      case DateRangeOption.custom:
        return 'Custom Range';
    }
  }

  DateTime _getStartDate(DateTime now, DateTime todayEnd, DateRangeOption range) {
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case DateRangeOption.today:
        return today;
      case DateRangeOption.thisWeek:
        return today.subtract(Duration(days: now.weekday - 1));
      case DateRangeOption.thisMonth:
        return DateTime(now.year, now.month, 1);
      case DateRangeOption.thisYear:
        return DateTime(now.year, 1, 1);
      case DateRangeOption.custom:
        return widget.state.startDate ?? today;
    }
  }

  DateTime _getEndDate(DateTime now, DateTime todayEnd, DateRangeOption range) {
    switch (range) {
      case DateRangeOption.today:
      case DateRangeOption.thisWeek:
      case DateRangeOption.thisMonth:
      case DateRangeOption.thisYear:
        return todayEnd;
      case DateRangeOption.custom:
        return widget.state.endDate ?? now;
    }
  }

  void _handleRangeChanged(DateRangeOption range) {
    if (range == DateRangeOption.custom) {
      _showDateRangePicker();
    } else {
      widget.onRangeChanged(range);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.availableRanges.map((range) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getRangeText(range)),
                      selected: widget.state.selectedRange == range,
                      onSelected: (selected) {
                        if (selected) {
                          _handleRangeChanged(range);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (widget.showRefreshButton && widget.onRefresh != null)
            IconButton(
              icon: widget.state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: widget.state.isLoading ? null : widget.onRefresh,
            ),
        ],
      ),
    );
  }
}

/// 日期范围显示组件
class DateRangeDisplay extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customLabel;
  final TextStyle? style;

  const DateRangeDisplay({
    super.key,
    this.startDate,
    this.endDate,
    this.customLabel,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (customLabel != null) {
      return Text(
        customLabel!,
        style: style ??
            TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
      );
    }

    if (startDate == null || endDate == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}',
      style: style ??
          TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
    );
  }
}
