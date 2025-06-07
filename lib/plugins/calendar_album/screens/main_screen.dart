import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import 'calendar_screen.dart';
import 'tag_screen.dart';
import 'album_screen.dart';
import '../../../core/storage/storage_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late CalendarController _calendarController;
  late TagController tagController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _calendarController = CalendarController();
    tagController = TagController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarController.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          CalendarScreen(
            calendarController: _calendarController,
            tagController: tagController,
          ),
          TagScreen(),
          AlbumScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: l10n.get('calendar'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tag),
            label: l10n.get('tags'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_library),
            label: l10n.get('album'),
          ),
        ],
      ),
    );
  }
}
