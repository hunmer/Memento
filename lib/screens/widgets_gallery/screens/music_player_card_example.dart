import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
        child: const Center(
          child: MusicPlayerCardWidget(
            albumArtUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuChAOLt5u0er4__Bp0rfV05ioa26Y4hHez_fuqOlobjMz23KbKlE69I5g5mF_Y0VMl1HNjmbR5zy3KaTqsQw2U2TsC8Ha3ATc55trb49XdBuwzSYEAZdwAfEdPfWzyc1Ckrn6bFPsvUt4QVVhqI9mvIdFP317DlWD0oL2SEgMazNF5KhMPYKqGvxKM3F9r4aYILJ6-1vuKJfWeeNfPpB0ggyxPQ81TVAAQ1Shir7z73qpi3Y9F1hZaWpNnhaEF42CAws8VFZ5lX5Oc',
            title: 'This blessing in disguise',
            lyrics: [
              'I can see it\'s',
              'hard to find',
              'This blessing',
              'in disguise',
              'This blessing',
              'in disguise',
            ],
            currentPosition: 192, // 3:12 in seconds
            totalDuration: 349, // 5:49 in seconds
            isPlaying: true,
          ),
        ),
      ),
    );
  }
}

/// 音乐播放器卡片小组件
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

  const MusicPlayerCardWidget({
    super.key,
    required this.albumArtUrl,
    required this.title,
    required this.lyrics,
    required this.currentPosition,
    required this.totalDuration,
    this.isPlaying = true,
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
      width: 340,
      height: 306, // aspect ratio 1:0.9
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.albumArtUrl,
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
                    // Spotify 图标
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
                const SizedBox(width: 16),

                // 歌词
                Expanded(
                  child: _buildLyrics(isDark, textPrimaryColor, textSecondaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 进度条
          _buildProgressBar(isDark, textPrimaryColor),

          const SizedBox(height: 4),

          // 控制按钮和时间
          Row(
            children: [
              // 播放控制按钮
              Row(
                children: [
                  _buildControlButton(
                    isDark,
                    Icons.skip_previous,
                    textSecondaryColor,
                  ),
                  const SizedBox(width: 16),
                  _buildPlayPauseButton(isDark, textPrimaryColor, textSecondaryColor),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    isDark,
                    Icons.skip_next,
                    textSecondaryColor,
                  ),
                ],
              ),

              const Spacer(),

              // 时间显示
              _buildTimeDisplay(isDark, textPrimaryColor, textSecondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyrics(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.lyrics.length, (index) {
        final isHighlight = index == 2 || index == 3;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            widget.lyrics[index],
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? textPrimary : textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }

  Widget _buildProgressBar(bool isDark, Color textColor) {
    final progress = widget.currentPosition / widget.totalDuration;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress * _progressAnimation.value,
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

  Widget _buildControlButton(
    bool isDark,
    IconData icon,
    Color color,
  ) {
    return IconButton(
      icon: Icon(icon, size: 30),
      color: color,
      onPressed: () {},
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildPlayPauseButton(
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
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
          widget.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 30,
        ),
        color: isDark ? Colors.black : Colors.white,
        onPressed: () {},
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTimeDisplay(
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final currentMinutes = widget.currentPosition ~/ 60;
    final currentSeconds = widget.currentPosition % 60;
    final totalMinutes = widget.totalDuration ~/ 60;
    final totalSeconds = widget.totalDuration % 60;

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
