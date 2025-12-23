import AppIntents
import intelligence

struct SendToAgentChatIntent: AppIntent {
    static var title: LocalizedStringResource = "发送消息到AI聊天"
    static var description: IntentDescription = "发送文本和图片到 Memento 的 AI 聊天频道"
    static var openAppWhenRun: Bool = true

    // 参数1: 文本内容（必填）
    @Parameter(title: "消息内容", description: "要发送的文本内容")
    var messageText: String

    // 参数2: 图片列表（可选）
    @Parameter(title: "图片", description: "要发送的图片（支持多张）")
    var images: [IntentFile]?

    // 参数3: 频道选择（可选）
    @Parameter(title: "频道", description: "选择已有频道，留空则创建新会话")
    var channel: ConversationEntity?

    @MainActor
    func perform() async throws -> some IntentResult {
        // 构造 JSON 数据
        var data: [String: Any] = [
            "action": "send_to_agent_chat",
            "message": messageText,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 处理频道ID
        if let channel = channel {
            data["conversationId"] = channel.id
        }

        // 处理图片文件
        if let images = images, !images.isEmpty {
            print("[SendToAgentChat] 收到 \(images.count) 张图片")
            var imagePaths: [String] = []

            for (index, imageFile) in images.enumerated() {
                print("[SendToAgentChat] 处理图片 \(index): \(imageFile)")

                // 将图片保存到临时目录
                if let fileURL = imageFile.fileURL {
                    print("[SendToAgentChat] 图片源路径: \(fileURL.path)")
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = "shortcut_image_\(index)_\(Date().timeIntervalSince1970).jpg"
                    let destURL = tempDir.appendingPathComponent(fileName)
                    print("[SendToAgentChat] 图片目标路径: \(destURL.path)")

                    do {
                        // 复制文件到临时目录
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.copyItem(at: fileURL, to: destURL)
                        imagePaths.append(destURL.path)
                        print("[SendToAgentChat] 图片复制成功: \(destURL.path)")
                    } catch {
                        print("[SendToAgentChat] 图片处理失败: \(error)")
                    }
                } else {
                    print("[SendToAgentChat] 警告：图片 \(index) 没有 fileURL")
                }
            }

            if !imagePaths.isEmpty {
                data["imagePaths"] = imagePaths
                print("[SendToAgentChat] 添加了 \(imagePaths.count) 张图片到数据: \(imagePaths)")
            } else {
                print("[SendToAgentChat] 警告：所有图片处理失败，imagePaths 为空")
            }
        } else {
            print("[SendToAgentChat] 未收到图片或图片数组为空")
        }

        // 将数据转换为 JSON 字符串
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // 通过 intelligence 插件通知 Flutter
            IntelligencePlugin.notifier.push(jsonString)
            print("[SendToAgentChat] 已发送数据到 Flutter: \(jsonString)")
        }

        return .result()
    }

    static var parameterSummary: some ParameterSummary {
        Summary("发送 \(\.$messageText)") {
            \.$images
            \.$channel
        }
    }
}
