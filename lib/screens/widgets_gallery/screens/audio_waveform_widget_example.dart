import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/audio_waveform_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 音频波形小组件示例
class AudioWaveformWidgetExample extends StatelessWidget {
  const AudioWaveformWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('音频波形小组件')),
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
                    child: AudioWaveformCardWidget(
                      title: 'New Audio',
                      date: '12.8.24',
                      duration: Duration(hours: 1, minutes: 12, seconds: 25),
                      size: const SmallSize(),
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
                    child: AudioWaveformCardWidget(
                      title: 'New Audio',
                      date: '12.8.24',
                      duration: Duration(hours: 1, minutes: 12, seconds: 25),
                      size: const MediumSize(),
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
                    child: AudioWaveformCardWidget(
                      title: 'New Audio',
                      date: '12.8.24',
                      duration: Duration(hours: 1, minutes: 12, seconds: 25),
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: AudioWaveformCardWidget(
                    title: 'New Audio Recording',
                    date: '12.8.24',
                    duration: Duration(hours: 1, minutes: 12, seconds: 25),
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: AudioWaveformCardWidget(
                    title: 'Complete New Audio Recording Session',
                    date: '12.8.24',
                    duration: Duration(hours: 1, minutes: 12, seconds: 25),
                    size: const Wide2Size(),
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
