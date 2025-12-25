import AppIntents
import intelligence

/// 快速创建习惯 Intent
///
/// 支持 Siri 快速创建新习惯
struct CreateHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "创建习惯"
    static var description: IntentDescription = "创建一个新的习惯追踪"
    static var openAppWhenRun: Bool = true

    // 参数1: 习惯名称（必填）
    @Parameter(
        title: "习惯名称",
        description: "想要养成的习惯",
        requestValueDialog: "想养成什么习惯?"
    )
    var title: String

    // 参数2: 目标时长（必填）
    @Parameter(
        title: "目标时长",
        description: "每天计划投入的时间（分钟）",
        default: 30
    )
    var durationMinutes: Int

    // 参数3: 备注（可选）
    @Parameter(
        title: "备注",
        description: "习惯的说明或目标"
    )
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateHabit] 开始创建习惯")
        print("[CreateHabit] 名称: \(title)")
        print("[CreateHabit] 目标时长: \(durationMinutes)分钟")
        print("[CreateHabit] 备注: \(notes ?? "无")")

        // 验证时长有效性
        guard durationMinutes > 0 else {
            print("[CreateHabit] 错误: 目标时长必须大于0")
            throw IntentError.message("目标时长必须大于0分钟")
        }

        // 构造参数对象
        var params: [String: Any] = [
            "title": title,
            "durationMinutes": durationMinutes
        ]

        // 添加备注（如果有）
        if let habitNotes = notes, !habitNotes.isEmpty {
            params["notes"] = habitNotes
        }

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "habits",
            "methodName": "createHabit",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateHabit] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let resultMessage = "已创建习惯: \(title) (每天\(durationMinutes)分钟)"
            return .result(value: resultMessage)
        } else {
            print("[CreateHabit] JSON 序列化失败")
            throw IntentError.message("创建习惯失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("创建习惯 \(\.$title)，每天 \(\.$durationMinutes) 分钟") {
            \.$notes
        }
    }
}
