import 'package:Memento/widgets/common/index.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:flutter/material.dart';

/// 运输追踪路线卡片示例
class RouteTrackingCardExample extends StatelessWidget {
  const RouteTrackingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('运输追踪路线卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
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
                    width: 280,
                    height: 150,
                    child: RouteTrackingCardWidget(
                      date: 'Wed, 8 Aug',
                      origin: RoutePoint(
                        city: 'Stuttgart',
                        date: 'Mon, 8 Aug',
                        isCompleted: true,
                      ),
                      destination: RoutePoint(
                        city: 'Dubai',
                        date: 'Tue, 9 Aug',
                        isCompleted: true,
                      ),
                      status: 'Shipped',
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 180,
                    child: RouteTrackingCardWidget(
                      date: 'Wed, 8 Aug',
                      origin: RoutePoint(
                        city: 'Stuttgart',
                        date: 'Mon, 8 Aug',
                        isCompleted: true,
                      ),
                      destination: RoutePoint(
                        city: 'Dubai',
                        date: 'Tue, 9 Aug',
                        isCompleted: true,
                      ),
                      status: 'Shipped',
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 220,
                    child: RouteTrackingCardWidget(
                      date: 'Wed, 8 Aug',
                      origin: RoutePoint(
                        city: 'Stuttgart',
                        date: 'Mon, 8 Aug',
                        isCompleted: true,
                      ),
                      destination: RoutePoint(
                        city: 'Dubai',
                        date: 'Tue, 9 Aug',
                        isCompleted: true,
                      ),
                      status: 'Shipped',
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: RouteTrackingCardWidget(
                    date: 'Wed, 8 Aug',
                    origin: RoutePoint(
                      city: 'Stuttgart, Germany',
                      date: 'Mon, 8 Aug',
                      isCompleted: true,
                    ),
                    destination: RoutePoint(
                      city: 'Dubai, UAE',
                      date: 'Tue, 9 Aug',
                      isCompleted: true,
                    ),
                    status: 'Shipped - In Transit',
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RouteTrackingCardWidget(
                    date: 'Wed, 8 Aug - Sat, 12 Aug',
                    origin: RoutePoint(
                      city: 'Stuttgart, Germany - Warehouse A',
                      date: 'Mon, 8 Aug - 09:30',
                      isCompleted: true,
                    ),
                    destination: RoutePoint(
                      city: 'Dubai, UAE - Distribution Center',
                      date: 'Tue, 9 Aug - 14:00',
                      isCompleted: true,
                    ),
                    status: 'Shipped - Delivered Successfully',
                    size: const Wide2Size(),
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
