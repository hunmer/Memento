import 'package:Memento/widgets/common/index.dart';
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
        child: const Center(
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
          ),
        ),
      ),
    );
  }
}
