import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 圆角任务列表卡片示例
class RoundedTaskListCardExample extends StatelessWidget {
  const RoundedTaskListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角任务列表卡片')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFE5E5E5),
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
                    child: RoundedTaskListCard(
                      size: const SmallSize(),
                      tasks: [
                        TaskListItem(
                          title: 'Design mobile UI',
                          subtitle: 'Widgefy UI kit',
                          date: '12 Jan 2021',
                        ),
                        TaskListItem(
                          title: 'Calculate budget',
                          subtitle: 'BetaCRM',
                          date: '1 Feb 2021',
                        ),
                      ],
                      headerText: 'Upcoming',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: RoundedTaskListCard(
                      size: const MediumSize(),
                      tasks: [
                        TaskListItem(
                          title: 'Design mobile UI',
                          subtitle: 'Widgefy UI kit',
                          date: '12 Jan 2021',
                        ),
                        TaskListItem(
                          title: 'Calculate budget',
                          subtitle: 'BetaCRM',
                          date: '1 Feb 2021',
                        ),
                        TaskListItem(
                          title: 'Search for a UI kit',
                          subtitle: 'Cardify landing pack',
                          date: '9 Mar 2021',
                        ),
                      ],
                      headerText: 'Upcoming',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 280,
                    child: RoundedTaskListCard(
                      size: const LargeSize(),
                      tasks: [
                        TaskListItem(
                          title: 'Design mobile UI dashboard',
                          subtitle: 'Widgefy UI kit',
                          date: '12 Jan 2021',
                        ),
                        TaskListItem(
                          title: 'Calculate budget and contract',
                          subtitle: 'BetaCRM',
                          date: '1 Feb 2021',
                        ),
                        TaskListItem(
                          title: 'Search for a UI kit',
                          subtitle: 'Cardify landing pack',
                          date: '9 Mar 2021',
                        ),
                        TaskListItem(
                          title: 'Design search page for website',
                          subtitle: 'IOTask UI kit',
                          date: '10 Feb 2021',
                        ),
                        TaskListItem(
                          title: 'Create HTML & CSS for startup',
                          subtitle: 'Roomsfy',
                          date: '21 Feb 2021',
                        ),
                      ],
                      headerText: 'Upcoming',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RoundedTaskListCard(
                    size: const WideSize(),
                    tasks: [
                      TaskListItem(
                        title: 'Design mobile UI dashboard',
                        subtitle: 'Widgefy UI kit - Mobile Application',
                        date: '12 Jan 2021',
                      ),
                      TaskListItem(
                        title: 'Calculate budget and contract',
                        subtitle: 'BetaCRM - Client Management',
                        date: '1 Feb 2021',
                      ),
                      TaskListItem(
                        title: 'Search for a UI kit',
                        subtitle: 'Cardify landing pack - Design Resources',
                        date: '9 Mar 2021',
                      ),
                      TaskListItem(
                        title: 'Design search page for website',
                        subtitle: 'IOTask UI kit - Web Development',
                        date: '10 Feb 2021',
                      ),
                    ],
                    headerText: 'Upcoming Tasks',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: RoundedTaskListCard(
                    size: const Wide2Size(),
                    tasks: [
                      TaskListItem(
                        title: 'Design mobile UI dashboard',
                        subtitle: 'Widgefy UI kit - Mobile Application Design',
                        date: '12 Jan 2021',
                      ),
                      TaskListItem(
                        title: 'Calculate budget and contract',
                        subtitle: 'BetaCRM - Client Management System',
                        date: '1 Feb 2021',
                      ),
                      TaskListItem(
                        title: 'Search for a UI kit',
                        subtitle: 'Cardify landing pack - Design Resources',
                        date: '9 Mar 2021',
                      ),
                      TaskListItem(
                        title: 'Design search page for website',
                        subtitle: 'IOTask UI kit - Web Development',
                        date: '10 Feb 2021',
                      ),
                      TaskListItem(
                        title: 'Create HTML & CSS for startup',
                        subtitle: 'Roomsfy - Web Development Project',
                        date: '21 Feb 2021',
                      ),
                      TaskListItem(
                        title: 'Review project documentation',
                        subtitle: 'Internal - Project Management',
                        date: '25 Feb 2021',
                      ),
                    ],
                    headerText: 'Upcoming Tasks Overview',
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
