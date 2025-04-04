import 'package:flutter/material.dart';
import '../models/timer_task.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class TimerTaskDetailsPage extends StatefulWidget {
  final TimerTask task;

  const TimerTaskDetailsPage({super.key, required this.task});

  @override
  State<TimerTaskDetailsPage> createState() => _TimerTaskDetailsPageState();
}

class _TimerTaskDetailsPageState extends State<TimerTaskDetailsPage> {
  late TimerTask _task;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    // 启动显示更新定时器，每秒更新一次
    _startDisplayTimer();
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 触发界面刷新
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _displayTimer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isPlaying) {
        _task.pause();
      } else {
        _task.start();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void didUpdateWidget(TimerTaskDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != oldWidget.task) {
      _task = widget.task;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_task.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(_task.completedDuration),
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  onPressed: _toggleTimer,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 48,
                  onPressed: () {
                    setState(() {
                      _task.reset();
                      _isPlaying = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
