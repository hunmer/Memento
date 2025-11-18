import 'package:flutter/material.dart';
import '../../../l10n/checkin_localizations.dart';
import 'stat_card.dart';

class StatisticsSection extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const StatisticsSection({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatCard(
            title: CheckinLocalizations.of(context).totalCheckinCount,
            value: '${statistics['totalItems']}',
            icon: Icons.list_alt,
          ),
          StatCard(
            title: CheckinLocalizations.of(context).todayCheckin,
            value: '${statistics['todayCheckins'] ?? 0}',
            icon: Icons.today,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}