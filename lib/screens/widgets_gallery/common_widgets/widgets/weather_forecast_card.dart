import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 天气预报卡片
///
/// 展示城市天气信息和温度趋势的卡片，支持动画效果和深色主题。
/// 可用于天气信息展示、温度历史追踪等场景。
class WeatherForecastCard extends StatefulWidget {
  /// 城市名称
  final String cityName;

  /// 天气描述
  final String weatherDescription;

  /// 当前温度
  final double currentTemp;

  /// 最低温度
  final double lowTemp;

  /// 温度历史数据（用于绘制柱状图）
  final List<double> temperatureHistory;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const WeatherForecastCard({
    super.key,
    required this.cityName,
    required this.weatherDescription,
    required this.currentTemp,
    required this.lowTemp,
    required this.temperatureHistory,
    this.inline = false,
    this.size = MediumSize(),
  });

  /// 从属性数据创建组件
  factory WeatherForecastCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return WeatherForecastCard(
      cityName: props['cityName'] as String? ?? 'Unknown',
      weatherDescription: props['weatherDescription'] as String? ?? '',
      currentTemp: (props['currentTemp'] as num?)?.toDouble() ?? 0.0,
      lowTemp: (props['lowTemp'] as num?)?.toDouble() ?? 0.0,
      temperatureHistory: (props['temperatureHistory'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<WeatherForecastCard> createState() => _WeatherForecastCardState();
}

class _WeatherForecastCardState extends State<WeatherForecastCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.inline ? double.maxFinite : 340,
        padding: widget.size.getPadding(),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部标题栏
            _buildHeader(context, isDark),
            SizedBox(height: widget.size.getTitleSpacing()),

            // 城市和天气信息
            _buildWeatherInfo(context, isDark),
            SizedBox(height: widget.size.getTitleSpacing() * 1.5),

            // 温度趋势图
            _buildTemperatureChart(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          width: widget.size.getIconSize(),
          height: widget.size.getIconSize(),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.wb_sunny,
            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
            size: widget.size.getIconSize() * 0.5,
          ),
        ),
        SizedBox(width: widget.size.getSmallSpacing() * 3),
        Text(
          'Weather',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _buildNavButton(context, isDark, Icons.chevron_left),
        SizedBox(width: widget.size.getSmallSpacing() * 2),
        _buildNavButton(context, isDark, Icons.chevron_right),
      ],
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(BuildContext context, bool isDark, IconData icon) {
    return Container(
      width: widget.size.getIconSize(),
      height: widget.size.getIconSize(),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: widget.size.getIconSize() * 0.6,
      ),
    );
  }

  /// 构建天气信息区域
  Widget _buildWeatherInfo(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.cityName,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: widget.size.getSmallSpacing()),
        Text(
          widget.weatherDescription,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: widget.size.getTitleFontSize(),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: widget.size.getSmallSpacing()),
        SizedBox(
          height: widget.size.getIconSize(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: widget.size.getIconSize() * 2.5,
                height: widget.size.getIconSize(),
                child: AnimatedFlipCounter(
                  value: widget.currentTemp * _fadeInAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    fontSize: widget.size.getSubtitleFontSize() + 6,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(width: widget.size.getSmallSpacing()),
              Text(
                '°',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  fontSize: widget.size.getSubtitleFontSize() + 6,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              SizedBox(width: widget.size.getSmallSpacing()),
              SizedBox(
                width: widget.size.getIconSize() * 2,
                height: widget.size.getIconSize(),
                child: AnimatedFlipCounter(
                  value: widget.lowTemp * _fadeInAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: widget.size.getSubtitleFontSize() + 6,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(
                height: widget.size.getIconSize(),
                child: Text(
                  '°',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: widget.size.getSubtitleFontSize() + 6,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建温度趋势图表
  Widget _buildTemperatureChart(BuildContext context, bool isDark) {
    final bars = <Widget>[];
    for (int i = 0; i < widget.temperatureHistory.length; i++) {
      if (i > 0) {
        bars.add(SizedBox(width: widget.size.getBarSpacing()));
      }
      bars.add(_TemperatureBarWidget(
        height: widget.temperatureHistory[i],
        isCurrent: i == 0,
        isDark: isDark,
        animation: _fadeInAnimation,
        index: i,
        size: widget.size,
      ));
    }

    return SizedBox(
      height: widget.size.getIconSize() * 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars,
      ),
    );
  }
}

/// 温度柱状图组件
class _TemperatureBarWidget extends StatelessWidget {
  final double height;
  final bool isCurrent;
  final bool isDark;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _TemperatureBarWidget({
    required this.height,
    required this.isCurrent,
    required this.isDark,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 计算每个柱子的延迟动画
    final end = (0.4 + index * 0.06).clamp(0.0, 1.0);
    final barAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.06,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    final barHeight = size.getIconSize() * 2;

    return AnimatedBuilder(
      animation: barAnimation,
      builder: (context, child) {
        return SizedBox(
          width: size.getBarWidth(),
          height: barHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.getBarWidth(),
              height: barHeight * height * barAnimation.value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isDark ? const Color(0xFF475569) : const Color(0xFF64748B))
                    : (isDark ? const Color(0xFF1E40AF) : const Color(0xFFBAE6FD)),
                borderRadius: BorderRadius.circular(size.getBarWidth() / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
