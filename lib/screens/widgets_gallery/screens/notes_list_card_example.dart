import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/notes_list_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 笔记列表卡片示例
class NotesListCardExample extends StatelessWidget {
  const NotesListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('笔记列表卡片')),
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
                    height: 180,
                    child: NotesListCardWidget(
                      size: const SmallSize(),
                      notes: const [
                        NoteItem(
                          title: 'Things to do in SF',
                          time: '8:12 AM',
                          preview: 'San Francisco is...',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 250,
                    child: NotesListCardWidget(
                      size: const MediumSize(),
                      notes: const [
                        NoteItem(
                          title: 'Things to do in San Francisco',
                          time: '8:12 AM',
                          preview: 'San Francisco is a beautiful city with...',
                        ),
                        NoteItem(
                          title: 'The Best Places in Paris',
                          time: 'Yesterday',
                          preview: 'Paris is a city of love...',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 350,
                    child: NotesListCardWidget(
                      size: const LargeSize(),
                      notes: const [
                        NoteItem(
                          title: 'Things to do in San Francisco',
                          time: '8:12 AM',
                          preview: 'San Francisco is a beautiful city with...',
                        ),
                        NoteItem(
                          title: 'The Best Places to Visit in Paris',
                          time: 'Yesterday',
                          preview: 'Paris is a city of love, romance...',
                        ),
                        NoteItem(
                          title: 'How to Write a Clear Email',
                          time: '6/4/24',
                          preview: 'Email is a powerful tool...',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: NotesListCardWidget(
                    size: const WideSize(),
                    notes: const [
                      NoteItem(
                        title: 'Things to do in San Francisco',
                        time: '8:12 AM',
                        preview: 'San Francisco is a beautiful city with...',
                      ),
                      NoteItem(
                        title: 'The Best Places to Visit in Paris',
                        time: 'Yesterday',
                        preview: 'Paris is a city of love, romance...',
                      ),
                      NoteItem(
                        title: 'How to Write a Clear Email',
                        time: '6/4/24',
                        preview: 'Email is a powerful tool...',
                      ),
                      NoteItem(
                        title: '10 Tips for Better Sleep',
                        time: 'Last week',
                        preview: 'Getting quality sleep is essential...',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: NotesListCardWidget(
                    size: const Wide2Size(),
                    notes: const [
                      NoteItem(
                        title: 'Things to do in San Francisco',
                        time: '8:12 AM',
                        preview: 'San Francisco is a beautiful city with...',
                      ),
                      NoteItem(
                        title: 'The Best Places to Visit in Paris',
                        time: 'Yesterday',
                        preview: 'Paris is a city of love, romance...',
                      ),
                      NoteItem(
                        title: 'How to Write a Clear Email',
                        time: '6/4/24',
                        preview: 'Email is a powerful tool...',
                      ),
                      NoteItem(
                        title: '10 Tips for Better Sleep',
                        time: 'Last week',
                        preview: 'Getting quality sleep is essential...',
                      ),
                      NoteItem(
                        title: 'Introduction to Machine Learning',
                        time: '2 weeks ago',
                        preview: 'Machine learning is transforming industries...',
                      ),
                    ],
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
