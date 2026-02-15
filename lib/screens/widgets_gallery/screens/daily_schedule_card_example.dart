import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_schedule_card.dart';

/// 每日日程卡片示例
class DailyScheduleCardExample extends StatelessWidget {
  const DailyScheduleCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日日程卡片')),
      body: Container(
        color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFFF2F2F7),
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
                    height: 180,
                    child: DailyScheduleCardWidget(
                      size: const SmallSize(),
                      todayDate: 'Monday, June 7',
                      todayEvents: const [
                        EventData(
                          title: 'Farmers Market',
                          startTime: '9:45',
                          startPeriod: 'am',
                          endTime: '11:00',
                          endPeriod: 'am',
                          color: EventColor.orange,
                          location: null,
                        ),
                      ],
                      tomorrowEvents: const [],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 250,
                    child: DailyScheduleCardWidget(
                      size: const MediumSize(),
                      todayDate: 'Monday, June 7',
                      todayEvents: const [
                        EventData(
                          title: 'Farmers Market',
                          startTime: '9:45',
                          startPeriod: 'am',
                          endTime: '11:00',
                          endPeriod: 'am',
                          color: EventColor.orange,
                          location: null,
                        ),
                        EventData(
                          title: 'Weekly Prep',
                          startTime: '11:15',
                          startPeriod: 'am',
                          endTime: '1:00',
                          endPeriod: 'pm',
                          color: EventColor.green,
                          location: null,
                        ),
                      ],
                      tomorrowEvents: const [],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 250,
                  child: DailyScheduleCardWidget(
                    size: const WideSize(),
                    todayDate: 'Monday, June 7',
                    todayEvents: const [
                      EventData(
                        title: 'Farmers Market',
                        startTime: '9:45',
                        startPeriod: 'am',
                        endTime: '11:00',
                        endPeriod: 'am',
                        color: EventColor.orange,
                        location: null,
                      ),
                      EventData(
                        title: 'Weekly Prep',
                        startTime: '11:15',
                        startPeriod: 'am',
                        endTime: '1:00',
                        endPeriod: 'pm',
                        color: EventColor.green,
                        location: null,
                      ),
                      EventData(
                        title: 'Product Sprint',
                        startTime: '2:00',
                        startPeriod: 'pm',
                        endTime: '3:00',
                        endPeriod: 'pm',
                        color: EventColor.blue,
                        location: null,
                      ),
                    ],
                    tomorrowEvents: const [],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 350,
                    child: DailyScheduleCardWidget(
                      size: const LargeSize(),
                      todayDate: 'Monday, June 7',
                      todayEvents: const [
                        EventData(
                          title: 'Farmers Market',
                          startTime: '9:45',
                          startPeriod: 'am',
                          endTime: '11:00',
                          endPeriod: 'am',
                          color: EventColor.orange,
                          location: null,
                        ),
                        EventData(
                          title: 'Weekly Prep',
                          startTime: '11:15',
                          startPeriod: 'am',
                          endTime: '1:00',
                          endPeriod: 'pm',
                          color: EventColor.green,
                          location: null,
                        ),
                        EventData(
                          title: 'Product Sprint',
                          startTime: '1:00',
                          startPeriod: 'pm',
                          endTime: '2:15',
                          endPeriod: 'pm',
                          color: EventColor.green,
                          location: null,
                        ),
                      ],
                      tomorrowEvents: const [
                        EventData(
                          title: "Ravi's Birthday",
                          startTime: '',
                          startPeriod: '',
                          endTime: '',
                          endPeriod: '',
                          color: EventColor.gray,
                          location: null,
                          isAllDay: true,
                          icon: Icons.card_giftcard,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: DailyScheduleCardWidget(
                    size: const Wide2Size(),
                    todayDate: 'Monday, June 7',
                    todayEvents: const [
                      EventData(
                        title: 'Farmers Market',
                        startTime: '9:45',
                        startPeriod: 'am',
                        endTime: '11:00',
                        endPeriod: 'am',
                        color: EventColor.orange,
                        location: null,
                      ),
                      EventData(
                        title: 'Weekly Prep',
                        startTime: '11:15',
                        startPeriod: 'am',
                        endTime: '1:00',
                        endPeriod: 'pm',
                        color: EventColor.green,
                        location: null,
                      ),
                      EventData(
                        title: 'Product Sprint',
                        startTime: '1:00',
                        startPeriod: 'pm',
                        endTime: '2:15',
                        endPeriod: 'pm',
                        color: EventColor.green,
                        location: null,
                      ),
                      EventData(
                        title: 'Team Review',
                        startTime: '3:30',
                        startPeriod: 'pm',
                        endTime: '4:30',
                        endPeriod: 'pm',
                        color: EventColor.blue,
                        location: null,
                      ),
                    ],
                    tomorrowEvents: const [
                      EventData(
                        title: "Ravi's Birthday",
                        startTime: '',
                        startPeriod: '',
                        endTime: '',
                        endPeriod: '',
                        color: EventColor.gray,
                        location: null,
                        isAllDay: true,
                        icon: Icons.card_giftcard,
                      ),
                      EventData(
                        title: 'Doctor Appointment',
                        startTime: '10:00',
                        startPeriod: 'am',
                        endTime: '11:00',
                        endPeriod: 'am',
                        color: EventColor.red,
                        location: null,
                      ),
                    ],
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
