import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: JournalPromptCardWidget(
                      size: const SmallSize(),
                      weekday: 'Monday',
                      prompt: 'How will you make tomorrow meaningful?',
                      onNewPressed: _dummyCallback,
                      onSyncPressed: _dummyCallback,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: JournalPromptCardWidget(
                      size: const MediumSize(),
                      weekday: 'Monday',
                      prompt: 'How will you make tomorrow meaningful?',
                      onNewPressed: _dummyCallback,
                      onSyncPressed: _dummyCallback,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: JournalPromptCardWidget(
                      size: const LargeSize(),
                      weekday: 'Monday',
                      prompt: 'How will you make tomorrow meaningful?',
                      onNewPressed: _dummyCallback,
                      onSyncPressed: _dummyCallback,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: JournalPromptCardWidget(
                    size: const WideSize(),
                    weekday: 'Monday',
                    prompt: 'How will you make tomorrow meaningful? How will you make tomorrow meaningful?',
                    onNewPressed: _dummyCallback,
                    onSyncPressed: _dummyCallback,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 320,
                  child: JournalPromptCardWidget(
                    size: const Wide2Size(),
                    weekday: 'Monday',
                    prompt: 'How will you make tomorrow meaningful? How will you make tomorrow meaningful? How will you make tomorrow meaningful?',
                    onNewPressed: _dummyCallback,
                    onSyncPressed: _dummyCallback,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
