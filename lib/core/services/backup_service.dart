import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart'
    show FloatingBallLocalizations;
import 'package:Memento/widgets/backup_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/screens/settings_screen/controllers/settings_screen_controller.dart';

class BackupService {
  final SettingsScreenController _controller;
  final BuildContext context;
  late String _subscriptionId;

  BackupService(this._controller, this.context) {
    // 订阅插件初始化完成事件
    _subscriptionId = EventManager.instance.subscribe(
      'plugins_initialized',
      (_) => _checkInitialBackup(),
    );
  }

  Future<void> _checkInitialBackup() async {
    await _controller.initPrefs();
    final shouldBackup = await _controller.shouldPerformBackup();
    if (shouldBackup && context.mounted) {
      // 添加2秒延迟，确保UI完全加载后再显示备份选项
      await Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          showBackupOptionsDialog();
        }
      });
    }
  }

  Future<void> showBackupScheduleDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => BackupTimePicker(
            initialSchedule: _controller.backupSchedule,
            onScheduleSelected: (schedule) {
              _controller.setBackupSchedule(schedule);
              _checkInitialBackup();
            },
          ),
    );
  }

  Future<void> showBackupOptionsDialog() async {
    // 在弹出对话框之前先保存当前备份检查日期
    _controller.resetBackupCheckDate();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              FloatingBallLocalizations.getText(context, 'backupOptions'),
            ),
            content: Text(
              FloatingBallLocalizations.getText(context, 'selectBackupMethod'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'export'),
                child: Text(
                  FloatingBallLocalizations.getText(context, 'exportAppData'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'full'),
                child: Text(
                  FloatingBallLocalizations.getText(context, 'fullBackup'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'webdav'),
                child: Text(
                  FloatingBallLocalizations.getText(context, 'webdavSync'),
                ),
              ),
            ],
          ),
    );

    if (result != null && context.mounted) {
      switch (result) {
        case 'export':
          _controller.exportData();
          break;
        case 'full':
          _controller.exportAllData();
          break;
        case 'webdav':
          _controller.uploadAllToWebDAV();
          break;
      }
    }
  }

  void dispose() {
    EventManager.instance.unsubscribeById(_subscriptionId);
  }
}
