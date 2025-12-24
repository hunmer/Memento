import 'package:flutter/material.dart';
import 'package:Memento/widgets/tts_settings_dialog.dart';

/// TTS 设置对话框示例
class TTSSettingsExample extends StatelessWidget {
  const TTSSettingsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS 设置对话框'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TTSSettingsDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个文本转语音设置对话框。'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showTTSSettings(context),
                icon: const Icon(Icons.record_voice_over),
                label: const Text('打开 TTS 设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTTSSettings(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const TTSSettingsDialog(),
    );
  }
}
