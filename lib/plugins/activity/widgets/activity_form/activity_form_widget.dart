import 'package:flutter/material.dart';
import '../../models/activity_record.dart';
import '../../../../plugins/diary/l10n/diary_localizations.dart';
import 'constants.dart';
import 'activity_form_state.dart';

class ActivityFormWidget extends StatefulWidget {
  final ActivityRecord? activity;
  final Function(ActivityRecord) onSave;
  final DateTime selectedDate;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final DateTime? lastActivityEndTime;

  const ActivityFormWidget({
    super.key,
    this.activity,
    required this.onSave,
    required this.selectedDate,
    this.initialStartTime,
    this.initialEndTime,
    this.lastActivityEndTime,
  });

  @override
  State<ActivityFormWidget> createState() => ActivityFormState();
}

class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final Function(String) onMoodSelected;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            DiaryLocalizations.of(context)!.mood,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          children: kMoods.map((mood) {
            final isSelected = mood == selectedMood;
            return InkWell(
              onTap: () => onMoodSelected(mood),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withAlpha(50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  mood,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}