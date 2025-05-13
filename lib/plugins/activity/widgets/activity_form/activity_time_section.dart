import 'package:flutter/material.dart';
import '../../../../plugins/diary/l10n/diary_localizations.dart';
import 'activity_form_utils.dart';

class ActivityTimeSection extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime selectedDate;
  final TextEditingController durationController;
  final Function(bool) onSelectTime;
  final Function(String) onDurationChanged;

  const ActivityTimeSection({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.selectedDate,
    required this.durationController,
    required this.onSelectTime,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = DiaryLocalizations.of(context)!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 开始时间
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => onSelectTime(true),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.startTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 间隔时间按钮
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(l10n.editInterval),
                    content: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.interval,
                        suffixText: l10n.minutes,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButton),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(durationController.text);
                        },
                        child: Text(l10n.confirmButton),
                      ),
                    ],
                  ),
                );

                if (result != null) {
                  onDurationChanged(result);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.interval,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${calculateDuration(selectedDate, startTime, endTime)}${l10n.minutes}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 结束时间
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => onSelectTime(false),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.endTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // 如果endTime是00:00，显示为23:59
                    endTime.hour == 0 && endTime.minute == 0
                        ? '23:59'
                        : '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}