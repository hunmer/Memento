import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/diary/l10n/diary_localizations.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/storage_manager.dart';
import 'diary_editor_screen.dart';
import '../models/diary_entry.dart';
import '../utils/diary_utils.dart';

class DiaryCalendarScreen extends StatefulWidget {
  final StorageManager storage;

  const DiaryCalendarScreen({super.key, required this.storage});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, DiaryEntry> _diaryEntries = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Colors from design
  static const Color _primaryColor = Color(0xFFD8BFD8); // Dusty Rose
  static const Color _primaryTextColor = Color(0xFF4A4A4A); // Soft charcoal
  static const Color _backgroundColor = Color(0xFFFAF8F5); // Light cream

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    final entries = await DiaryUtils.loadDiaryEntries();
    if (mounted) {
      setState(() {
        _diaryEntries = entries;
      });
    }
  }

  void _onDayClicked(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    // 直接打开编辑器
    _navigateToEditor();
  }

  void _navigateToEditor() {
    if (_selectedDay == null) return;

    // Standardize today's date
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Standardize selected date
    final normalizedSelectedDay = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    // Check if selected date is in the future
    if (normalizedSelectedDay.isAfter(normalizedToday)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DiaryLocalizations.of(context).cannotSelectFutureDate),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => DiaryEditorScreen(
                  date: normalizedSelectedDay,
                  storage: widget.storage,
                  initialTitle:
                      _diaryEntries[normalizedSelectedDay]?.title ?? '',
                  initialContent:
                      _diaryEntries[normalizedSelectedDay]?.content ?? '',
                ),
          ),
        )
        .then((_) => _loadDiaryEntries());
  }

  List<String> _extractImagesFromContent(String content) {
    // Simple regex to find markdown images ![alt](url)
    final regex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEntry =
        _selectedDay != null ? _diaryEntries[_selectedDay] : null;
    
    // Check if current theme is dark
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : _backgroundColor;
    final textColor = isDark ? Colors.white : _primaryTextColor;
    final primaryColor = isDark ? Theme.of(context).colorScheme.primary : _primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => PluginManager.toHomeScreen(context),
                  tooltip: DiaryLocalizations.of(context).myDiary,
                ),
              ),
            ),
            // Month Selector
            MonthSelector(
              selectedMonth: _focusedDay,
              onMonthSelected: (month) {
                setState(() {
                  _focusedDay = DateTime(month.year, month.month, _focusedDay.day);
                });
              },
              getMonthStats: (month) {
                // For diary plugin, we'll show entry count instead of financial stats
                final monthEntries = _diaryEntries.entries.where((entry) {
                  return entry.key.year == month.year && entry.key.month == month.month;
                }).toList();

                final entryCount = monthEntries.length;
                final totalWords = monthEntries.fold(0, (sum, entry) => sum + entry.value.content.length);

                return {
                  'income': entryCount.toDouble(), // Use income for entry count
                  'expense': totalWords.toDouble(), // Use expense for word count
                };
              },
              primaryColor: primaryColor,
            ),

            // Calendar
            TableCalendar<DiaryEntry>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDayClicked,
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                if (_diaryEntries.containsKey(normalizedDay)) {
                  return [_diaryEntries[normalizedDay]!];
                }
                return [];
              },
              rowHeight: 70, // Matches h-16 (approx 64px) + gap
              daysOfWeekHeight: 40,
              headerVisible: false, // We use custom header
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                weekendStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0], // S M T ...
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(4),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                defaultDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                weekendDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              calendarBuilders: CalendarBuilders<DiaryEntry>(
                defaultBuilder: (context, day, focusedDay) {
                   return _buildCalendarCell(day, textColor, null, isDark);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, textColor, primaryColor, isDark, isToday: true);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, textColor, primaryColor, isDark, isSelected: true);
                },
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  final entry = events.first;
                  return Positioned(
                    top: 4,
                    right: 4,
                    child: entry.mood != null
                        ? Text(entry.mood!, style: const TextStyle(fontSize: 14))
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Selected Day Details
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedDay != null) ...[
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDay!),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedEntry != null) ...[
                        // Images list (if any)
                         Builder(
                           builder: (context) {
                             final images = _extractImagesFromContent(selectedEntry.content);
                             if (images.isEmpty) return const SizedBox.shrink();
                             return Container(
                               height: 100,
                               margin: const EdgeInsets.only(bottom: 12),
                               child: ListView.builder(
                                 scrollDirection: Axis.horizontal,
                                 itemCount: images.length,
                                 itemBuilder: (context, index) {
                                   return Container(
                                     width: 100,
                                     margin: const EdgeInsets.only(right: 8),
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(8),
                                       image: DecorationImage(
                                         image: NetworkImage(images[index]), // Or FileImage if local
                                         fit: BoxFit.cover,
                                       ),
                                     ),
                                   );
                                 },
                               ),
                             );
                           }
                         ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              selectedEntry.content.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), ''), // Remove images from text preview
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Text(
                              DiaryLocalizations.of(context).noDiaryForDate,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditor,
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, Color textColor, Color? borderColor, bool isDark, {bool isToday = false, bool isSelected = false}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final entry = _diaryEntries[normalizedDay];
    
    // Simulate random-ish background for demo matching the design's visual interest
    // In a real app, maybe we use a specific color or pattern based on mood/content
    final hasEntry = entry != null;
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: (isSelected || isToday) ? Border.all(color: borderColor ?? Colors.transparent, width: 2) : null,
        color: hasEntry ? (isDark ? Colors.white10 : Colors.grey.shade100) : Colors.transparent,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (entry?.mood != null)
            Positioned(
              top: 2,
              right: 2,
              child: Text(entry!.mood!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
