import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 时区滑块小组件示例
class TimeZoneSliderWidgetExample extends StatelessWidget {
  const TimeZoneSliderWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('时区滑块小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TimeZoneSliderWidget(
            location: 'Shibuya, Tokyo',
            gmtOffset: '+9',
            date: 'Aug 12',
            hour: 10,
            minute: 25,
            isPM: true,
            timeDifference: '~4H',
          ),
        ),
      ),
    );
  }
}

/// 时区数据模型
class TimeZoneData {
  final String location;
  final String gmtOffset;
  final String date;
  final int hour;
  final int minute;
  final bool isPM;
  final String timeDifference;

  const TimeZoneData({
    required this.location,
    required this.gmtOffset,
    required this.date,
    required this.hour,
    required this.minute,
    required this.isPM,
    required this.timeDifference,
  });
}

/// 时区滑块小组件
class TimeZoneSliderWidget extends StatefulWidget {
  final String location;
  final String gmtOffset;
  final String date;
  final int hour;
  final int minute;
  final bool isPM;
  final String timeDifference;

  const TimeZoneSliderWidget({
    super.key,
    required this.location,
    required this.gmtOffset,
    required this.date,
    required this.hour,
    required this.minute,
    required this.isPM,
    required this.timeDifference,
  });

  @override
  State<TimeZoneSliderWidget> createState() => _TimeZoneSliderWidgetState();
}

class _TimeZoneSliderWidgetState extends State<TimeZoneSliderWidget>
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
    final primaryColor = Theme.of(context).colorScheme.error;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部：地点和时区信息
                  _LocationInfo(
                    location: widget.location,
                    gmtOffset: widget.gmtOffset,
                    date: widget.date,
                    animation: _animation,
                    isDark: isDark,
                  ),

                  // 中间：滑块进度条
                  _SliderTrack(
                    progress: 0.67,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    animation: _animation,
                  ),

                  // 底部：时间和时差标签
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TimeDisplay(
                        hour: widget.hour,
                        minute: widget.minute,
                        isPM: widget.isPM,
                        animation: _animation,
                        isDark: isDark,
                      ),
                      _TimeDifferenceBadge(
                        timeDifference: widget.timeDifference,
                        animation: _animation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 地点信息
class _LocationInfo extends StatelessWidget {
  final String location;
  final String gmtOffset;
  final String date;
  final Animation<double> animation;
  final bool isDark;

  const _LocationInfo({
    required this.location,
    required this.gmtOffset,
    required this.date,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      gmtOffset,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 滑块进度条
class _SliderTrack extends StatelessWidget {
  final double progress;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _SliderTrack({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;

                return SizedBox(
                  height: 6,
                  width: trackWidth,
                  child: Stack(
                    children: [
                      // 背景轨道
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // 进度条
                      FractionallySizedBox(
                        widthFactor: progress * itemAnimation.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // 左滑块
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 右滑块
                      Positioned(
                        left: (progress - 0.02).clamp(0.0, 1.0) * trackWidth,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// 时间显示
class _TimeDisplay extends StatelessWidget {
  final int hour;
  final int minute;
  final bool isPM;
  final Animation<double> animation;
  final bool isDark;

  const _TimeDisplay({
    required this.hour,
    required this.minute,
    required this.isPM,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPM ? 'PM' : 'AM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedFlipCounter(
                      value: hour * itemAnimation.value,
                      textStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AnimatedFlipCounter(
                        value: minute * itemAnimation.value,
                        textStyle: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 时差标签
class _TimeDifferenceBadge extends StatelessWidget {
  final String timeDifference;
  final Animation<double> animation;

  const _TimeDifferenceBadge({
    required this.timeDifference,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: itemAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C759).withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              timeDifference,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
