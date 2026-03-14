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

// MARK: - 待办任务数据模型

struct TodoTaskItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let priority: Int
    let quadrant: String
    let status: Int
    let tags: [String]
    let subtaskCount: Int
    let completedSubtaskCount: Int
    let startDate: String?
    let dueDate: String?
    let duration: Int?
    let iconCodePoint: Int?

    // 计算属性
    var isCompleted: Bool {
        return status == 2  // TaskStatus.done = 2
    }
}

// MARK: - 纪念日数据模型

struct DayItem: Codable, Identifiable {
    let id: String
    let title: String
    let targetDate: String
    let daysRemaining: Int
    let isExpired: Bool
    let isToday: Bool
    let backgroundColor: Int
    let backgroundImageUrl: String?
    let notes: [String]?

    // 计算属性：状态文本
    var statusText: String {
        if isToday {
            return "今天"
        } else if isExpired {
            return "\(-daysRemaining) 天前"
        } else {
            return "\(daysRemaining) 天后"
        }
    }

    // 计算属性：颜色
    var accentColor: Color {
        if isToday {
            return .green
        } else if isExpired {
            return .purple
        } else if daysRemaining <= 7 {
            return .cyan
        } else {
            return .orange
        }
    }
}

// MARK: - 目标追踪数据模型

struct TrackerGoal: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String?
    let iconColor: Int?
    let unitType: String
    let targetValue: Double
    let currentValue: Double
    let progress: Double
    let isCompleted: Bool
    let group: String
    let accentColor: Int
    let dateSettingsType: String?
    let dailyCompleted: [Bool]?

    // 计算属性：进度百分比
    var progressPercent: Int {
        return min(Int(progress * 100), 100)
    }

    // 计算属性：进度显示文本
    var progressText: String {
        if targetValue >= 1000 {
            return String(format: "%.1fk/%.0fk", currentValue / 1000, targetValue / 1000)
        } else if targetValue >= 100 {
            return String(format: "%.0f/%.0f", currentValue, targetValue)
        } else {
            return String(format: "%.1f/%.1f", currentValue, targetValue)
        }
    }

    // 计算属性：霓虹色
    var neonColor: Color {
        return Color(
            red: Double((accentColor >> 16) & 0xFF) / 255.0,
            green: Double((accentColor >> 8) & 0xFF) / 255.0,
            blue: Double(accentColor & 0xFF) / 255.0
        )
    }
}

// MARK: - 账单数据模型

struct BillItem: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let amount: Double
    let date: String
    let isExpense: Bool
    let icon: Int
    let iconColor: Int
    let note: String?
    let isSubscription: Bool?

    // 计算属性：格式化金额
    var formattedAmount: String {
        let absAmount = abs(amount)
        if absAmount >= 1000 {
            return String(format: "%@%.1fk", isExpense ? "-" : "+", absAmount / 1000)
        } else {
            return String(format: "%@%.2f", isExpense ? "-" : "+", absAmount)
        }
    }

    // 计算属性：图标颜色
    var itemIconColor: Color {
        return Color(
            red: Double((iconColor >> 16) & 0xFF) / 255.0,
            green: Double((iconColor >> 8) & 0xFF) / 255.0,
            blue: Double(iconColor & 0xFF) / 255.0
        )
    }

    // 计算属性：金额颜色
    var amountColor: Color {
        return isExpense ? Color(red: 1.0, green: 0.231, blue: 0.188) :  // 红色 #FF3B30
               Color(red: 0.204, green: 0.78, blue: 0.349)  // 绿色 #34C759
    }
}

// MARK: - 笔记数据模型

struct NoteItem: Codable, Identifiable {
    let id: String
    let title: String
    let contentPreview: String
    let folderId: String
    let folderName: String
    let folderColor: Int
    let folderIcon: Int
    let neonBorderColor: Int
    let tags: [String]
    let createdAt: String
    let updatedAt: String

    // 计算属性：霓虹边框颜色
    var neonColor: Color {
        return Color(
            red: Double((neonBorderColor >> 16) & 0xFF) / 255.0,
            green: Double((neonBorderColor >> 8) & 0xFF) / 255.0,
            blue: Double(neonBorderColor & 0xFF) / 255.0
        )
    }

