import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/notes_list_card.dart';

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
        child: const Center(
          child: NotesListCardWidget(
            notes: [
              NoteItem(
                title: 'Things to do in San Francisco',
                time: '8:12 AM',
                preview: 'San Francisco is a beautiful city with...',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBykhyLQimYqgyqS7FAuZ85nBHtlSQUB_5dhHrI-q1jPlOTgTQL6KlVk6_hjzXy7qucN9kjhtEt924uP2WJpCSH03hMy0fQPzD_fNwuv0LddeoHfOtyehH2H0bgF-sm_ih6urXvD8hqSo7msdnOILRVWbDq3aQKSGSsXLFEgEP08f3Ywq49KY2XFbJHgrNGDlyTGezM_vDJ9Dc6-yybzXvNVtcv04ESHRjLJkT1K6Call5PufNQLUy7zyBdNUEmaPs3I9upyYTreg',
              ),
              NoteItem(
                title: 'The Best Places to Visit in Paris',
                time: 'Yesterday',
                preview: 'Paris is a city of love, romance...',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAGQPD1Xp3dSJRxZPEHVjuJ6vKuTsdkjLexjj39r0wDPXma9pcKM7PIzj093abx_AFfcksbZwBcCO-nbXEL2SMCyB3B5O-ZDmZRWXKOPs9vddGAEKIf_t41jwL9dFD04mVLck3xYDPZKya_p7GWtKGh8J76hhhpLc8PTE-y-hnCqn3xXCmw5gJajThTnFbD-T6wkAOTeniQ-JLrlhgdPWitT4M2cwWGAYhgRFiFSovPWdlEGAdveRbIXjKmQUugEYkrrsCZXEsVdw',
              ),
              NoteItem(
                title: 'How to Write a Clear and Concise Emails',
                time: '6/4/24',
                preview: 'Email is a powerful tool that can be used...',
              ),
              NoteItem(
                title: 'The Importance of Taking Notes',
                time: '6/2/24',
                preview: 'Taking notes is an important skill that ca...',
              ),
              NoteItem(
                title: 'Designing for Accessibility',
                time: '5/31/24',
                preview: 'Accessibility is important for all users...',
              ),
              NoteItem(
                title: 'User Research Findings',
                time: '5/31/24',
                preview: 'Users want to be able to customize the...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
