import AppIntents
import intelligence

/// 快速创建日记 Intent
///
/// 支持 Siri 语音输入日记内容
struct CreateDiaryIntent: AppIntent {
    static var title: LocalizedStringResource = "写日记"
    static var description: IntentDescription = "创建今天的日记"
    static var openAppWhenRun: Bool = true

    // 参数1: 日记内容（必填）
    @Parameter(
        title: "日记内容",
        description: "今天想记录的内容",
        requestValueDialog: "今天想记录什么?"
    )
    var content: String

    // 参数2: 日记标题（可选）
    @Parameter(
        title: "日记标题",
        description: "给今天的日记起个标题"
    )
    var title: String?

    // 参数3: 心情（可选）
    @Parameter(
        title: "今天的心情",
        description: "选择一个表情来表达今天的心情",
        default: DiaryMood.neutral
    )
    var mood: DiaryMood

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateDiary] 开始创建日记")
        print("[CreateDiary] 内容: \(content)")
        print("[CreateDiary] 标题: \(title ?? "无")")
        print("[CreateDiary] 心情: \(mood.emoji)")

        // 获取今天的日期（格式：YYYY-MM-DD）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        // 构造参数对象
        var params: [String: Any] = [
            "date": today,
            "content": content,
            "mood": mood.emoji
        ]

        // 添加标题（如果有）
        if let diaryTitle = title, !diaryTitle.isEmpty {
            params["title"] = diaryTitle
        }

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "diary",
            "methodName": "saveDiary",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateDiary] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let resultMessage = "已记录今天的日记 \(mood.emoji)"
            return .result(value: resultMessage)
        } else {
            print("[CreateDiary] JSON 序列化失败")
            throw IntentError.message("创建日记失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("写日记") {
            \.$content
            \.$title
            \.$mood
        }
    }
}

/// 日记心情枚举
enum DiaryMood: String, AppEnum {
    case veryHappy = "veryHappy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case angry = "angry"

    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .angry: return "😠"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "心情")
    }

    static var caseDisplayRepresentations: [DiaryMood: DisplayRepresentation] {
        [
            .veryHappy: DisplayRepresentation(title: "非常开心 😄"),
            .happy: DisplayRepresentation(title: "开心 😊"),
            .neutral: DisplayRepresentation(title: "平静 😐"),
            .sad: DisplayRepresentation(title: "难过 😔"),
            .angry: DisplayRepresentation(title: "生气 😠")
        ]
    }
}
