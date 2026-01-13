import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/music_player_card.dart';

/// 音乐播放器卡片示例
class MusicPlayerCardExample extends StatelessWidget {
  const MusicPlayerCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('音乐播放器卡片')),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
        child: const Center(
          child: MusicPlayerCardWidget(
            albumArtUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
            title: 'This blessing in disguise',
            lyrics: [
              'I can see it\'s',
              'hard to find',
              'This blessing',
              'in disguise',
              'This blessing',
              'in disguise',
            ],
            currentPosition: 192, // 3:12 in seconds
            totalDuration: 349, // 5:49 in seconds
            isPlaying: true,
          ),
        ),
      ),
    );
  }
}
