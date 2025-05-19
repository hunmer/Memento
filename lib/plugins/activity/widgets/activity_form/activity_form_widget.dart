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
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            ..._getMoodsList().map((mood) {
              final isSelected = mood == selectedMood;
              return InkWell(
              onTap: () => onMoodSelected(mood),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 55,
                height: 55,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
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
            InkWell(
              onTap: () async {
              final TextEditingController controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('输入心情'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '请输入心情表情或文字',
                    ),
                    maxLength: 4, // 限制输入长度
                    autofocus: true, // 自动获取焦点
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        Navigator.of(context).pop(value);
                      }
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          Navigator.of(context).pop(controller.text);
                        }
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                onMoodSelected(result);
              }
            },
            borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withAlpha(125),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                ),
              ),
            ),
        ],
        ),
      ],
    );
  }
  
  /// 获取合并后的心情列表，将最近使用的心情插入到候选列表前面，并截取前十个
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
    
    // 截取前10个
    if (combinedMoods.length > 10) {
      combinedMoods = combinedMoods.sublist(0, 10);
    }
    
    return combinedMoods;
  }
}