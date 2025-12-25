import Foundation

/// Shortcut 执行结果的共享存储
///
/// 使用 App Groups 共享容器在 App Intent (Extension) 和 Flutter (Main App) 之间传递数据
class ShortcutResultStorage {
    static let shared = ShortcutResultStorage()

    private let appGroupIdentifier = "group.github.hunmer.memento"
    private let resultsDirectoryName = "shortcut_results"

    private init() {
        createResultsDirectoryIfNeeded()
    }

    /// 获取共享容器目录
    private var sharedContainerURL: URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    /// 获取结果存储目录
    private var resultsDirectoryURL: URL? {
        guard let containerURL = sharedContainerURL else { return nil }
        return containerURL.appendingPathComponent(resultsDirectoryName)
    }

    /// 创建结果存储目录（如果不存在）
    private func createResultsDirectoryIfNeeded() {
        guard let directoryURL = resultsDirectoryURL else { return }

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    /// 生成结果文件的 URL
    func resultFileURL(for callId: String) -> URL? {
        return resultsDirectoryURL?.appendingPathComponent("\(callId).json")
    }

    /// 写入"等待中"状态
    func writePendingStatus(callId: String) {
        guard let fileURL = resultFileURL(for: callId) else { return }

        let pendingData: [String: Any] = [
            "status": "pending",
            "timestamp": Date().timeIntervalSince1970
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: pendingData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            try? jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[ShortcutResult] 已写入等待状态: \(callId)")
        }
    }

    /// 轮询读取结果（带超时）
    func pollResult(callId: String, timeout: TimeInterval = 30.0) async -> [String: Any]? {
        guard let fileURL = resultFileURL(for: callId) else {
            print("[ShortcutResult] 无法获取结果文件路径")
            return nil
        }

        let startTime = Date()
        let pollInterval: TimeInterval = 0.5 // 每 0.5 秒检查一次

        while Date().timeIntervalSince(startTime) < timeout {
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                continue
            }

            // 读取文件内容
            guard let jsonString = try? String(contentsOf: fileURL, encoding: .utf8),
                  let jsonData = jsonString.data(using: .utf8),
                  let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                continue
            }

            // 检查状态
            let status = result["status"] as? String

            if status == "completed" {
                print("[ShortcutResult] 读取到完成结果: \(callId)")
                // 清理文件
                try? FileManager.default.removeItem(at: fileURL)
                return result
            } else if status == "pending" {
                // 仍在等待，继续轮询
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                continue
            } else {
                // 未知状态
                print("[ShortcutResult] 未知状态: \(status ?? "nil")")
                break
            }
        }

        // 超时或失败
        print("[ShortcutResult] 轮询超时或失败: \(callId)")
        try? FileManager.default.removeItem(at: fileURL)
        return nil
    }

    /// 清理过期的结果文件（超过 1 小时）
    func cleanupExpiredResults() {
        guard let directoryURL = resultsDirectoryURL else { return }

        let oneHourAgo = Date().addingTimeInterval(-3600)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        for fileURL in files {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let creationDate = attrs[.creationDate] as? Date,
               creationDate < oneHourAgo {
                try? FileManager.default.removeItem(at: fileURL)
                print("[ShortcutResult] 已清理过期文件: \(fileURL.lastPathComponent)")
            }
        }
    }
}
