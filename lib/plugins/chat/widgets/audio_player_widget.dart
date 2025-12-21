import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final int durationInSeconds;
  final bool isLocalFile;
  final Color primaryColor;
  final Color backgroundColor;
  final Color progressColor;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.durationInSeconds = 0,
    this.isLocalFile = true,
    this.primaryColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blue,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    setState(() => _isLoading = true);

    try {
      // 设置音频文件
      if (widget.isLocalFile) {
        // 使用 ImageUtils.getAbsolutePath 转换相对路径为绝对路径
        final filePath = await ImageUtils.getAbsolutePath(widget.audioPath);

        await _audioPlayer.setSource(DeviceFileSource(filePath));
      } else {
        await _audioPlayer.setSource(UrlSource(widget.audioPath));
      }

      // 设置音频时长
      if (widget.durationInSeconds > 0) {
        _duration = Duration(seconds: widget.durationInSeconds);
      } else {
        _duration = await _audioPlayer.getDuration() ?? Duration.zero;
      }

      // 监听播放状态
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      // 监听播放位置
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // 监听播放完成
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          // 播放完成时重置位置，但不在这里 setState，避免冲突
          _position = Duration.zero;
        }
      });

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('初始化音频播放器时出错: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // 如果已经播放完成，需要重新设置音频源
      if (_position >= _duration || _position == Duration.zero) {
        await _replay();
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _replay() async {
    try {
      setState(() => _isLoading = true);

      // 重新设置音频源
      if (widget.isLocalFile) {
        final filePath = await ImageUtils.getAbsolutePath(widget.audioPath);
        await _audioPlayer.setSource(DeviceFileSource(filePath));
      } else {
        await _audioPlayer.setSource(UrlSource(widget.audioPath));
      }

      // 重置播放位置
      _position = Duration.zero;

      // 开始播放
      await _audioPlayer.resume();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('重新播放音频时出错: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seek(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  void _changeSpeed() {
    // 切换播放速度：1.0x -> 1.5x -> 2.0x -> 1.0x
    setState(() {
      if (_playbackSpeed >= 2.0) {
        _playbackSpeed = 1.0;
      } else {
        _playbackSpeed += 0.5;
      }
    });
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放/暂停按钮
          _isLoading
              ? SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.primaryColor,
                  ),
                ),
              )
              : IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: widget.primaryColor,
                  size: 36,
                ),
                onPressed: _isInitialized ? _playPause : null,
              ),

          const SizedBox(width: 8),

          // 进度条
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 时间显示
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.primaryColor,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                // 进度滑块
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: widget.progressColor,
                    inactiveTrackColor: widget.backgroundColor.withValues(
                      alpha: 0.3,
                    ),
                    thumbColor: widget.primaryColor,
                    overlayColor: widget.primaryColor.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(
                      0,
                      _duration.inSeconds.toDouble(),
                    ),
                    onChanged: _isInitialized ? _seek : null,
                  ),
                ),
              ],
            ),
          ),

          // 播放速度按钮
          TextButton(
            onPressed: _isInitialized ? _changeSpeed : null,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '${_playbackSpeed}x',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