    // 计算属性：文件夹颜色
    var folderItemColor: Color {
        return Color(
            red: Double((folderColor >> 16) & 0xFF) / 255.0,
            green: Double((folderColor >> 8) & 0xFF) / 255.0,
            blue: Double(folderColor & 0xFF) / 255.0
        )
    }

    // 计算属性：格式化更新时间
    var formattedUpdateTime: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: updatedAt) else {
            return ""
        }
        let now = Date()
        let calendar = Calendar.current

        // 计算时间差
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days)d ago"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                return dateFormatter.string(from: date)
            }
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - 商店商品数据模型

struct StoreProduct: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let price: Int
    let stock: Int
    let isAvailable: Bool
    let useDuration: Int?

    // 计算属性：显示的库存状态
    var stockStatus: String {
        if stock <= 0 {
            return "已售罄"
        } else if stock <= 5 {
            return "仅剩\(stock)件"
        } else {
            return "库存\(stock)件"
        }
    }
}

// MARK: - 用户物品分组数据模型

struct UserItemGroup: Codable, Identifiable {
    var id: String { productId }
    let productId: String
    let productName: String
    let count: Int
    let isExpired: Bool
    let earliestExpiry: String
    let daysRemaining: Int
    let purchasePrice: Int

    // 计算属性：过期状态文本
    var expiryText: String {
        if isExpired {
            return "已过期"
        } else if daysRemaining == 0 {
            return "今天过期"
        } else if daysRemaining <= 3 {
            return "\(daysRemaining)天后过期"
        } else if daysRemaining <= 7 {
            return "\(daysRemaining)天后过期"
        } else {
            return "\(daysRemaining)天后过期"
        }
    }

