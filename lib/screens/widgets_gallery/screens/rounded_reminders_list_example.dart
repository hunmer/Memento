import 'package:Memento/widgets/common/index.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 圆角提醒事项列表卡片示例
class RoundedRemindersListExample extends StatefulWidget {
  const RoundedRemindersListExample({super.key});

  @override
  State<RoundedRemindersListExample> createState() =>
      _RoundedRemindersListExampleState();
}

class _RoundedRemindersListExampleState extends State<RoundedRemindersListExample> {
  final Map<int, List<ReminderItem>> _itemsMap = {};

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    // 小尺寸
    _itemsMap[0] = [
      const ReminderItem(text: 'Pick up supplies'),
      const ReminderItem(text: 'Send recipe', isCompleted: true),
      const ReminderItem(text: 'Book club prep'),
    ];

    // 中尺寸
    _itemsMap[1] = [
      const ReminderItem(text: 'Pick up arts & crafts supplies'),
      const ReminderItem(text: 'Send cookie recipe to Rigo', isCompleted: true),
      const ReminderItem(text: 'Book club prep'),
      const ReminderItem(text: 'Hike with Darla'),
      const ReminderItem(text: 'Schedule maintenance'),
    ];

    // 大尺寸
    _itemsMap[2] = [
      const ReminderItem(text: 'Pick up arts & crafts supplies'),
      const ReminderItem(text: 'Send cookie recipe to Rigo', isCompleted: true),
      const ReminderItem(text: 'Book club prep', isCompleted: true),
      const ReminderItem(text: 'Hike with Darla'),
      const ReminderItem(text: 'Schedule car maintenance'),
      const ReminderItem(text: 'Cancel membership', isCompleted: true),
      const ReminderItem(text: 'Check spare tire'),
    ];

    // 中宽尺寸
    _itemsMap[3] = [
      const ReminderItem(text: 'Pick up arts & crafts supplies'),
      const ReminderItem(text: 'Send cookie recipe to Rigo', isCompleted: true),
      const ReminderItem(text: 'Book club prep'),
      const ReminderItem(text: 'Hike with Darla'),
      const ReminderItem(text: 'Schedule car maintenance'),
      const ReminderItem(text: 'Cancel membership', isCompleted: true),
      const ReminderItem(text: 'Check spare tire'),
      const ReminderItem(text: 'Buy groceries'),
    ];

    // 大宽尺寸
    _itemsMap[4] = [
      const ReminderItem(text: 'Pick up arts & crafts supplies'),
      const ReminderItem(text: 'Send cookie recipe to Rigo', isCompleted: true),
      const ReminderItem(text: 'Book club prep', isCompleted: true),
      const ReminderItem(text: 'Hike with Darla'),
      const ReminderItem(text: 'Schedule car maintenance'),
      const ReminderItem(text: 'Cancel membership', isCompleted: true),
      const ReminderItem(text: 'Check spare tire'),
      const ReminderItem(text: 'Buy groceries'),
      const ReminderItem(text: 'Call dentist', isCompleted: true),
      const ReminderItem(text: 'Pay bills'),
      const ReminderItem(text: 'Update resume'),
      const ReminderItem(text: 'Read book'),
      const ReminderItem(text: 'Workout'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角提醒事项列表卡片')),
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
                    height: 200,
                    child: ReminderListCard(
                      size: const SmallSize(),
                      itemCount: _itemsMap[0]!.length,
                      items: _itemsMap[0]!,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 280,
                    child: ReminderListCard(
                      size: const MediumSize(),
                      itemCount: _itemsMap[1]!.length,
                      items: _itemsMap[1]!,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 380,
                    child: ReminderListCard(
                      size: const LargeSize(),
                      itemCount: _itemsMap[2]!.length,
                      items: _itemsMap[2]!,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: ReminderListCard(
                    size: const WideSize(),
                    itemCount: _itemsMap[3]!.length,
                    items: _itemsMap[3]!,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: ReminderListCard(
                    size: const Wide2Size(),
                    itemCount: _itemsMap[4]!.length,
                    items: _itemsMap[4]!,
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
