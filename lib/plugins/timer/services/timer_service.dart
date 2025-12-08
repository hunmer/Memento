import 'package:flutter/services.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';

class TimerService {
  static const MethodChannel _channel = MethodChannel(
    'github.hunmer.memento/timer_service',
  );

  // 启动前台通知服务
  static Future<void> startNotificationService(TimerTask task) async {
    try {
      await _channel.invokeMethod('startTimerService', {
        'taskId': task.id,
        'taskName': task.name,
        'subTimers':
            task.timerItems
                .map(
                  (st) => {
                    'name': st.name,
                    'current': st.completedDuration.inSeconds,
                    'duration': st.duration.inSeconds,
                    'completed': st.isCompleted,
                  },
                )
                .toList(),
        'currentSubTimerIndex': task.getCurrentIndex(),
      });
    } catch (e) {
      print('Error starting notification service: $e');
    }
  }

  // 更新前台通知
  static Future<void> updateNotification(TimerTask task) async {
    try {
      await _channel.invokeMethod('updateTimerService', {
        'taskId': task.id,
        'taskName': task.name,
        'subTimers':
            task.timerItems
                .map(
                  (st) => {
                    'name': st.name,
                    'current': st.completedDuration.inSeconds,
                    'duration': st.duration.inSeconds,
                    'completed': st.isCompleted,
                  },
                )
                .toList(),
        'currentSubTimerIndex': task.getCurrentIndex(),
      });
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  // 停止前台通知服务
  static Future<void> stopNotificationService([String? taskId]) async {
    try {
      await _channel.invokeMethod('stopTimerService', {'taskId': taskId ?? ''});
    } catch (e) {
      print('Error stopping notification service: $e');
    }
  }
}
