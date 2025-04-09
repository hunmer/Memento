import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../l10n/day_localizations.dart';

class MemorialDayListItem extends StatelessWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;

  const MemorialDayListItem({
    super.key,
    required this.memorialDay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = DayLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: _buildLeadingIcon(),
        title: Text(memorialDay.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(memorialDay.formattedTargetDate),
            Text(
              memorialDay.isExpired
                  ? localizations.daysPassed(memorialDay.daysPassed)
                  : localizations.daysRemaining(memorialDay.daysRemaining),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: memorialDay.backgroundColor,
        shape: BoxShape.circle,
        image: memorialDay.backgroundImageUrl != null
            ? DecorationImage(
                image: NetworkImage(memorialDay.backgroundImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Center(
        child: Text(
          memorialDay.isExpired ? '过' : memorialDay.isToday ? '今' : '待',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (memorialDay.isToday) {
      return Colors.green;
    } else if (memorialDay.isExpired) {
      return Colors.grey;
    } else if (memorialDay.daysRemaining <= 7) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}