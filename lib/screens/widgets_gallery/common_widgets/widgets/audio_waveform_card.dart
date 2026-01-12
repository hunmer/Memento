import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 音频波形小组件
///
/// 用于显示音频录制信息，包括标题、日期、时长和波形可视化
class AudioWaveformCardWidget extends StatefulWidget {
  /// 音频标题
  final String title;

  /// 录制日期
  final String date;

  /// 音频时长
  final Duration duration;

  /// 主题色
  final Color? primaryColor;

  const AudioWaveformCardWidget({
    super.key,
    required this.title,
    required this.date,
    required this.duration,
    this.primaryColor,
  });

  /// 从 props 创建实例（用于通用小组件系统）
  factory AudioWaveformCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析时长（秒数）
    final durationInSeconds = (props['durationInSeconds'] as num?)?.toInt() ?? 0;
    final duration = Duration(seconds: durationInSeconds);

    return AudioWaveformCardWidget(
      title: props['title'] as String? ?? '未命名音频',
      date: props['date'] as String? ?? '',
      duration: duration,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
    );
  }

  @override
  State<AudioWaveformCardWidget> createState() =>
      _AudioWaveformCardWidgetState();
}

class _AudioWaveformCardWidgetState extends State<AudioWaveformCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final effectivePrimaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部：标题和设置按钮
                  _buildHeader(isDark),

                  // 中间：波形动画
                  _buildWaveform(effectivePrimaryColor, isDark),

                  // 底部：时间和播放按钮
                  _buildFooter(effectivePrimaryColor, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建顶部标题区域
  Widget _buildHeader(bool isDark) {
    final titleAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: titleAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: titleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建波形动画
  Widget _buildWaveform(Color primaryColor, bool isDark) {
    final waveformAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    return SizedBox(
      height: 96,
      child: AnimatedBuilder(
        animation: waveformAnimation,
        builder: (context, child) {
          return _WaveformBars(
            primaryColor: primaryColor,
            isDark: isDark,
            animation: waveformAnimation,
          );
        },
      ),
    );
  }

  /// 构建底部时间和播放按钮
  Widget _buildFooter(Color primaryColor, bool isDark) {
    final footerAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: footerAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: footerAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeDisplay(
                duration: widget.duration,
                animation: footerAnimation,
                isDark: isDark,
              ),
              _PlayPauseButton(
                primaryColor: primaryColor,
                animation: footerAnimation,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 波形条组件
class _WaveformBars extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _WaveformBars({
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // 模拟波形高度数据 (24个条)
    final heights = [
      12.0,
      20.0,
      25.0,
      12.0,
      24.0,
      32.0,
      16.0,
      28.0,
      20.0,
      12.0,
      24.0,
      40.0,
      20.0,
      28.0,
      56.0,
      24.0,
      12.0,
      32.0,
      20.0,
      12.0,
      20.0,
      28.0,
      24.0,
      12.0,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(heights.length, (index) {
        final baseHeight = heights[index];
        final isPlayed = index < 12;
        final isPlayingPosition = index == 12;

        // 计算每个条的延迟动画
        final step = 0.03;
        final start = (index * step).clamp(0.0, 0.7);
        final end = (0.5 + index * step).clamp(0.0, 1.0);
        final itemAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: _WaveformBar(
            height: baseHeight * itemAnimation.value,
            color: isPlayingPosition
                ? primaryColor
                : isPlayed
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300),
            width: isPlayingPosition ? 6 : 4,
            isPlayingPosition: isPlayingPosition,
            primaryColor: primaryColor,
          ),
        );
      }),
    );
  }
}

/// 单个波形条
class _WaveformBar extends StatelessWidget {
  final double height;
  final Color color;
  final double width;
  final bool isPlayingPosition;
  final Color primaryColor;

  const _WaveformBar({
    required this.height,
    required this.color,
    required this.width,
    required this.isPlayingPosition,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isPlayingPosition ? primaryColor : color,
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }
}

/// 时间显示组件
class _TimeDisplay extends StatelessWidget {
  final Duration duration;
  final Animation<double> animation;
  final bool isDark;

  const _TimeDisplay({
    required this.duration,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Row(
      children: [
        AnimatedFlipCounter(
          value: hours * animation.value,
          textStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
            letterSpacing: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        Text(
          ':',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        AnimatedFlipCounter(
          value: minutes * animation.value,
          textStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
            letterSpacing: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        Text(
          ':',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        AnimatedFlipCounter(
          value: seconds * animation.value,
          textStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
            letterSpacing: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
      ],
    );
  }
}

/// 播放/暂停按钮组件
class _PlayPauseButton extends StatefulWidget {
  final Color primaryColor;
  final Animation<double> animation;

  const _PlayPauseButton({
    required this.primaryColor,
    required this.animation,
  });

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  bool _isPlaying = true;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: widget.animation.value * (_isPressed ? 0.95 : 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => setState(() => _isPlaying = !_isPlaying),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
