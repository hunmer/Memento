import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../l10n/day_localizations.dart';

class MemorialDayCard extends StatelessWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;

  const MemorialDayCard({
    super.key,
    required this.memorialDay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = DayLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: memorialDay.backgroundColor,
            image: memorialDay.backgroundImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(memorialDay.backgroundImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memorialDay.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  memorialDay.formattedTargetDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memorialDay.isExpired
                      ? localizations.daysPassed(memorialDay.daysPassed)
                      : localizations.daysRemaining(memorialDay.daysRemaining),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                if (memorialDay.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    memorialDay.notes.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}