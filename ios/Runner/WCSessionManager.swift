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
    case getCheckinItems
    case getContactItems
    case getHabits
    case getTimers
    case getTodoTasks
    case getDayItems
    case getTrackerGoals
    case getBillItems
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
        logger.info("===== 收到消息（带回复）: \(message) =====")

        guard let requestString = message["request"] as? String else {
            logger.error("请求中没有 request 字段")
            replyHandler([
                "success": false,
                "error": "无效的请求格式"
            ])
            return
        }

        logger.info("请求类型: \(requestString)")

        guard let requestType = WatchRequest(rawValue: requestString) else {
            logger.error("未知的请求类型: \(requestString)")
            replyHandler([
                "success": false,
                "error": "无效的请求类型: \(requestString)"
            ])
            return
        }

        logger.info("开始处理请求: \(requestString)")
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
        case .getCheckinItems:
            handleGetCheckinItems(replyHandler: replyHandler)
        case .getContactItems:
            handleGetContactItems(replyHandler: replyHandler)
        case .getHabits:
            handleGetHabits(replyHandler: replyHandler)
        case .getTimers:
            handleGetTimers(replyHandler: replyHandler)
        case .getTodoTasks:
            handleGetTodoTasks(replyHandler: replyHandler)
        case .getDayItems:
            handleGetDayItems(replyHandler: replyHandler)
        case .getTrackerGoals:
            handleGetTrackerGoals(replyHandler: replyHandler)
        case .getBillItems:
            handleGetBillItems(replyHandler: replyHandler)
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

    // MARK: - 打卡相关处理方法

    private func handleGetCheckinItems(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getCheckinItems 请求")

        // 通过 MethodChannel 向 Flutter 请求打卡数据
        methodChannel?.invokeMethod("getWatchCheckinItems", arguments: nil) { result in
            // Flutter 的 result 可能是错误对象 (FlutterError)
            if let flutterError = result as? FlutterError {
                self.logger.error("获取打卡数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取打卡数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 联系人相关处理方法

    private func handleGetContactItems(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getContactItems 请求")

        // 通过 MethodChannel 向 Flutter 请求联系人数据
        methodChannel?.invokeMethod("getWatchContactItems", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取联系人数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取联系人数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 习惯相关处理方法

    private func handleGetHabits(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getHabits 请求")

        // 通过 MethodChannel 向 Flutter 请求习惯数据
        methodChannel?.invokeMethod("getWatchHabits", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取习惯数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取习惯数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 计时器相关处理方法

    private func handleGetTimers(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getTimers 请求")

        // 通过 MethodChannel 向 Flutter 请求计时器数据
        methodChannel?.invokeMethod("getWatchTimers", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取计时器数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取计时器数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 待办任务相关处理方法

    private func handleGetTodoTasks(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getTodoTasks 请求")

        // 通过 MethodChannel 向 Flutter 请求待办任务数据
        methodChannel?.invokeMethod("getWatchTodoTasks", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取待办任务数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取待办任务数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 纪念日相关处理方法

    private func handleGetDayItems(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getDayItems 请求")

        // 通过 MethodChannel 向 Flutter 请求纪念日数据
        methodChannel?.invokeMethod("getWatchDayItems", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取纪念日数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取纪念日数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 目标追踪相关处理方法

    private func handleGetTrackerGoals(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getTrackerGoals 请求")

        // 通过 MethodChannel 向 Flutter 请求追踪目标数据
        methodChannel?.invokeMethod("getWatchTrackerGoals", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取追踪目标数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取追踪目标数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }

    // MARK: - 账单相关处理方法

    private func handleGetBillItems(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("处理 getBillItems 请求")

        // 通过 MethodChannel 向 Flutter 请求账单数据
        methodChannel?.invokeMethod("getWatchBillItems", arguments: nil) { result in
            if let flutterError = result as? FlutterError {
                self.logger.error("获取账单数据失败: \(flutterError.message ?? "未知错误")")
                replyHandler([
                    "success": false,
                    "error": flutterError.message ?? "未知错误"
                ])
                return
            }

            guard let data = result as? [[String: Any]] else {
                self.logger.error("无效的返回数据格式: \(String(describing: result))")
                replyHandler([
                    "success": false,
                    "error": "无效的返回数据格式"
                ])
                return
            }

            self.logger.info("成功获取账单数据，数据条数: \(data.count)")
            replyHandler([
                "success": true,
                "data": data
            ])
        }
    }
}
