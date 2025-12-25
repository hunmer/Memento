import AppIntents
import intelligence

/// 通用插件方法调用 Intent
///
/// 允许通过 Siri Shortcuts 调用任意插件的 JavaScript API
/// 参数通过 JSON 格式传递，执行结果返回给用户
struct CallPluginMethodIntent: AppIntent {
    static var title: LocalizedStringResource = "调用插件方法"
    static var description: IntentDescription = "调用 Memento 插件的方法（通过 JS Bridge）"
    static var openAppWhenRun: Bool = true

    // 参数1: 插件 ID（必填）
    @Parameter(
        title: "插件ID",
        description: "插件标识符，如: todo, diary, bill",
        requestValueDialog: "请输入插件ID"
    )
    var pluginId: String

    // 参数2: 方法名（必填）
    @Parameter(
        title: "方法名",
        description: "要调用的方法名称，如: createTodo, getDiaryByDate",
        requestValueDialog: "请输入方法名"
    )
    var methodName: String

    // 参数3: JSON 参数（可选）
    @Parameter(
        title: "参数",
        description: "JSON 格式的参数，如: {\"title\":\"买菜\",\"priority\":\"high\"}",
        requestValueDialog: "请输入参数（JSON格式）"
    )
    var paramsJson: String?

    // 参数4: 是否后台执行（可选）
    @Parameter(
        title: "后台执行",
        description: "是否在后台执行（不打开应用）",
        default: false
    )
    var runInBackground: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CallPluginMethod] 开始执行")
        print("[CallPluginMethod] 插件ID: \(pluginId)")
        print("[CallPluginMethod] 方法名: \(methodName)")
        print("[CallPluginMethod] 参数: \(paramsJson ?? "null")")
        print("[CallPluginMethod] 后台执行: \(runInBackground)")

        // 构造发送到 Flutter 的 JSON 数据
        var data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": pluginId,
            "methodName": methodName,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 解析参数 JSON
        if let paramsJson = paramsJson, !paramsJson.isEmpty {
            do {
                if let jsonData = paramsJson.data(using: .utf8),
                   let params = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    data["params"] = params
                    print("[CallPluginMethod] 参数解析成功: \(params)")
                } else {
                    print("[CallPluginMethod] 警告: 参数不是有效的 JSON 对象")
                }
            } catch {
                print("[CallPluginMethod] 参数 JSON 解析失败: \(error)")
                // 继续执行，传递空参数
            }
        }

        // 转换为 JSON 字符串并发送到 Flutter
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // 通过 intelligence 插件通知 Flutter
            IntelligencePlugin.notifier.push(jsonString)
            print("[CallPluginMethod] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let resultMessage = "已调用 \(pluginId).\(methodName)"
            return .result(value: resultMessage)
        } else {
            print("[CallPluginMethod] JSON 序列化失败")
            throw IntentError.message("数据序列化失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("调用 \(\.$pluginId).\(\.$methodName)") {
            \.$paramsJson
            \.$runInBackground
        }
    }
}

/// Intent 错误类型
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case message(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .message(let msg):
            return LocalizedStringResource(stringLiteral: msg)
        }
    }
}
