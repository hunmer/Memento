//
//  WCSessionManager.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/11.
//

import WatchConnectivity
import os.log
import Combine

// MARK: - 数据模型

struct ChatChannel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let unreadCount: Int
    let createdAt: String?
    let lastActiveAt: String?
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let channelId: String
    let content: String
    let senderId: String?
    let senderName: String?
    let timestamp: String
    let isMe: Bool?
}

// MARK: - 请求和响应类型

enum WatchRequest: String, Codable {
    case getChatChannels
    case getChatMessages
}

enum ResponseKey: String, Codable {
    case success
    case data
    case error
}

// MARK: - WCSession Manager

class WCSessionManager: NSObject, ObservableObject {
    static let shared = WCSessionManager()
    private let logger = Logger(subsystem: "com.memento.watch", category: "WCSession")

    @Published var isConnected = false
    @Published var isReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            logger.info("WCSession 初始化完成")
        } else {
            logger.error("WCSession 不支持")
        }
    }
}

// MARK: - 公开方法

extension WCSessionManager {

    /// 获取所有频道
    func getChatChannels() async throws -> [ChatChannel] {
        let request: [String: Any] = ["request": WatchRequest.getChatChannels.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到频道列表响应: \(String(describing: response))")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let channels = try JSONDecoder().decode([ChatChannel].self, from: jsonData)
                        continuation.resume(returning: channels)
                    } catch {
                        self.logger.error("解析频道数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取频道列表失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取指定频道的消息
    func getChatMessages(channelId: String) async throws -> [ChatMessage] {
        let request: [String: Any] = [
            "request": WatchRequest.getChatMessages.rawValue,
            "channelId": channelId
        ]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到消息列表响应: \(String(describing: response))")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let messages = try JSONDecoder().decode([ChatMessage].self, from: jsonData)
                        continuation.resume(returning: messages)
                    } catch {
                        self.logger.error("解析消息数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取消息列表失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }
}

// MARK: - WCSessionDelegate

extension WCSessionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
            if let error = error {
                self.logger.error("WCSession 激活失败: \(error.localizedDescription)")
            } else {
                self.logger.info("WCSession 已激活，状态: \(activationState.rawValue)")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.logger.info("Phone reachable 状态变更: \(session.isReachable)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("收到消息: \(message)")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        logger.info("收到应用上下文更新: \(applicationContext)")
    }

}
