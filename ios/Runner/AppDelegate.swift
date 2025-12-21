import Flutter
import UIKit
import flutter_foreground_task
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var timerMethodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins with the callback
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)

    // 设置timer服务的MethodChannel
    setupTimerServiceChannel()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupTimerServiceChannel() {
    let controller = window?.rootViewController as? FlutterViewController
    timerMethodChannel = FlutterMethodChannel(
      name: "github.hunmer.memento/timer_service",
      binaryMessenger: controller!.binaryMessenger
    )

    timerMethodChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startMultipleTimerService":
        self?.handleStartTimerService(call: call, result: result)
      case "updateMultipleTimerService":
        self?.handleUpdateTimerService(call: call, result: result)
      case "stopMultipleTimerService":
        self?.handleStopTimerService(call: call, result: result)
      case "updateTimerService":
        // 兼容旧版本API
        self?.handleUpdateTimerService(call: call, result: result)
      case "stopTimerService":
        // 兼容旧版本API
        self?.handleStopTimerService(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleStartTimerService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let timerId = args?["timerId"] as? String ?? ""
    let taskName = args?["taskName"] as? String ?? ""
    let content = args?["content"] as? String ?? ""
    let progress = args?["progress"] as? Int ?? 0
    let maxProgress = args?["maxProgress"] as? Int ?? 100

    print("[TimerService] iOS端暂不支持前台计时器服务: \(taskName)")
    result(nil)
  }

  private func handleUpdateTimerService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let timerId = args?["timerId"] as? String ?? ""
    let content = args?["content"] as? String ?? ""
    let progress = args?["progress"] as? Int ?? 0
    let maxProgress = args?["maxProgress"] as? Int ?? 100

    print("[TimerService] iOS端暂不支持更新计时器服务: timerId=\(timerId), progress=\(progress)/\(maxProgress)")
    result(nil)
  }

  private func handleStopTimerService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let timerId = args?["timerId"] as? String ?? ""

    print("[TimerService] iOS端暂不支持停止计时器服务: timerId=\(timerId)")
    result(nil)
  }

  // MARK: - UNUserNotificationCenterDelegate

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
  }
}
