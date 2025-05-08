
import 'package:flutter/material.dart';
import '../controllers/tracker_controller.dart';

class TrackerSummaryCard extends StatelessWidget {
  const TrackerSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.flag,
              value: controller.getGoalCount(),
              label: '目标数',
            ),
            _buildStatItem(
              context,
              icon: Icons.note_add,
              value: controller.getTodayRecordCount(),
              label: '今日记录',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required int value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
