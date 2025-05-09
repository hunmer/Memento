
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/screens/settings_screen/controllers/settings_screen_controller.dart';

class BackupService {
  final SettingsScreenController _controller;
  late String _subscriptionId;

  BackupService(this._controller) {
    // 订阅插件初始化完成事件
    _subscriptionId = EventManager.instance.subscribe(
      'plugins_initialized',
      (_) => _checkInitialBackup(),
    );
  }

  Future<void> _checkInitialBackup() async {
    final shouldBackup = await _controller.shouldPerformBackup();
    if (shouldBackup) {
      _controller.showBackupOptionsDialog();
    }
  }

  void dispose() {
    EventManager.instance.unsubscribeById(_subscriptionId);
  }
}
