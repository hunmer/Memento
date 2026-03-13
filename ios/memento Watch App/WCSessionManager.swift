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

struct ChatChannel: Codable, Identifiable, Hashable {
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

// MARK: - 日记数据模型

struct DiaryEntry: Codable, Identifiable, Hashable {
    var id: String { date }
    let date: String
    let title: String
    let contentPreview: String
    let wordCount: Int
    let mood: String?
    let updatedAt: String
}

struct DiaryEntryDetail: Codable {
    let date: String
    let title: String
    let content: String
    let wordCount: Int
    let mood: String?
    let createdAt: String
    let updatedAt: String
}

struct DiaryStats: Codable {
    let todayWordCount: Int
    let monthWordCount: Int
    let completedDays: Int
    let totalDays: Int
}

// MARK: - 活动数据模型

struct ActivityRecord: Codable, Identifiable {
    let id: String
    let title: String
    let startTime: String
    let endTime: String
    let duration: Int
    let tags: [String]
    let description: String?
    let mood: String?
}

struct ActivityTodayStats: Codable {
    let todayCount: Int
    let todayDuration: Int
    let remainingTime: Int
    let activities: [ActivityRecord]
}

// MARK: - 打卡数据模型

struct CheckinItem: Codable, Identifiable {
    let id: String
    let name: String
    let icon: Int
    let color: Int
    let isCheckedToday: Bool
    let consecutiveDays: Int
    let weekDays: [CheckinDay]
    let lastCheckinTime: String?
}

struct CheckinDay: Codable {
    let day: String
    let checked: Bool
}

// MARK: - 联系人数据模型

struct ContactItem: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String
    let avatar: String?
    let gender: String?
    let notes: String?
    let tags: [String]
    let interactionCount: Int
    let lastInteractionType: String?
    let lastInteractionTime: String?
    let lastContactTime: String
}

// MARK: - 习惯数据模型

struct HabitItem: Codable, Identifiable {
    let id: String
    let title: String
    let skillName: String
    let skillColor: Int
    let icon: String?
    let todayMinutes: Int
    let targetMinutes: Int
    let totalDurationMinutes: Int
    let dailyMinutes: [Int]
}

// MARK: - 计时器数据模型

struct TimerSubItem: Codable, Identifiable {
    let id: String
    let name: String
    let type: Int  // 0: countUp, 1: countDown, 2: pomodoro
    let duration: Int  // 秒
    let completedDuration: Int  // 秒
    let isRunning: Bool
    let isCompleted: Bool
    let repeatCount: Int?
    let workDuration: Int?  // 番茄钟专用
    let breakDuration: Int?  // 番茄钟专用
    let cycles: Int?  // 番茄钟专用
    let currentCycle: Int?  // 番茄钟专用
    let isWorkPhase: Bool?  // 番茄钟专用
}

struct TimerTaskItem: Codable, Identifiable {
    let id: String
    let name: String
    let color: Int
    let icon: Int
    let group: String?
    let isRunning: Bool
    let isCompleted: Bool
    let repeatCount: Int?
    let timerItems: [TimerSubItem]
    let activeTimerId: String?
    let createdAt: String?
}

// MARK: - 请求和响应类型

enum WatchRequest: String, Codable {
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

    // MARK: - 日记相关方法

