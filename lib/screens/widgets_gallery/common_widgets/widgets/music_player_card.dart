import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 音乐播放器卡片小组件
///
/// 显示专辑封面、歌词、播放进度和控制按钮
class MusicPlayerCardWidget extends StatefulWidget {
  /// 专辑封面 URL
  final String albumArtUrl;

  /// 歌曲标题
  final String title;

  /// 歌词列表
  final List<String> lyrics;

  /// 当前播放位置（秒）
  final int currentPosition;

  /// 总时长（秒）
  final int totalDuration;

  /// 是否正在播放
  final bool isPlaying;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const MusicPlayerCardWidget({
    super.key,
    required this.albumArtUrl,
    required this.title,
    required this.lyrics,
    required this.currentPosition,
    required this.totalDuration,
    this.isPlaying = true,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MusicPlayerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MusicPlayerCardWidget(
      albumArtUrl: props['albumArtUrl'] as String? ?? '',
      title: props['title'] as String? ?? '',
      lyrics: (props['lyrics'] as List<dynamic>?)?.cast<String>() ?? [],
      currentPosition: props['currentPosition'] as int? ?? 0,
      totalDuration: props['totalDuration'] as int? ?? 0,
      isPlaying: props['isPlaying'] as bool? ?? true,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<MusicPlayerCardWidget> createState() => _MusicPlayerCardWidgetState();
}

class _MusicPlayerCardWidgetState extends State<MusicPlayerCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // 进度条动画
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
    // 延迟启动进度条动画
    Future.delayed(const Duration(milliseconds: 300), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : Colors.black;
    final textSecondaryColor =
        isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

    return Container(
      width: widget.inline ? double.maxFinite : 340,
      height: widget.inline ? double.maxFinite : 306,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 专辑封面和歌词
          Expanded(
            child: Row(
              children: [
                // 专辑封面
                _AlbumArtWidget(
                  albumArtUrl: widget.albumArtUrl,
                  animation: _animation,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),

                // 歌词
                Expanded(
                  child: _LyricsWidget(
                    lyrics: widget.lyrics,
                    animation: _animation,
                    textPrimaryColor: textPrimaryColor,
                    textSecondaryColor: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 进度条
          _ProgressBarWidget(
            currentPosition: widget.currentPosition,
            totalDuration: widget.totalDuration,
            animation: _progressAnimation,
            isDark: isDark,
          ),

          const SizedBox(height: 4),

          // 控制按钮和时间
          Row(
            children: [
              // 播放控制按钮
              _PlaybackControlsWidget(
                isPlaying: widget.isPlaying,
                animation: _animation,
                textSecondaryColor: textSecondaryColor,
                isDark: isDark,
                onPlayPauseToggle: () {},
                onPrevious: () {},
                onNext: () {},
              ),

              const Spacer(),

              // 时间显示
              _TimeDisplayWidget(
                currentPosition: widget.currentPosition,
                totalDuration: widget.totalDuration,
                primaryColor: textPrimaryColor,
                secondaryColor: textSecondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 专辑封面组件
class _AlbumArtWidget extends StatelessWidget {
  final String albumArtUrl;
  final Animation<double> animation;
  final bool isDark;

  const _AlbumArtWidget({
    required this.albumArtUrl,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final albumAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: albumAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: albumAnimation.value,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  albumArtUrl,
                  width: 115,
                  height: 115,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 115,
                      height: 115,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.album, size: 48),
                    );
                  },
                ),
              ),
              // 音乐图标
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 歌词组件
class _LyricsWidget extends StatelessWidget {
  final List<String> lyrics;
  final Animation<double> animation;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const _LyricsWidget({
    required this.lyrics,
    required this.animation,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final lyricsAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: lyricsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: lyricsAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(lyrics.length, (index) {
              final isHighlight = index == 2 || index == 3;
              final step = 0.1;
              final start = (index * step).clamp(0.0, 0.5);
              final end = (0.4 + index * step).clamp(0.0, 1.0);
              final itemAnimation = CurvedAnimation(
                parent: animation,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return AnimatedBuilder(
                animation: itemAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: itemAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - itemAnimation.value)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          lyrics[index],
                          style: TextStyle(
                            fontSize: isHighlight ? 16 : 14,
                            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                            color: isHighlight ? textPrimaryColor : textSecondaryColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}

/// 进度条组件
class _ProgressBarWidget extends StatelessWidget {
  final int currentPosition;
  final int totalDuration;
  final Animation<double> animation;
  final bool isDark;

  const _ProgressBarWidget({
    required this.currentPosition,
    required this.totalDuration,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentPosition / totalDuration;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress * animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 播放控制组件
class _PlaybackControlsWidget extends StatelessWidget {
  final bool isPlaying;
  final Animation<double> animation;
  final Color textSecondaryColor;
  final bool isDark;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PlaybackControlsWidget({
    required this.isPlaying,
    required this.animation,
    required this.textSecondaryColor,
    required this.isDark,
    required this.onPlayPauseToggle,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final controlsAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: controlsAnimation.value,
          child: Transform.scale(
            scale: controlsAnimation.value,
            child: Row(
              children: [
                _buildControlButton(Icons.skip_previous, textSecondaryColor, onPrevious),
                const SizedBox(width: 16),
                _buildPlayPauseButton(isDark, onPlayPauseToggle),
                const SizedBox(width: 16),
                _buildControlButton(Icons.skip_next, textSecondaryColor, onNext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 30),
      color: color,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildPlayPauseButton(bool isDark, VoidCallback onPressed) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.grey.shade900,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 30,
        ),
        color: isDark ? Colors.black : Colors.white,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// 时间显示组件
class _TimeDisplayWidget extends StatelessWidget {
  final int currentPosition;
  final int totalDuration;
  final Color primaryColor;
  final Color secondaryColor;

  const _TimeDisplayWidget({
    required this.currentPosition,
    required this.totalDuration,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final currentMinutes = currentPosition ~/ 60;
    final currentSeconds = currentPosition % 60;
    final totalMinutes = totalDuration ~/ 60;
    final totalSeconds = totalDuration % 60;

    return Row(
      children: [
        Text(
          '$currentMinutes:${currentSeconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
        Text(
          ' / ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: secondaryColor,
          ),
        ),
        Text(
          '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}
