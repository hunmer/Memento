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

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MusicPlayerCardWidget({
    super.key,
    required this.albumArtUrl,
    required this.title,
    required this.lyrics,
    required this.currentPosition,
    required this.totalDuration,
    this.isPlaying = true,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
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
      size: size,
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
      constraints: widget.inline ? null : widget.size.getHeightConstraints(),
      padding: widget.size.getPadding(),
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
                  size: widget.size,
                ),
                SizedBox(width: widget.size.getItemSpacing()),

                // 歌词
                Expanded(
                  child: _LyricsWidget(
                    lyrics: widget.lyrics,
                    animation: _animation,
                    textPrimaryColor: textPrimaryColor,
                    textSecondaryColor: textSecondaryColor,
                    size: widget.size,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 进度条
          _ProgressBarWidget(
            currentPosition: widget.currentPosition,
            totalDuration: widget.totalDuration,
            animation: _progressAnimation,
            isDark: isDark,
            size: widget.size,
          ),

          SizedBox(height: widget.size.getItemSpacing() / 2),

          // 控制按钮和时间
          Row(
            children: [
              // 播放控制按钮
              _PlaybackControlsWidget(
                isPlaying: widget.isPlaying,
                animation: _animation,
                textSecondaryColor: textSecondaryColor,
                isDark: isDark,
                size: widget.size,
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
                size: widget.size,
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
  final HomeWidgetSize size;

  const _AlbumArtWidget({
    required this.albumArtUrl,
    required this.animation,
    required this.isDark,
    required this.size,
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
                  width: size.getPadding().left * 9.5,
                  height: size.getPadding().left * 9.5,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: size.getPadding().left * 9.5,
                      height: size.getPadding().left * 9.5,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.album, size: size.getIconSize() * 2),
                    );
                  },
                ),
              ),
              // 音乐图标
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(size.getPadding().left / 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: size.getIconSize() / 3,
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
  final HomeWidgetSize size;

  const _LyricsWidget({
    required this.lyrics,
    required this.animation,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.size,
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
                        padding: EdgeInsets.only(bottom: size.getPadding().left / 10),
                        child: Text(
                          lyrics[index],
                          style: TextStyle(
                            fontSize: isHighlight ? size.getIconSize() - 2 : size.getIconSize() - 4,
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
  final HomeWidgetSize size;

  const _ProgressBarWidget({
    required this.currentPosition,
    required this.totalDuration,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentPosition / totalDuration;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: size.getPadding().left / 2.5,
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
  final HomeWidgetSize size;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PlaybackControlsWidget({
    required this.isPlaying,
    required this.animation,
    required this.textSecondaryColor,
    required this.isDark,
    required this.size,
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
                SizedBox(width: size.getItemSpacing()),
                _buildPlayPauseButton(isDark, onPlayPauseToggle),
                SizedBox(width: size.getItemSpacing()),
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
      icon: Icon(icon, size: size.getIconSize()),
      color: color,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildPlayPauseButton(bool isDark, VoidCallback onPressed) {
    final buttonSize = size.getPadding().left * 2.4;
    return Container(
      width: buttonSize,
      height: buttonSize,
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
          size: size.getIconSize(),
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
  final HomeWidgetSize size;

  const _TimeDisplayWidget({
    required this.currentPosition,
    required this.totalDuration,
    required this.primaryColor,
    required this.secondaryColor,
    required this.size,
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
            fontSize: size.getIconSize() - 4,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
        Text(
          ' / ',
          style: TextStyle(
            fontSize: size.getIconSize() - 6,
            fontWeight: FontWeight.normal,
            color: secondaryColor,
          ),
        ),
        Text(
          '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: size.getIconSize() - 4,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}
