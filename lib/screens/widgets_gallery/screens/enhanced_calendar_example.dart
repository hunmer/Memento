import 'package:flutter/material.dart';
import 'package:Memento/widgets/enhanced_calendar/enhanced_calendar.dart';

/// 增强日历示例
class EnhancedCalendarExample extends StatefulWidget {
  const EnhancedCalendarExample({super.key});

  @override
  State<EnhancedCalendarExample> createState() => _EnhancedCalendarExampleState();
}

class _EnhancedCalendarExampleState extends State<EnhancedCalendarExample> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Map<DateTime, CalendarDayData> _dayData = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _generateSampleData();
  }

  /// 生成示例数据
  void _generateSampleData() {
    final now = DateTime.now();

    // 为本月添加一些示例数据
    for (int i = 1; i <= 15; i++) {
      final date = DateTime(now.year, now.month, i);
      final count = (i % 3) + 1;

      // 每5天添加一个背景图片（示例路径）
      final String? backgroundImage = i % 5 == 0
          ? 'app_data/images/sample_$i.jpg'
          : null;

      _dayData[DateTime(date.year, date.month, date.day)] = CalendarDayData(
        date: date,
        backgroundImage: backgroundImage,
        count: count,
        isToday: _isSameDay(date, now),
        isCurrentMonth: date.month == now.month,
      );
    }

    // 为上个月和下个月也添加一些数据
    for (int i = 25; i <= 30; i++) {
      final date = DateTime(now.year, now.month - 1, i);
      _dayData[DateTime(date.year, date.month, date.day)] = CalendarDayData(
        date: date,
        count: 1,
        isCurrentMonth: false,
      );
    }

    for (int i = 1; i <= 5; i++) {
      final date = DateTime(now.year, now.month + 1, i);
      _dayData[DateTime(date.year, date.month, date.day)] = CalendarDayData(
        date: date,
        count: i % 2 + 1,
        isCurrentMonth: false,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDay = date;
    });
    _showDayDetails(date);
  }

  void _showDayDetails(DateTime date) {
    final dayKey = DateTime(date.year, date.month, date.day);
    final dayData = _dayData[dayKey];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.year}年${date.month}月${date.day}日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSameDay(date, DateTime.now()))
              const Text('今天是当前日期', style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 8),
            Text('事件数量: ${dayData?.count ?? 0}'),
            if (dayData?.backgroundImage != null) ...[
              const SizedBox(height: 8),
              const Text('有背景图片'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强日历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '回到今天',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = null;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 组件标题区
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'EnhancedCalendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 日历组件
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 日历卡片
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: EnhancedCalendarWidget(
                          dayData: _dayData,
                          focusedMonth: _focusedDay,
                          selectedDate: _selectedDay,
                          onDaySelected: _onDaySelected,
                          enableDateSelection: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 功能说明
                    _buildFeatureList(context),

                    const SizedBox(height: 24),

                    // 当前选择信息
                    if (_selectedDay != null) _buildSelectedInfo(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能特性',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          context,
          Icons.image,
          '背景图片支持',
          '可为特定日期设置自定义背景图片',
        ),
        _buildFeatureItem(
          context,
          Icons.notifications,
          '事件数量标记',
          '显示每天的事件数量，99+自动省略',
        ),
        _buildFeatureItem(
          context,
          Icons.touch_app,
          '日期选择',
          '点击选择日期，长按触发更多操作',
        ),
        _buildFeatureItem(
          context,
          Icons.today,
          '今天高亮',
          '当前日期自动高亮显示',
        ),
        _buildFeatureItem(
          context,
          Icons.palette,
          '自定义样式',
          '支持自定义文字、边框、背景等样式',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedInfo(BuildContext context) {
    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayData = _dayData[dayKey];

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '已选择: ${_selectedDay!.year}年${_selectedDay!.month}月${_selectedDay!.day}日',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (dayData?.count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dayData!.count} 事件',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
