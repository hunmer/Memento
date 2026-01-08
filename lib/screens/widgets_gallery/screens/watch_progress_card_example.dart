import 'package:flutter/material.dart';

/// 观看进度卡片示例
class WatchProgressCardExample extends StatelessWidget {
  const WatchProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('观看进度卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        child: const Center(
          child: WatchProgressCardWidget(
            userName: 'James',
            lastWatched: '2 days ago',
            currentCount: 16,
            totalCount: 24,
            items: [
              WatchProgressItem(
                title: 'Dune: Part Two',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
              WatchProgressItem(
                title: 'Oppenheimer',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
              WatchProgressItem(
                title: 'Small Things like It',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 观看项目数据模型
class WatchProgressItem {
  final String title;
  final String thumbnailUrl;

  const WatchProgressItem({
    required this.title,
    required this.thumbnailUrl,
  });
}

/// 观看进度小组件
class WatchProgressCardWidget extends StatefulWidget {
  final String userName;
  final String lastWatched;
  final int currentCount;
  final int totalCount;
  final List<WatchProgressItem> items;

  const WatchProgressCardWidget({
    super.key,
    required this.userName,
    required this.lastWatched,
    required this.currentCount,
    required this.totalCount,
    required this.items,
  });

  @override
  State<WatchProgressCardWidget> createState() => _WatchProgressCardWidgetState();
}

class _WatchProgressCardWidgetState extends State<WatchProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const double _baseEnd = 0.6;

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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final elementCount = widget.items.length + 2; // +2 for header and progress section
    final maxStep = (1.0 - _baseEnd) / (elementCount - 1);
    final step = maxStep * 0.9;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isDark, 0, step),
                  const SizedBox(height: 32),
                  _buildProgressSection(isDark, 1, step),
                  const SizedBox(height: 32),
                  ..._buildItemsList(isDark, step),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.white,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${widget.userName}!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last watched ${widget.lastWatched}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    final progress = widget.currentCount / widget.totalCount;

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.currentCount}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/${widget.totalCount}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Watched Movies',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: progress * itemAnimation.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      topRight: Radius.circular(1),
                      bottomRight: Radius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsList(bool isDark, double step) {
    final List<Widget> items = [];

    for (int i = 0; i < widget.items.length; i++) {
      if (i > 0) {
        items.add(const SizedBox(height: 20));
      }
      items.add(_buildItem(widget.items[i], isDark, i + 2, step));
    }

    return items;
  }

  Widget _buildItem(WatchProgressItem item, bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              child: const Icon(Icons.movie, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
