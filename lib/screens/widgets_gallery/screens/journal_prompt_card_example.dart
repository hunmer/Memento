import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/journal_prompt_card.dart';

/// 日记提示卡片示例
class JournalPromptCardExample extends StatelessWidget {
  const JournalPromptCardExample({super.key});

  static void _dummyCallback() {}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('日记提示卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: JournalPromptCardWidget(
            weekday: 'Monday',
            prompt: 'How will you make tomorrow meaningful?',
            onNewPressed: _dummyCallback,
            onSyncPressed: _dummyCallback,
          ),
        ),
      ),
    );
  }
}
