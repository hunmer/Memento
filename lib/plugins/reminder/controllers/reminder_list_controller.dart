import 'package:flutter/material.dart';
import '../services/reminder_service.dart';
import '../models/reminder.dart';

/// 提醒列表控制器
class ReminderListController extends ChangeNotifier {
  final ReminderService _service = ReminderService();

  List<Reminder> get reminders => _service.reminders;

  ReminderListController() {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    await _service.refresh();
    notifyListeners();
  }

  Future<void> refresh() async {
    await _service.refresh();
    notifyListeners();
  }

  Future<void> toggleReminder(String id) async {
    await _service.toggleReminder(id);
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _service.deleteReminder(id);
    notifyListeners();
  }
}
