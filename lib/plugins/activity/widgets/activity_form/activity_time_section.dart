import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wheel_picker/wheel_picker.dart';
import 'package:Memento/plugins/diary/l10n/diary_localizations.dart';

class ActivityTimeSection extends StatelessWidget {
  static const int _maxIntervalMinutes = 24 * 60; // cover full day range
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
    DiaryLocalizations.of(context);
    final appL10n = AppLocalizations.of(context)!;

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
                    appL10n.startTime,
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
        // 间隔时间选择器
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  appL10n.interval,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(50),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.unknown,
                        },
                      ),
                      child: WheelPicker(
                        controller: WheelPickerController(
                          itemCount: _maxIntervalMinutes,
                          initialIndex: int.tryParse(durationController.text) ?? 0,
                        ),
                        style: const WheelPickerStyle(
                          itemExtent: 40,
                          squeeze: 1.25,
                          diameterRatio: 0.8,
                          surroundingOpacity: 0.25,
                          magnification: 1.2,
                        ),
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              '$index${appL10n.minutes}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                        onIndexChanged: (index, _) {
                          durationController.text = index.toString();
                          onDurationChanged(index.toString());
                        },
                      ),
                    ),
                  ),
                ),
              ],
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
                    appL10n.endTime,
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
