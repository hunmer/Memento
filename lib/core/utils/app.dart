import 'package:restart_app/restart_app.dart';

/// 重启应用
Future<void> restartApplication() async {
  Restart.restartApp(
    notificationTitle: 'Restarting App',
    notificationBody: 'Please tap here to open the app again.',
  );
}
