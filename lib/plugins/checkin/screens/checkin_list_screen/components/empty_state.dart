import 'package:flutter/material.dart';
import '../../../l10n/checkin_localizations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            CheckinLocalizations.of(context)?.noRecords ?? '没有打卡项目',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            CheckinLocalizations.of(context)?.createCheckin ?? '点击下方按钮添加新的打卡项目',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}