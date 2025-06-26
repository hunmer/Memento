import 'dart:io';

import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/widgets/file_preview/l10n/file_preview_localizations.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../utils/image_utils.dart';

class VideoPreview extends StatefulWidget {
  final String filePath;

  const VideoPreview({super.key, required this.filePath});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // 使用 PathUtils 转换路径
      final absolutePath = await ImageUtils.getAbsolutePath(widget.filePath);
      if (absolutePath.isEmpty) {
        throw Exception('无法获取视频文件的绝对路径');
      }

      final videoFile = File(absolutePath);
      if (!await videoFile.exists()) {
        throw Exception('视频文件不存在：$absolutePath');
      }

      debugPrint('正在初始化视频播放器，文件路径: $absolutePath');

      // 打开视频文件
      await _player.open(Media(absolutePath));

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('视频初始化错误: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isInitialized = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.videoLoadFailed}: ${e.toString()}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                FilePreviewLocalizations.of(context)!.videoLoadFailed,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingVideo,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Video(controller: _controller),
                  _PlayPauseOverlay(player: _player),
                ],
              ),
            ),
          ),
        ),
        _VideoProgressIndicator(player: _player),
      ],
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  final Player player;

  const _PlayPauseOverlay({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final bool isPlaying = snapshot.data ?? false;
        return Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 50),
              reverseDuration: const Duration(milliseconds: 200),
              child:
                  isPlaying
                      ? const SizedBox.shrink()
                      : Container(color: Colors.black26),
            ),
            GestureDetector(
              onTap: () {
                isPlaying ? player.pause() : player.play();
              },
            ),
          ],
        );
      },
    );
  }
}

class _VideoProgressIndicator extends StatelessWidget {
  final Player player;

  const _VideoProgressIndicator({required this.player});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds'
        : '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: player.stream.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: player.stream.duration,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor:
                              Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(76),
                          thumbColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            player.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          StreamBuilder<bool>(
                            stream: player.stream.playing,
                            builder: (context, snapshot) {
                              final bool isPlaying = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  isPlaying ? player.pause() : player.play();
                                },
                              );
                            },
                          ),
                          Text(
                            _formatDuration(duration),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
