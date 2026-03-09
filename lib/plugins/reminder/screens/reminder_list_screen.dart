import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import '../models/reminder.dart';
import '../controllers/reminder_list_controller.dart';
import 'components/reminder_card.dart';
import 'components/empty_state.dart';
import 'reminder_form_screen.dart';

/// 提醒列表界面
class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  late ReminderListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReminderListController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _controller.reminders;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
      body: SuperCupertinoNavigationWrapper(
        title: const Text('定时提醒'),
        largeTitle: '定时提醒',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addReminder),
        ],
        body:
            reminders.isEmpty
                ? const EmptyState()
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return ReminderCard(
                      reminder: reminder,
                      onToggle: () => _controller.toggleReminder(reminder.id),
                      onEdit: () => _editReminder(reminder),
                      onDelete: () => _deleteReminder(reminder),
                    );
                  },
                ),
      ),
    );
  }

  Future<void> _addReminder() async {
    final result = await NavigationHelper.push<bool>(
      context,
      const ReminderFormScreen(),
      routeName: '/reminder/form',
    );
    if (result == true) {
      await _controller.refresh();
    }
  }

  Future<void> _editReminder(Reminder reminder) async {
    final result = await NavigationHelper.push<bool>(
      context,
      ReminderFormScreen(existingReminder: reminder),
      routeName: '/reminder/form',
    );
    if (result == true) {
      await _controller.refresh();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除提醒'),
            content: Text('确定要删除提醒"${reminder.title}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _controller.deleteReminder(reminder.id);
    }
  }
}
