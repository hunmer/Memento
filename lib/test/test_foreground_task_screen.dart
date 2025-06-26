import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../core/services/foreground_task_manager.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
  }

  // Called based on the eventAction set in ForegroundTaskOptions.
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Send data to main isolate.
    final Map<String, dynamic> data = {
      "timestampMillis": timestamp.millisecondsSinceEpoch,
    };
    FlutterForegroundTask.sendDataToMain(data);
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('onDestroy(isTimeout: $isTimeout)');
  }

  // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself is pressed.
  @override
  void onNotificationPressed() {
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

class TestForegroundTaskScreen extends StatefulWidget {
  const TestForegroundTaskScreen({super.key});

  @override
  State<TestForegroundTaskScreen> createState() =>
      _TestForegroundTaskScreenState();
}

class _TestForegroundTaskScreenState extends State<TestForegroundTaskScreen> {
  final ForegroundTaskManager _manager = ForegroundTaskManager();
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _manager.addDataCallback(_onReceiveData);
  }

  @override
  void dispose() {
    _manager.removeDataCallback(_onReceiveData);
    super.dispose();
  }

  void _onReceiveData(Object data) {
    debugPrint('Received data: $data');
  }

  Future<void> _toggleService() async {
    if (_isRunning) {
      await _manager.stopService();
    } else {
      await _manager.startService(
        serviceId: 1,
        notificationTitle: 'Test Service 2',
        notificationText: 'Foreground service is running',
        callback: startCallback,
      );
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.testForegroundTask),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Service Status: ${_isRunning ? 'Running' : 'Stopped'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleService,
              child: Text(_isRunning ? 'Stop Service' : 'Start Service'),
            ),
          ],
        ),
      ),
    );
  }
}
