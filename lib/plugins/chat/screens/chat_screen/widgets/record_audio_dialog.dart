import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RecordAudioDialog extends StatefulWidget {
  final Function(File audioFile, Duration duration) onStop;

  const RecordAudioDialog({
    super.key,
    required this.onStop,
  });

  @override
  State<RecordAudioDialog> createState() => _RecordAudioDialogState();
}

class _RecordAudioDialogState extends State<RecordAudioDialog> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  DateTime? _startTime;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟执行录音初始化，以确保对话框完全显示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _startRecording();
      }
    });
  }


  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // 检查录音权限
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw '需要录音权限才能录制语音消息';
      }

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(tempDir.path, 'audio_$timestamp.m4a');

      // 配置录音参数
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 2,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _startTime = DateTime.now();
      });

      // 更新录音时长
      _updateDuration();
    } catch (e) {
      debugPrint('开始录音时出错: $e');
      if (mounted) {
        // 显示错误提示对话框
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('录音失败'),
            content: Text(
              e.toString().contains('权限') 
                  ? '请在系统设置中允许应用使用麦克风，以便录制语音消息。'
                  : '开始录音时出现错误，请检查麦克风是否正常工作并重试。'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
        // 关闭录音对话框
        Navigator.of(context).pop();
      }
    }
  }

  void _updateDuration() {
    if (!mounted || !_isRecording || _startTime == null) return;

    setState(() {
      _duration = DateTime.now().difference(_startTime!);
    });

    Future.delayed(const Duration(seconds: 1), _updateDuration);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        widget.onStop(file, _duration);
      }
    } catch (e) {
      debugPrint('停止录音时出错: $e');
      if (mounted) {
        // 显示错误提示对话框
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('录音失败'),
            content: const Text('停止录音时出现错误，录音可能未能保存。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '录制语音消息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 停止录音按钮
                IconButton.filled(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(64, 64),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '点击停止按钮结束录音',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}