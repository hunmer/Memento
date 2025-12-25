import AppIntents
import intelligence

/// 快速创建活动记录 Intent
///
/// 支持 Siri 快速记录活动
struct CreateActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "记录活动"
    static var description: IntentDescription = "记录一个时间段的活动"
    static var openAppWhenRun: Bool = true

    // 参数1: 活动标题（必填）
    @Parameter(
        title: "活动名称",
        description: "做了什么活动",
        requestValueDialog: "活动名称是什么?"
    )
    var title: String

    // 参数2: 开始时间（必填）
    @Parameter(
        title: "开始时间",
        description: "活动开始的时间"
    )
    var startTime: Date

    // 参数3: 结束时间（必填）
    @Parameter(
        title: "结束时间",
        description: "活动结束的时间"
    )
    var endTime: Date

    // 参数4: 活动描述（可选）
    @Parameter(
        title: "活动描述",
        description: "活动的详细说明"
    )
    var activityDescription: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateActivity] 开始创建活动")
        print("[CreateActivity] 标题: \(title)")
        print("[CreateActivity] 开始时间: \(startTime)")
        print("[CreateActivity] 结束时间: \(endTime)")
        print("[CreateActivity] 描述: \(activityDescription ?? "无")")

        // 验证时间有效性
        guard endTime > startTime else {
            print("[CreateActivity] 错误: 结束时间必须晚于开始时间")
            throw IntentError.message("结束时间必须晚于开始时间")
        }

        // 转换为 ISO 8601 格式
        let formatter = ISO8601DateFormatter()
        let startTimeStr = formatter.string(from: startTime)
        let endTimeStr = formatter.string(from: endTime)

        // 构造参数对象
        var params: [String: Any] = [
            "startTime": startTimeStr,
            "endTime": endTimeStr,
            "title": title
        ]

        // 添加描述（如果有）
        if let description = activityDescription, !description.isEmpty {
            params["description"] = description
        }

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "activity",
            "methodName": "createActivity",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateActivity] 已发送数据到 Flutter: \(jsonString)")

            // 计算活动时长
            let duration = endTime.timeIntervalSince(startTime) / 60
            let resultMessage = "已记录活动: \(title) (\(Int(duration))分钟)"
            return .result(value: resultMessage)
        } else {
            print("[CreateActivity] JSON 序列化失败")
            throw IntentError.message("创建活动失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("记录活动 \(\.$title)") {
            \.$startTime
            \.$endTime
            \.$activityDescription
        }
    }
}
