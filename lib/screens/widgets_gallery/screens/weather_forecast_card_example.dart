import 'package:flutter/material.dart';

/// 天气预报卡片示例
class WeatherForecastCardExample extends StatelessWidget {
  const WeatherForecastCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('天气预报卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: WeatherForecastCardWidget(
            cityName: 'London',
            weatherDescription: 'Heavy showers',
            currentTemp: 12,
            lowTemp: 4,
            temperatureHistory: [0.70, 0.60, 0.55, 0.45, 0.35, 0.30, 0.25, 0.20, 0.20, 0.25],
          ),
        ),
      ),
    );
  }
}

/// 天气预报数据模型
class WeatherData {
  final String cityName;
  final String weatherDescription;
  final double currentTemp;
  final double lowTemp;
  final List<double> temperatureHistory;

  const WeatherData({
    required this.cityName,
    required this.weatherDescription,
    required this.currentTemp,
    required this.lowTemp,
    required this.temperatureHistory,
  });
}

/// 天气预报卡片小组件
class WeatherForecastCardWidget extends StatefulWidget {
  final String cityName;
  final String weatherDescription;
  final double currentTemp;
  final double lowTemp;
  final List<double> temperatureHistory;

  const WeatherForecastCardWidget({
    super.key,
    required this.cityName,
    required this.weatherDescription,
    required this.currentTemp,
    required this.lowTemp,
    required this.temperatureHistory,
  });

  @override
  State<WeatherForecastCardWidget> createState() => _WeatherForecastCardWidgetState();
}

class _WeatherForecastCardWidgetState extends State<WeatherForecastCardWidget>
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
        width: 340,
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),

            // 城市和天气信息
            _buildWeatherInfo(context, isDark),
            const SizedBox(height: 32),

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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.wb_sunny,
            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Weather',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _buildNavButton(context, isDark, Icons.chevron_left),
        const SizedBox(width: 8),
        _buildNavButton(context, isDark, Icons.chevron_right),
      ],
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(BuildContext context, bool isDark, IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: 20,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.weatherDescription,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 28,
                child: AnimatedFlipCounter(
                  value: widget.currentTemp * _fadeInAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '°',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 60,
                height: 28,
                child: AnimatedFlipCounter(
                  value: widget.lowTemp * _fadeInAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: Text(
                  '°',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 20,
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
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.temperatureHistory.length, (index) {
          final barHeight = widget.temperatureHistory[index];
          final isCurrent = index == 0;

          return _TemperatureBarWidget(
            height: barHeight,
            isCurrent: isCurrent,
            isDark: isDark,
            animation: _fadeInAnimation,
            index: index,
          );
        }).expand((widget) => [widget, const SizedBox(width: 6)]).take(widget.temperatureHistory.length * 2 - 1).toList(),
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

  const _TemperatureBarWidget({
    required this.height,
    required this.isCurrent,
    required this.isDark,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // 计算每个柱子的延迟动画
    final barAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.08,
        0.5 + index * 0.08,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: barAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 12,
          height: 64,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 12,
              height: 64 * height * barAnimation.value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isDark ? const Color(0xFF475569) : const Color(0xFF64748B))
                    : (isDark ? const Color(0xFF1E40AF) : const Color(0xFFBAE6FD)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}
