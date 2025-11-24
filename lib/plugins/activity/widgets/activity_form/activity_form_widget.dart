import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
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
  final List<String>? recentMoods;
  final List<String>? recentTags;

  const ActivityFormWidget({
    super.key,
    this.activity,
    required this.onSave,
    required this.selectedDate,
    this.initialStartTime,
    this.initialEndTime,
    this.lastActivityEndTime,
    this.recentMoods,
    this.recentTags,
  });

  @override
  State<ActivityFormWidget> createState() => ActivityFormState();
}

class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final Function(String) onMoodSelected;
  final List<String>? recentMoods;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
    this.recentMoods,
  });

  @override
  Widget build(BuildContext context) {
    final moods = _getMoodsList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (4 * 12)) / 5; // 5 items per row, 12px gap
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...moods.map((mood) {
              final isSelected = mood == selectedMood;
              return InkWell(
                onTap: () => onMoodSelected(mood),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: itemWidth,
                  height: itemWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(mood, style: const TextStyle(fontSize: 28)),
                ),
              );
            }),
            InkWell(
              onTap: () async {
                final TextEditingController controller = TextEditingController();
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(ActivityLocalizations.of(context).inputMood),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '请输入心情表情或文字',
                      ),
                      maxLength: 4,
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          Navigator.of(context).pop(value);
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            Navigator.of(context).pop(controller.text);
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.confirm),
                      ),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  onMoodSelected(result);
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: itemWidth,
                height: itemWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add, 
                  size: 24, 
                  color: Colors.grey.shade400
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  /// 获取合并后的心情列表，将最近使用的心情插入到候选列表前面，并截取前9个（留一个位置给添加按钮）
  List<String> _getMoodsList() {
    // 创建一个新的列表来存储最终结果
    List<String> combinedMoods = [];

    // 如果有最近使用的心情，先添加它们
    if (recentMoods != null && recentMoods!.isNotEmpty) {
      combinedMoods.addAll(recentMoods!);
    }

    // 添加默认心情，但排除已经在最近使用中的
    for (String mood in kMoods) {
      if (!combinedMoods.contains(mood)) {
        combinedMoods.add(mood);
      }
    }

    // 截取前9个
    if (combinedMoods.length > 9) {
      combinedMoods = combinedMoods.sublist(0, 9);
    }

    return combinedMoods;
  }
}
