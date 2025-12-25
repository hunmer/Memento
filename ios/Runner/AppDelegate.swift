import Flutter
import UIKit
import flutter_foreground_task
import UserNotifications
import intelligence

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var timerMethodChannel: FlutterMethodChannel?
  static var shortcutMethodChannel: FlutterMethodChannel?

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

    // 设置 Shortcut 调用的 MethodChannel
    setupShortcutMethodChannel()

    // 设置 Intelligence 插件监听器
    setupIntelligencePlugin()

    // 清理旧的临时文件
    cleanupOldTempFiles()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 设置 Intelligence 插件
  private func setupIntelligencePlugin() {
    IntelligencePlugin.storage.attachListener {
      // 当频道列表更新时，刷新 Shortcuts 参数
      // 可以在这里添加刷新逻辑
      print("[AppDelegate] 频道列表已更新")
    }

    print("[AppDelegate] Intelligence 插件已配置")
  }

  /// 清理旧的临时文件（24小时前的文件）
  private func cleanupOldTempFiles() {
    let tempDir = FileManager.default.temporaryDirectory
    guard let files = try? FileManager.default.contentsOfDirectory(
      at: tempDir,
      includingPropertiesForKeys: [.creationDateKey]
    ) else {
      return
    }

    let now = Date()
    let oneDayAgo = now.addingTimeInterval(-86400) // 24小时 = 86400秒

    var cleanedCount = 0
    for fileURL in files {
      // 只清理 Shortcuts 图片临时文件
      if fileURL.lastPathComponent.hasPrefix("shortcut_image_") {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let creationDate = attrs[.creationDate] as? Date {
          // 删除 24 小时前的文件
          if creationDate < oneDayAgo {
            try? FileManager.default.removeItem(at: fileURL)
            cleanedCount += 1
          }
        }
      }
    }

    if cleanedCount > 0 {
      print("[AppDelegate] 已清理 \(cleanedCount) 个旧临时文件")
    }
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

  private func setupShortcutMethodChannel() {
    let controller = window?.rootViewController as? FlutterViewController
    AppDelegate.shortcutMethodChannel = FlutterMethodChannel(
      name: "github.hunmer.memento/shortcut_plugin_call",
      binaryMessenger: controller!.binaryMessenger
    )

    // 设置方法处理器（用于写入共享文件）
    AppDelegate.shortcutMethodChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "writeShortcutResult":
        self.handleWriteShortcutResult(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    print("[AppDelegate] Shortcut MethodChannel 已配置")
  }

  private func handleWriteShortcutResult(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let callId = args["callId"] as? String,
          let resultData = args["result"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "缺少必要参数", details: nil))
      return
    }

    // 写入共享文件
    if let fileURL = ShortcutResultStorage.shared.resultFileURL(for: callId) {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        try jsonData.write(to: fileURL)
        print("[AppDelegate] 已写入 Shortcut 结果: \(callId)")
        result(true)
      } catch {
        print("[AppDelegate] 写入失败: \(error)")
        result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
      }
    } else {
      result(FlutterError(code: "PATH_ERROR", message: "无法获取共享文件路径", details: nil))
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
