import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/plugins/checkin/screens/checkin_record_screen.dart';
import 'package:Memento/plugins/checkin/widgets/checkin_record_dialog.dart';
import 'package:intl/intl.dart';
import 'weekly_checkin_circles.dart';

class CheckinItemCard extends StatelessWidget {
  final CheckinItem item;
  final int index;
  final int itemIndex;
  final CheckinListController controller;
  final VoidCallback onStateChanged;

  const CheckinItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.itemIndex,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content;
    switch (item.cardStyle) {
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
          onTap: () {
            NavigationHelper.push(context, CheckinRecordScreen(
                      checkinItem: item,
                      controller: controller,),
            ).then((_) => onStateChanged());
          },
          onLongPress: () {
            controller.showItemOptionsDialog(item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
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
                      item.name,
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
                      color: item.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (item.lastCheckinDate != null)
                  Row(
                    children: [
                      Text(
                        _formatLastCheckinTime(),
                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.hintColor,
                      ),
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
              child: WeeklyCheckinCircles(
                item: item,
                onDateSelected: (selectedDate) {
                  _showCheckinDialog(context, selectedDate);
                },
              ),
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
                Icon(item.icon, color: item.color, size: 20),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.lastCheckinDate != null)
              Row(
                children: [
                  Text(
                    DateFormat('HH:mm').format(item.lastCheckinDate!),
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStatItem(context, Icons.checklist_rtl, stats['count']!.toString(), '本次次数', Colors.blue),
              _buildSmallStatItem(context, Icons.calendar_today, stats['days']!.toString(), '本次天数', Colors.purple),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Progress Button (Acting as +1)
        InkWell(
          onTap: () => _showCheckinDialog(context, DateTime.now()),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Progress Bar
                FractionallySizedBox(
                  widthFactor: (stats['count']! / 30).clamp(0.0, 1.0), // Example target 30
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Text
                Center(
                  child: Text(
                    '${stats['count']}/30', // Example target
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (item.lastCheckinDate != null)
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
            Expanded(
              child: _buildMonthCalendar(context, theme),
            ),
            const SizedBox(width: 16),
            
            // Right Side Stats & Button
            SizedBox(
              width: 80, // Fixed width for right column
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceAround,
                       children: [
                         Expanded(child: _buildSmallStatItem(context, Icons.checklist_rtl, stats['count']!.toString(), '次数', Colors.blue)),
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
        color: item.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, color: item.color, size: 24),
    );
  }

  Widget _buildPlusOneButton(BuildContext context, {required double size}) {
    return InkWell(
      onTap: () => _showCheckinDialog(context, DateTime.now()),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '+1',
            style: TextStyle(
              color: item.color,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStatItem(BuildContext context, IconData icon, String value, String label, Color color) {
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

  Widget _buildMonthCalendar(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    // Adjust weekday to start from 0 (Monday) to 6 (Sunday) if needed, 
    // or just use grid indices. Text '1' should correspond to day 1.
    
    // Reference HTML just lists numbers 1 to 31. Let's do that for simplicity 
    // to match the visual. It's a simple grid of numbers.
    
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
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final hasCheckin = item.checkInRecords.containsKey(dateStr) && item.checkInRecords[dateStr]!.isNotEmpty;
        final isToday = day == now.day;

        return Container(
          decoration: BoxDecoration(
            color: hasCheckin ? item.color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isToday && !hasCheckin ? Border.all(color: item.color, width: 1) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              color: hasCheckin ? item.color : theme.hintColor,
              fontWeight: hasCheckin || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  // --- Logic Helpers ---

  void _showCheckinDialog(BuildContext context, DateTime date) {
    showDialog(
      context: context,
      builder:
          (context) => CheckinRecordDialog(
            item: item,
            controller: controller,
            onCheckinCompleted: onStateChanged,
            selectedDate: date,
          ),
    );
  }

  Map<String, int> _calculateMonthlyStats() {
    final now = DateTime.now();
    final records = item.getMonthlyRecords(now.year, now.month);
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
      if (item.checkInRecords.containsKey(dateStr) &&
          item.checkInRecords[dateStr]!.isNotEmpty) {
        completedCount++;
      }
    }
    return '$completedCount 次/周';
  }

  String _formatLastCheckinTime() {
    final lastDate = item.lastCheckinDate;
    if (lastDate == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastDate);

    if (diff.inDays == 0) {
      final records = item.getDateRecords(lastDate);
      if (records.isNotEmpty) {
        return DateFormat('HH:mm').format(records.first.checkinTime);
      }
      return '今天';
    } else if (diff.inDays == 1) {
      final records = item.getDateRecords(lastDate);
      if (records.isNotEmpty) {
        return '昨天 ${DateFormat('HH:mm').format(records.first.checkinTime)}';
      }
      return '昨天';
    } else {
      return DateFormat('MM-dd').format(lastDate);
    }
  }
}
