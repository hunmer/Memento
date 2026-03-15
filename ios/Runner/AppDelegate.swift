import Flutter
import UIKit
import flutter_foreground_task
import UserNotifications
import intelligence
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var timerMethodChannel: FlutterMethodChannel?
  static var shortcutMethodChannel: FlutterMethodChannel?
  private var widgetMethodChannel: FlutterMethodChannel?

  // 保存初始的 iOS 小组件 URL（用于冷启动）
  private var initialIOSWidgetURL: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 检查是否通过 URL scheme 启动（冷启动情况）
    if let url = launchOptions?[.url] as? URL {
      if url.scheme == "memento" && url.host?.hasPrefix("ios_widget_config") == true {
        print("[AppDelegate] 冷启动时检测到 iOS 小组件点击: \(url.absoluteString)")
        initialIOSWidgetURL = url.absoluteString
      }
    }

    // Register plugins with the callback
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)

    // 设置timer服务的MethodChannel
    setupTimerServiceChannel()

    // 设置 Shortcut 调用的 MethodChannel
    setupShortcutMethodChannel()

    // 设置 Widget 点击的 MethodChannel
    setupWidgetMethodChannel()

    // 设置 Intelligence 插件监听器
    setupIntelligencePlugin()

    // 清理旧的临时文件
    cleanupOldTempFiles()

    // 设置 WatchConnectivity
    setupWatchConnectivity()

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

  /// 设置 Widget 点击的 MethodChannel
  private func setupWidgetMethodChannel() {
    let controller = window?.rootViewController as? FlutterViewController
    widgetMethodChannel = FlutterMethodChannel(
      name: "github.hunmer.memento/widget_click",
      binaryMessenger: controller!.binaryMessenger
    )

    // 处理 Flutter 端的查询请求
    widgetMethodChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getInitialIOSWidgetURL":
        // 返回初始的 iOS 小组件 URL（冷启动时保存的）
        result(self?.initialIOSWidgetURL)
        // 返回后清除，避免重复处理
        self?.initialIOSWidgetURL = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    print("[AppDelegate] Widget MethodChannel 已配置")
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

  // MARK: - URL Scheme Handling

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("[AppDelegate] 收到 URL: \(url.absoluteString)")
    print("[AppDelegate] URL scheme: \(url.scheme ?? "nil")")
    print("[AppDelegate] URL host: \(url.host ?? "nil")")
    print("[AppDelegate] URL path: \(url.path)")

    // 处理 iOS 原生小组件的点击事件
    // URL 格式: memento://ios_widget_config_{widgetKind}
    if url.scheme == "memento" && url.host?.hasPrefix("ios_widget_config") == true {
      print("[AppDelegate] 检测到 iOS 小组件点击: \(url.absoluteString)")

      // 直接通过 MethodChannel 发送给 Flutter
      widgetMethodChannel?.invokeMethod("onIOSWidgetClicked", arguments: url.absoluteString)

      return true
    }

    // 让 Flutter 处理其他 URL
    // super.application 会将 URL 传递给 Flutter 插件（包括 home_widget）
    return super.application(app, open: url, options: options)
  }

  // MARK: - WatchConnectivity

  private func setupWatchConnectivity() {
    // 确保 WCSession 已激活
    if WCSession.isSupported() {
      WCSession.default.delegate = WCSessionManager.shared
      WCSession.default.activate()

      // 设置 MethodChannel
      if let controller = window?.rootViewController as? FlutterViewController {
        WCSessionManager.shared.setupMethodChannel(controller)
      }

      print("[AppDelegate] WatchConnectivity 已初始化")
    } else {
      print("[AppDelegate] 当前设备不支持 WatchConnectivity")
    }
  }
}
