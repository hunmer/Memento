import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';

/// 打卡项目卡片组件
///
/// 用于展示打卡项目的卡片，支持三种风格：weekly、small、calendar。
///
/// 使用示例：
/// ```dart
/// CheckinItemCardWidget(
///   item: CheckinItem(name: '早起', icon: Icons.wb_sunny),
///   index: 0,
///   itemIndex: 0,
///   onStateChanged: () {},
/// )
/// ```
class CheckinItemCardWidget extends StatefulWidget {
  /// 打卡项目数据
  final CheckinItem item;

  /// 索引
  final int index;

  /// 项目索引
  final int itemIndex;

  /// 状态变更回调（用于+1按钮）
  final VoidCallback onStateChanged;

  /// 点击回调（可选，用于卡片主体导航）
  final VoidCallback? onTap;

  /// 长按回调（可选）
  final VoidCallback? onLongPress;

  /// 日期选择回调（可选，用于点击周圈或日历日期）
  final Function(DateTime selectedDate)? onDateSelected;

  const CheckinItemCardWidget({
    super.key,
    required this.item,
    required this.index,
    required this.itemIndex,
    required this.onStateChanged,
    this.onTap,
    this.onLongPress,
    this.onDateSelected,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory CheckinItemCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemJson = props['item'] as Map<String, dynamic>?;
    return CheckinItemCardWidget(
      item: itemJson != null ? CheckinItem.fromJson(itemJson) : CheckinItem(
        name: props['name'] as String? ?? '',
        icon: props['icon'] != null
            ? IconData(props['icon'] as int, fontFamily: 'MaterialIcons')
            : Icons.check_circle,
      ),
      index: props['index'] as int? ?? 0,
      itemIndex: props['itemIndex'] as int? ?? 0,
      onStateChanged: props['onStateChanged'] as VoidCallback? ?? () {},
      onTap: props['onTap'] as VoidCallback?,
      onLongPress: props['onLongPress'] as VoidCallback?,
      onDateSelected: props['onDateSelected'] as Function(DateTime)?,
    );
  }

  @override
  State<CheckinItemCardWidget> createState() => _CheckinItemCardWidgetState();
}

class _CheckinItemCardWidgetState extends State<CheckinItemCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    switch (widget.item.cardStyle) {
      case CheckinCardStyle.small:
        content = _buildSmallStyle(context, theme);
        break;
      case CheckinCardStyle.calendar:
        content = _buildCalendarStyle(context, theme);
        break;
      case CheckinCardStyle.weekly:
        content = _buildWeeklyStyle(context, theme);
        break;
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16.0), child: content),
        ),
      ),
    );
  }

  // --- Weekly Style ---
  Widget _buildWeeklyStyle(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Name
            Expanded(
              child: Row(
                children: [
                  _buildIcon(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Stats (Frequency & Last Check-in)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getWeeklyProgressText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.item.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.item.lastCheckinDate != null)
                  Row(
                    children: [
                      Text(
                        _formatLastCheckinTime(),
                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.access_time, size: 12, color: theme.hintColor),
                    ],
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Body Row (Weekly Circles + Button)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildWeeklyCircles(),
            ),
            const SizedBox(width: 16),
            // +1 Button
            _buildPlusOneButton(context, size: 56),
          ],
        ),
      ],
    );
  }

  // --- Small Style ---
  Widget _buildSmallStyle(BuildContext context, ThemeData theme) {
    final stats = _calculateMonthlyStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.item.icon, color: widget.item.color, size: 20),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.item.lastCheckinDate != null)
              Row(
                children: [
                  Text(
                    _formatTimeOnly(widget.item.lastCheckinDate!),
                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                  ),
                  Icon(Icons.edit_note, size: 14, color: theme.hintColor),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Stats Box
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStatItem(
                context,
                Icons.checklist_rtl,
                stats['count']!.toString(),
                '本次次数',
                Colors.blue,
              ),
              _buildSmallStatItem(
                context,
                Icons.calendar_today,
                stats['days']!.toString(),
                '本次天数',
                Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Progress Button (Acting as +1)
        _buildProgressButton(context, stats),
      ],
    );
  }

  // --- Calendar Style ---
  Widget _buildCalendarStyle(BuildContext context, ThemeData theme) {
    final stats = _calculateMonthlyStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildIcon(theme),
                const SizedBox(width: 12),
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (widget.item.lastCheckinDate != null)
              Row(
                children: [
                  Text(
                    _formatLastCheckinTime(),
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_note, size: 16, color: theme.hintColor),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Body
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Calendar Grid
            Expanded(child: _buildMonthCalendar(context, theme)),
            const SizedBox(width: 16),

            // Right Side Stats & Button
            SizedBox(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildSmallStatItem(
                            context,
                            Icons.checklist_rtl,
                            stats['count']!.toString(),
                            '次数',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPlusOneButton(context, size: 60),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: widget.item.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.item.icon, color: widget.item.color, size: 24),
    );
  }

  Widget _buildPlusOneButton(BuildContext context, {required double size}) {
    return InkWell(
      onTap: widget.onStateChanged,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '+1',
            style: TextStyle(
              color: widget.item.color,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressButton(BuildContext context, Map<String, int> stats) {
    return InkWell(
      onTap: widget.onStateChanged,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: widget.item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Progress Bar
            FractionallySizedBox(
              widthFactor: (stats['count']! / 30).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.item.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Text
            Center(
              child: Text(
                '${stats['count']}/30',
                style: TextStyle(
                  color: widget.item.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildWeeklyCircles() {
    final now = DateTime.now();
    // 标准化为今天的 00:00:00
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final circles = <Widget>[];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      // 标准化日期，去除时间部分
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasCheckin = widget.item.checkInRecords.containsKey(dateStr) &&
          widget.item.checkInRecords[dateStr]!.isNotEmpty;
      final isToday = normalizedDate.isAtSameMomentAs(today);

      // 检查日期是否在未来（使用标准化日期比较）
      final isFuture = normalizedDate.isAfter(today);

      circles.add(
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () {
                // 如果是未来日期，不允许点击
                if (isFuture) return;
                // 触发日期选择回调
                widget.onDateSelected?.call(normalizedDate);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasCheckin
                      ? widget.item.color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !hasCheckin
                      ? Border.all(color: widget.item.color, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCheckin ? widget.item.color : Theme.of(context).hintColor,
                      fontWeight: hasCheckin || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (i < 6) {
        circles.add(const SizedBox(width: 4));
      }
    }

    return Row(children: circles);
  }

  Widget _buildMonthCalendar(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    // 标准化为今天的 00:00:00
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(now.year, now.month, day);
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final hasCheckin =
            widget.item.checkInRecords.containsKey(dateStr) &&
            widget.item.checkInRecords[dateStr]!.isNotEmpty;
        final isToday = date.isAtSameMomentAs(today);

        // 检查日期是否在未来（使用标准化日期比较）
        final isFuture = date.isAfter(today);

        return GestureDetector(
          onTap: () {
            // 如果是未来日期，不允许点击
            if (isFuture) return;
            // 触发日期选择回调
            widget.onDateSelected?.call(date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: hasCheckin
                  ? widget.item.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border:
                  isToday && !hasCheckin
                      ? Border.all(color: widget.item.color, width: 1)
                      : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                color: hasCheckin ? widget.item.color : theme.hintColor,
                fontWeight:
                    hasCheckin || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Logic Helpers ---

  Map<String, int> _calculateMonthlyStats() {
    final now = DateTime.now();
    final records = widget.item.getMonthlyRecords(now.year, now.month);
    int count = 0;
    records.forEach((_, list) => count += list.length);
    return {'count': count, 'days': records.length};
  }

  String _getWeeklyProgressText() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    int completedCount = 0;
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (widget.item.checkInRecords.containsKey(dateStr) &&
          widget.item.checkInRecords[dateStr]!.isNotEmpty) {
        completedCount++;
      }
    }
    return '$completedCount 次/周';
  }

  String _formatLastCheckinTime() {
    final lastDate = widget.item.lastCheckinDate;
    if (lastDate == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastDate);

    if (diff.inDays == 0) {
      final records = widget.item.getDateRecords(lastDate);
      if (records.isNotEmpty) {
        return _formatTimeOnly(records.first.checkinTime);
      }
      return '今天';
    } else if (diff.inDays == 1) {
      final records = widget.item.getDateRecords(lastDate);
      if (records.isNotEmpty) {
        return '昨天 ${_formatTimeOnly(records.first.checkinTime)}';
      }
      return '昨天';
    } else {
      return '${lastDate.month}-${lastDate.day}';
    }
  }

  String _formatTimeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
