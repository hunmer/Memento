import AppIntents
import intelligence

/// 快速创建待办任务 Intent
///
/// 支持 Siri 自然语言识别,可以通过语音快速创建任务
struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "创建待办任务"
    static var description: IntentDescription = "快速创建一个新的待办任务"
    static var openAppWhenRun: Bool = true

    // 参数1: 任务标题（必填）
    @Parameter(
        title: "任务名称",
        description: "要创建的任务标题",
        requestValueDialog: "你想创建什么任务?"
    )
    var title: String

    // 参数2: 优先级（可选）
    @Parameter(
        title: "优先级",
        description: "任务的优先级级别",
        default: TaskPriority.medium
    )
    var priority: TaskPriority

    // 参数3: 任务描述（可选）
    @Parameter(
        title: "任务描述",
        description: "任务的详细说明",
        requestValueDialog: "需要添加任务描述吗?"
    )
    var taskDescription: String?

    // 参数4: 截止日期（可选）
    @Parameter(
        title: "截止日期",
        description: "任务的截止日期"
    )
    var dueDate: Date?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateTask] 开始创建任务")
        print("[CreateTask] 标题: \(title)")
        print("[CreateTask] 优先级: \(priority.rawValue)")
        print("[CreateTask] 描述: \(taskDescription ?? "无")")
        print("[CreateTask] 截止日期: \(dueDate?.description ?? "无")")

        // 构造参数对象
        var params: [String: Any] = [
            "title": title,
            "priority": priority.rawValue
        ]

        // 添加可选参数
        if let description = taskDescription, !description.isEmpty {
            params["description"] = description
        }

        if let date = dueDate {
            // 转换为 ISO 8601 格式
            let formatter = ISO8601DateFormatter()
            params["dueDate"] = formatter.string(from: date)
        }

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "todo",
            "methodName": "createTask",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateTask] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let resultMessage = "已创建任务: \(title)"
            return .result(value: resultMessage)
        } else {
            print("[CreateTask] JSON 序列化失败")
            throw IntentError.message("创建任务失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("创建任务 \(\.$title)") {
            \.$priority
            \.$taskDescription
            \.$dueDate
        }
    }
}

/// 任务优先级枚举
enum TaskPriority: String, AppEnum {
    case low = "low"
    case medium = "medium"
    case high = "high"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "优先级")
    }

    static var caseDisplayRepresentations: [TaskPriority: DisplayRepresentation] {
        [
            .low: DisplayRepresentation(title: "低", subtitle: "不紧急的任务"),
            .medium: DisplayRepresentation(title: "中", subtitle: "普通任务"),
            .high: DisplayRepresentation(title: "高", subtitle: "重要任务")
        ]
    }
}
