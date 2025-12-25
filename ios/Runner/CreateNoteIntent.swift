import AppIntents
import intelligence

/// 快速创建笔记 Intent
///
/// 支持 Siri 语音输入笔记内容
struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "快速笔记"
    static var description: IntentDescription = "快速创建一条新笔记"
    static var openAppWhenRun: Bool = true

    // 参数1: 笔记标题（必填）
    @Parameter(
        title: "笔记标题",
        description: "笔记的标题",
        requestValueDialog: "笔记标题是什么?"
    )
    var title: String

    // 参数2: 笔记内容（必填）
    @Parameter(
        title: "笔记内容",
        description: "笔记的正文内容",
        requestValueDialog: "笔记内容是什么?"
    )
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateNote] 开始创建笔记")
        print("[CreateNote] 标题: \(title)")
        print("[CreateNote] 内容: \(content)")

        // 构造参数对象
        let params: [String: Any] = [
            "title": title,
            "content": content
        ]

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "notes",
            "methodName": "createNote",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateNote] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let resultMessage = "已创建笔记: \(title)"
            return .result(value: resultMessage)
        } else {
            print("[CreateNote] JSON 序列化失败")
            throw IntentError.message("创建笔记失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("创建笔记 \(\.$title)") {
            \.$content
        }
    }
}
