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

        // 生成唯一调用ID
        let callId = "\(Date().timeIntervalSince1970)_\(Int.random(in: 10000...99999))"

        // 构造发送到 Flutter 的数据
        var data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": pluginId,
            "methodName": methodName,
            "callId": callId,  // 添加调用ID
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
                throw IntentError.message("参数 JSON 解析失败: \(error.localizedDescription)")
            }
        }

        // 写入"等待中"状态到共享文件
        ShortcutResultStorage.shared.writePendingStatus(callId: callId)

        // 通过 intelligence 插件推送消息到 Flutter
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CallPluginMethod] 已发送数据到 Flutter: \(jsonString)")
        } else {
            throw IntentError.message("数据序列化失败")
        }

        // 轮询读取结果（超时 30 秒）
        print("[CallPluginMethod] 开始轮询结果，callId: \(callId)")
        if let result = await ShortcutResultStorage.shared.pollResult(callId: callId, timeout: 30.0) {
            print("[CallPluginMethod] 读取到结果: \(result)")

            let success = result["success"] as? Bool ?? false

            if success {
                // 成功：格式化返回数据
                let data = result["data"]
                let resultMessage = formatResult(pluginId: pluginId, methodName: methodName, data: data)
                return .result(value: resultMessage)
            } else {
                // 失败：返回错误信息
                let error = result["error"] as? String ?? "未知错误"
                throw IntentError.message("执行失败: \(error)")
            }
        } else {
            // 超时
            throw IntentError.message("执行超时，请确保应用已打开并正常运行")
        }
    }

    /// 格式化返回结果
    ///
    /// 注意：为了让 Shortcuts 能够将结果作为 JSON 使用（例如提取字段），
    /// 我们需要返回 JSON 字符串而不是格式化的文本。
    /// Shortcuts 会自动识别 JSON 字符串并将其解析为字典/数组。
    private func formatResult(pluginId: String, methodName: String, data: Any?) -> String {
        guard let data = data else {
            // 无数据，返回成功消息的 JSON
            return "{\"success\":true,\"message\":\"\\(pluginId).\\(methodName) 执行成功\"}"
        }

        // 将数据转换为 JSON 字符串（紧凑格式，不带换行）
        // Shortcuts 会自动解析此 JSON 字符串
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        // 如果无法转换为 JSON，返回字符串值的 JSON
        return "{\"success\":true,\"value\":\"\(String(describing: data).replacingOccurrences(of: "\"", with: "\\\""))\"}"
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