    /// 获取本月日记列表
    func getDiaryEntries() async throws -> [DiaryEntry] {
        let request: [String: Any] = ["request": WatchRequest.getDiaryEntries.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到日记列表响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let entries = try JSONDecoder().decode([DiaryEntry].self, from: jsonData)
                        continuation.resume(returning: entries)
                    } catch {
                        self.logger.error("解析日记数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取日记列表失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取指定日期的日记详情
    func getDiaryEntry(date: String) async throws -> DiaryEntryDetail {
        let request: [String: Any] = [
            "request": WatchRequest.getDiaryEntry.rawValue,
            "date": date
        ]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到日记详情响应")

                if let success = response["success"] as? Bool, success,
                   let data = response["data"] as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let entry = try JSONDecoder().decode(DiaryEntryDetail.self, from: jsonData)
                        continuation.resume(returning: entry)
                    } catch {
                        self.logger.error("解析日记详情失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取日记详情失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取日记统计数据
    func getDiaryStats() async throws -> DiaryStats {
        let request: [String: Any] = ["request": WatchRequest.getDiaryStats.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到日记统计响应")

                if let success = response["success"] as? Bool, success,
                   let data = response["data"] as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let stats = try JSONDecoder().decode(DiaryStats.self, from: jsonData)
                        continuation.resume(returning: stats)
                    } catch {
                        self.logger.error("解析日记统计失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取日记统计失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 活动相关方法

    /// 获取今日活动统计数据
    func getActivityToday() async throws -> ActivityTodayStats {
        let request: [String: Any] = ["request": WatchRequest.getActivityToday.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到今日活动统计响应")

                if let success = response["success"] as? Bool, success,
                   let data = response["data"] as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let stats = try JSONDecoder().decode(ActivityTodayStats.self, from: jsonData)
                        continuation.resume(returning: stats)
                    } catch {
                        self.logger.error("解析今日活动统计失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取今日活动统计失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取指定日期的活动数据
    func getActivityData(date: String? = nil) async throws -> [ActivityRecord] {
        var request: [String: Any] = ["request": WatchRequest.getActivityData.rawValue]
        if let date = date {
            request["date"] = date
        }

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到活动数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let activities = try JSONDecoder().decode([ActivityRecord].self, from: jsonData)
                        continuation.resume(returning: activities)
                    } catch {
                        self.logger.error("解析活动数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取活动数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 打卡相关方法

    /// 获取打卡项目列表
    func getCheckinItems() async throws -> [CheckinItem] {
        logger.info("发送 getCheckinItems 请求")
        logger.info("Watch isReachable: \(WCSession.default.isReachable)")
        logger.info("Watch activationState: \(WCSession.default.activationState.rawValue)")

        let request: [String: Any] = ["request": WatchRequest.getCheckinItems.rawValue]
        logger.info("请求内容: \(request)")

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到打卡数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([CheckinItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析打卡数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取打卡数据失败: \(error.localizedDescription)")
                self.logger.error("WCError: \(error)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 联系人相关方法

    /// 获取联系人列表
    func getContactItems() async throws -> [ContactItem] {
        logger.info("发送 getContactItems 请求")

        let request: [String: Any] = ["request": WatchRequest.getContactItems.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到联系人数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([ContactItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析联系人数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取联系人数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 习惯相关方法

    /// 获取习惯列表
    func getHabits() async throws -> [HabitItem] {
        logger.info("发送 getHabits 请求")

        let request: [String: Any] = ["request": WatchRequest.getHabits.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到习惯数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([HabitItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析习惯数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取习惯数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 计时器相关方法

    /// 获取计时器列表
    func getTimers() async throws -> [TimerTaskItem] {
        logger.info("发送 getTimers 请求")

        let request: [String: Any] = ["request": WatchRequest.getTimers.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到计时器数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([TimerTaskItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析计时器数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取计时器数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }
}

// MARK: - WCSessionDelegate

extension WCSessionManager: WCSessionDelegate {

    // watchOS 必需方法
    #if os(watchOS)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            self.isConnected = (activationState == .activated)
            if let error = error {
                self.logger.error("WCSession 激活失败: \(error.localizedDescription)")
            } else {
                self.logger.info("WCSession 已激活，状态: \(activationState.rawValue)")
            }
        }
    }
    #endif

    // iOS 必需方法
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession 已变为非活动状态")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession 已停用")
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            self.isConnected = (activationState == .activated)
            if let error = error {
                self.logger.error("WCSession 激活失败: \(error.localizedDescription)")
            } else {
                self.logger.info("WCSession 已激活，状态: \(activationState.rawValue)")
            }
        }
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
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

    // 消息回复处理器
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("收到消息（带回复）: \(message)")
        replyHandler(["received": true])
    }
}
