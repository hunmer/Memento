import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    child: MusicPlayerCardWidget(
                      size: const SmallSize(),
                      albumArtUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
                      title: 'This blessing',
                      lyrics: const ['I can see it\'s', 'hard to find'],
                      currentPosition: 192,
                      totalDuration: 349,
                      isPlaying: true,
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
                    child: MusicPlayerCardWidget(
                      size: const MediumSize(),
                      albumArtUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
                      title: 'This blessing in disguise',
                      lyrics: const ['I can see it\'s', 'hard to find', 'This blessing'],
                      currentPosition: 192,
                      totalDuration: 349,
                      isPlaying: true,
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
                    child: MusicPlayerCardWidget(
                      size: const LargeSize(),
                      albumArtUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
                      title: 'This blessing in disguise',
                      lyrics: const ['I can see it\'s', 'hard to find', 'This blessing', 'in disguise', 'This blessing'],
                      currentPosition: 192,
                      totalDuration: 349,
                      isPlaying: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: MusicPlayerCardWidget(
                    size: const WideSize(),
                    albumArtUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
                    title: 'This blessing in disguise',
                    lyrics: const ['I can see it\'s', 'hard to find', 'This blessing', 'in disguise'],
                    currentPosition: 192,
                    totalDuration: 349,
                    isPlaying: true,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: MusicPlayerCardWidget(
                    size: const Wide2Size(),
                    albumArtUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
                    title: 'This blessing in disguise - Complete Album',
                    lyrics: const ['I can see it\'s', 'hard to find', 'This blessing', 'in disguise', 'This blessing', 'is here'],
                    currentPosition: 192,
                    totalDuration: 349,
                    isPlaying: true,
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
