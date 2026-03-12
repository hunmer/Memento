//
//  WCSessionManager.swift
//  Memento
//
//  Created by Claude on 2026/3/12.
//

import Foundation
import WatchConnectivity
import os.log
import Flutter

// MARK: - 数据模型

struct ChatChannel: Codable {
    let id: String
    let name: String
    let description: String?
    let unreadCount: Int
    let createdAt: String?
    let lastActiveAt: String?
}

struct ChatMessage: Codable {
    let id: String
    let channelId: String
    let content: String
    let senderId: String?
    let senderName: String?
    let timestamp: String
    let isMe: Bool?
}

// MARK: - 请求类型

enum WatchRequest: String {
    case getChatChannels
    case getChatMessages
    case getDiaryEntries
    case getDiaryEntry
    case getDiaryStats
    case getActivityToday
    case getActivityData
}

// MARK: - WCSession Manager

class WCSessionManager: NSObject, ObservableObject {
    static let shared = WCSessionManager()
    private let logger = Logger(subsystem: "com.memento.ios", category: "WCSession")

    private var methodChannel: FlutterMethodChannel?

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

    // 设置 MethodChannel 用于与 Flutter 通信
    func setupMethodChannel(_ controller: FlutterViewController) {
        methodChannel = FlutterMethodChannel(
            name: "github.hunmer.memento/watch_connectivity",
            binaryMessenger: controller.binaryMessenger
        )

        logger.info("WatchConnectivity MethodChannel 已配置")
    }
}

// MARK: - WCSessionDelegate

extension WCSessionManager: WCSessionDelegate {

    // iOS 必需方法
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession 已变为非活动状态")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession 已停用")
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isConnected = (activationState == .activated)
            if let error = error {
                self.logger.error("WCSession 激活失败: \(error.localizedDescription)")
            } else {
                self.logger.info("WCSession 已激活，状态: \(activationState.rawValue)")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.logger.info("Watch reachable 状态变更: \(session.isReachable)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("收到消息: \(message)")
    }

    // 处理来自 watchOS 的消息请求
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("收到消息（带回复）: \(message)")

        guard let requestString = message["request"] as? String,
              let requestType = WatchRequest(rawValue: requestString) else {
            replyHandler([
                "success": false,
                "error": "无效的请求类型"
            ])
            return
        }

        switch requestType {
        case .getChatChannels:
            handleGetChatChannels(replyHandler: replyHandler)
        case .getChatMessages:
            guard let channelId = message["channelId"] as? String else {
                replyHandler([
                    "success": false,
                    "error": "缺少 channelId 参数"
                ])
                return
            }
            handleGetChatMessages(channelId: channelId, replyHandler: replyHandler)
        case .getDiaryEntries:
            handleGetDiaryEntries(replyHandler: replyHandler)
        case .getDiaryEntry:
            guard let date = message["date"] as? String else {
                replyHandler([
                    "success": false,
                    "error": "缺少 date 参数"
                ])
                return
            }
            handleGetDiaryEntry(date: date, replyHandler: replyHandler)
        case .getDiaryStats:
            handleGetDiaryStats(replyHandler: replyHandler)
        case .getActivityToday:
            handleGetActivityToday(replyHandler: replyHandler)
        case .getActivityData:
            if let date = message["date"] as? String {
                handleGetActivityData(date: date, replyHandler: replyHandler)
            } else {
                handleGetActivityData(date: nil, replyHandler: replyHandler)
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        logger.info("收到应用上下文更新: \(applicationContext)")
    }

    // MARK: - 请求处理方法

    private func handleGetChatChannels(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getChatChannels 请求")

        // 通过 MethodChannel 向 Flutter 请求频道列表
        methodChannel?.invokeMethod("getWatchChatChannels", arguments: nil) { result in
            // Flutter 的 result 可能是错误对象 (FlutterError)
            if let flutterError = result as? FlutterError {
                self.logger.error("获取频道列表失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            // 直接返回字典数组给 watchOS
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    private func handleGetChatMessages(channelId: String, replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getChatMessages 请求: channelId=\(channelId)")

        // 通过 MethodChannel 向 Flutter 请求消息列表
        methodChannel?.invokeMethod("getWatchChatMessages", arguments: ["channelId": channelId]) { result in
            // Flutter 的 result 可能是错误对象 (FlutterError)
            if let flutterError = result as? FlutterError {
                self.logger.error("获取消息列表失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            // 直接返回字典数组给 watchOS
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    private func handleGetDiaryEntries(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getDiaryEntries 请求")

        // 通过 MethodChannel 向 Flutter 请求日记列表
        methodChannel?.invokeMethod("getWatchDiaryEntries", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取日记列表失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    private func handleGetDiaryEntry(date: String, replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getDiaryEntry 请求: date=\(date)")

        // 通过 MethodChannel 向 Flutter 请求日记详情
        methodChannel?.invokeMethod("getWatchDiaryEntry", arguments: ["date": date]) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取日记详情失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [String: Any] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    private func handleGetDiaryStats(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getDiaryStats 请求")

        // 通过 MethodChannel 向 Flutter 请求日记统计
        methodChannel?.invokeMethod("getWatchDiaryStats", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取日记统计失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [String: Any] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 活动相关处理方法

    private func handleGetActivityToday(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getActivityToday 请求")

        // 通过 MethodChannel 向 Flutter 请求今日活动统计
        methodChannel?.invokeMethod("getWatchActivityToday", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取今日活动统计失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [String: Any] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    private func handleGetActivityData(date: String?, replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getActivityData 请求: date=\(date ?? "nil")")

        var arguments: [String: Any]? = nil
        if let date = date {
            arguments = ["date": date]
        }

        // 通过 MethodChannel 向 Flutter 请求活动数据
        methodChannel?.invokeMethod("getWatchActivityData", arguments: arguments) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取活动数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 公开方法（主动向 watchOS 发送数据）

    /// 发送频道列表到 watchOS
    func sendChatChannelsToWatch(_ channels: [ChatChannel]) {
        guard WCSession.default.isReachable else {
            logger.warning("Watch 不可达，无法发送数据")
            return
        }

        do {
            let jsonData = try JSONEncoder().encode(channels)
            if let jsonDicts = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                WCSession.default.transferUserInfo(["chatChannels": jsonDicts])
                logger.info("已发送频道列表到 watchOS")
            }
        } catch {
            logger.error("编码频道数据失败: \(error.localizedDescription)")
        }
    }

    /// 发送消息到 watchOS
    func sendMessagesToWatch(_ messages: [ChatMessage], channelId: String) {
        guard WCSession.default.isReachable else {
            logger.warning("Watch 不可达，无法发送数据")
            return
        }

        do {
            let jsonData = try JSONEncoder().encode(messages)
            if let jsonDicts = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                WCSession.default.transferUserInfo([
                    "chatMessages": jsonDicts,
                    "channelId": channelId
                ])
                logger.info("已发送消息到 watchOS")
            }
        } catch {
            logger.error("编码消息数据失败: \(error.localizedDescription)")
        }
    }
}
