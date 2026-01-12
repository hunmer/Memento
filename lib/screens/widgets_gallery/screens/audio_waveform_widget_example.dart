import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/audio_waveform_card.dart';

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
        child: const Center(
          child: SizedBox(
            width: 340,
            height: 340,
            child: AudioWaveformCardWidget(
              title: 'New Audio',
              date: '12.8.24',
              duration: Duration(hours: 1, minutes: 12, seconds: 25),
            ),
          ),
        ),
      ),
    );
  }
}
