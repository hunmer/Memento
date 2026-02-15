import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/weather_forecast_card.dart';

/// 天气预报卡片示例
///
/// 展示如何使用 WeatherForecastCard 组件
class WeatherForecastCardExample extends StatelessWidget {
  const WeatherForecastCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('天气预报卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: WeatherForecastCard(
                      size: HomeWidgetSize.small,
                      cityName: 'London',
                      weatherDescription: 'Heavy showers',
                      currentTemp: 12,
                      lowTemp: 4,
                      temperatureHistory: [0.70, 0.60, 0.55, 0.45, 0.35, 0.30, 0.25, 0.20, 0.20, 0.25],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: WeatherForecastCard(
                      size: HomeWidgetSize.medium,
                      cityName: 'London',
                      weatherDescription: 'Heavy showers',
                      currentTemp: 12,
                      lowTemp: 4,
                      temperatureHistory: [0.70, 0.60, 0.55, 0.45, 0.35, 0.30, 0.25, 0.20, 0.20, 0.25],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: WeatherForecastCard(
                      size: HomeWidgetSize.large,
                      cityName: 'London',
                      weatherDescription: 'Heavy showers',
                      currentTemp: 12,
                      lowTemp: 4,
                      temperatureHistory: [0.70, 0.60, 0.55, 0.45, 0.35, 0.30, 0.25, 0.20, 0.20, 0.25],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}

/// 使用 fromProps 工厂方法创建天气预报卡片的示例
class WeatherForecastCardPropsExample extends StatelessWidget {
  const WeatherForecastCardPropsExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 从属性字典创建组件（适用于动态配置场景）
    final props = {
      'cityName': 'Beijing',
      'weatherDescription': 'Sunny',
      'currentTemp': 25.0,
      'lowTemp': 15.0,
      'temperatureHistory': [0.60, 0.70, 0.75, 0.65, 0.55, 0.50, 0.45, 0.50, 0.55, 0.60],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('天气预报卡片（fromProps）')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: WeatherForecastCard.fromProps(props, HomeWidgetSize.small),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: WeatherForecastCard.fromProps(props, HomeWidgetSize.medium),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: WeatherForecastCard.fromProps(props, HomeWidgetSize.large),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}