    // 计算属性：状态颜色
    var statusColor: Color {
        if isExpired {
            return .red
        } else if daysRemaining == 0 {
            return .orange
        } else if daysRemaining <= 3 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - 节点笔记本数据模型

struct NodesNotebook: Codable, Identifiable {
    let id: String
    let title: String
    let icon: Int
    let color: Int
    let nodeCount: Int

    // 计算属性：笔记本颜色
    var notebookColor: Color {
        return Color(
            red: Double((color >> 16) & 0xFF) / 255.0,
            green: Double((color >> 8) & 0xFF) / 255.0,
            blue: Double(color & 0xFF) / 255.0
        )
    }
}

// MARK: - 节点数据模型

struct NodeItem: Codable, Identifiable {
    let id: String
    let title: String
    let status: Int  // 0=todo, 1=doing, 2=done, 3=none
    let color: Int
    let tags: [String]
    let notes: String?
    let depth: Int
    let hasChildren: Bool
    let childrenCount: Int

    // 计算属性：节点颜色
    var nodeColor: Color {
        return Color(
            red: Double((color >> 16) & 0xFF) / 255.0,
            green: Double((color >> 8) & 0xFF) / 255.0,
            blue: Double(color & 0xFF) / 255.0
        )
    }

    // 计算属性：状态图标
    var statusIcon: String {
        switch status {
        case 0: return "circle"
        case 1: return "clock"
        case 2: return "checkmark.circle.fill"
        default: return "circle"
        }
    }

    // 计算属性：状态颜色
    var statusColor: Color {
        switch status {
        case 0: return .gray
        case 1: return .blue
        case 2: return .green
        default: return .gray.opacity(0.5)
        }
    }

    // 计算属性：状态文本
    var statusText: String {
        switch status {
        case 0: return "待办"
        case 1: return "进行中"
        case 2: return "已完成"
        default: return ""
        }
    }
}
    let count: Int
    let isExpired: Bool
    let earliestExpiry: String
    let daysRemaining: Int
    let purchasePrice: Int

    // 计算属性：过期状态文本
    var expiryStatus: String {
        if isExpired {
            return "已过期"
        } else if daysRemaining == 0 {
            return "今天过期"
        } else if daysRemaining <= 3 {
            return "\(daysRemaining)天后过期"
        } else if daysRemaining <= 7 {
            return "\(daysRemaining)天后过期"
        } else {
            return "\(daysRemaining)天后过期"
        }
    }

    // 计算属性：状态颜色
    var statusColor: Color {
        if isExpired {
            return .red
        } else if daysRemaining == 0 {
            return .orange
        } else if daysRemaining <= 3 {
            return .yellow
        } else {
            return .green
        }
    }
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
    case getTodoTasks
    case getDayItems
    case getTrackerGoals
    case getBillItems
    case getNotes
    case getStoreProducts
    case getUserItems
    case getNodesNotebooks
    case getNodes
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

    // MARK: - 待办任务相关方法

    /// 获取待办任务列表
    func getTodoTasks() async throws -> [TodoTaskItem] {
        logger.info("发送 getTodoTasks 请求")

        let request: [String: Any] = ["request": WatchRequest.getTodoTasks.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到待办任务数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([TodoTaskItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析待办任务数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取待办任务数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 纪念日相关方法

    /// 获取纪念日列表
    func getDayItems() async throws -> [DayItem] {
        logger.info("发送 getDayItems 请求")

        let request: [String: Any] = ["request": WatchRequest.getDayItems.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到纪念日数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([DayItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析纪念日数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取纪念日数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 目标追踪相关方法

    /// 获取追踪目标列表
    func getTrackerGoals() async throws -> [TrackerGoal] {
        logger.info("发送 getTrackerGoals 请求")

        let request: [String: Any] = ["request": WatchRequest.getTrackerGoals.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到追踪目标数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([TrackerGoal].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析追踪目标数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取追踪目标数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 账单相关方法

    /// 获取账单列表
    func getBillItems() async throws -> [BillItem] {
        logger.info("发送 getBillItems 请求")

        let request: [String: Any] = ["request": WatchRequest.getBillItems.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到账单数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([BillItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析账单数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取账单数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 笔记相关方法

    /// 获取笔记列表
    func getNotes() async throws -> [NoteItem] {
        logger.info("发送 getNotes 请求")

        let request: [String: Any] = ["request": WatchRequest.getNotes.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到笔记数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([NoteItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析笔记数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取笔记数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 商店相关方法

    /// 获取商品列表
    func getStoreProducts() async throws -> [StoreProduct] {
        logger.info("发送 getStoreProducts 请求")

        let request: [String: Any] = ["request": WatchRequest.getStoreProducts.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到商品数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([StoreProduct].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析商品数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取商品数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取用户物品列表
    func getUserItems() async throws -> [UserItemGroup] {
        logger.info("发送 getUserItems 请求")

        let request: [String: Any] = ["request": WatchRequest.getUserItems.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到用户物品数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([UserItemGroup].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析用户物品数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取用户物品数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - 节点笔记本相关方法

    /// 获取节点笔记本列表
    func getNodesNotebooks() async throws -> [NodesNotebook] {
        logger.info("发送 getNodesNotebooks 请求")

        let request: [String: Any] = ["request": WatchRequest.getNodesNotebooks.rawValue]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到节点笔记本数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([NodesNotebook].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析节点笔记本数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取节点笔记本数据失败: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }

    /// 获取指定笔记本的节点列表
    func getNodes(notebookId: String) async throws -> [NodeItem] {
        logger.info("发送 getNodes 请求, notebookId=\(notebookId)")

        let request: [String: Any] = [
            "request": WatchRequest.getNodes.rawValue,
            "notebookId": notebookId
        ]

        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(request, replyHandler: { response in
                self.logger.info("收到节点数据响应")

                if let success = response["success"] as? Bool, success,
                   let dataArray = response["data"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                        let items = try JSONDecoder().decode([NodeItem].self, from: jsonData)
                        continuation.resume(returning: items)
                    } catch {
                        self.logger.error("解析节点数据失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else if let errorMessage = response["error"] as? String {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(throwing: NSError(domain: "WCSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }, errorHandler: { error in
                self.logger.error("获取节点数据失败: \(error.localizedDescription)")
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
