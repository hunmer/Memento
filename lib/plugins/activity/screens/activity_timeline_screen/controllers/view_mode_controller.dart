import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';

enum ViewMode {
  timeline,
  grid,
}

class ViewModeController extends ChangeNotifier {
  final plugin = ActivityPlugin.instance;
  ViewMode _currentMode;
  int _selectedMinutes = 0;

  ViewModeController() : _currentMode = ViewMode.timeline {
    _loadViewMode();
  }

  bool get isGridMode => _currentMode == ViewMode.grid;
  int get selectedMinutes => _selectedMinutes;

  Future<void> _loadViewMode() async {
    try {
      final savedMode = plugin.settings['view_mode'];
      if (savedMode != null) {
        _currentMode = ViewMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => ViewMode.timeline,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载视图模式失败: $e');
    }
  }

  Future<void> _saveViewMode() async {
    try {
      await plugin.updateSettings({'view_mode': _currentMode.toString()});
    } catch (e) {
      debugPrint('保存视图模式失败: $e');
    }
  }

  void toggleViewMode() {
    _currentMode = isGridMode ? ViewMode.timeline : ViewMode.grid;
    _saveViewMode();
    notifyListeners();
  }

  void updateSelectedMinutes(int minutes) {
    _selectedMinutes = minutes;
    notifyListeners();
  }

  void clearSelectedMinutes() {
    _selectedMinutes = 0;
    notifyListeners();
  }
}