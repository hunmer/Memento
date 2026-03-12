//
//  ActivityListView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/12.
//

import SwiftUI
import Combine

// MARK: - 颜色扩展

extension Color {
    static let watchGray = Color(hex: "1c1c1e")
    static let watchTextSecondary = Color(hex: "8e8e93")
    static let fitnessGreen = Color(hex: "30d158")
    static let workBlue = Color(hex: "0a84ff")
    static let leisurePurple = Color(hex: "bf5af2")
    static let moodHappy = Color(hex: "30d158")
    static let moodGood = Color(hex: "64d2ff")
    static let moodNeutral = Color(hex: "ffd60a")
    static let moodBad = Color(hex: "ff9f0a")
    static let moodSad = Color(hex: "ff453a")
    static let durationBadgeBg = Color(hex: "2c2c2e")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 心情

enum Mood: String, CaseIterable {
    case happy = "开心"
    case good = "愉快"
    case neutral = "一般"
    case bad = "糟糕"
    case sad = "难过"

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .bad: return "😔"
        case .sad: return "😢"
        }
    }

    var color: Color {
        switch self {
        case .happy: return .moodHappy
        case .good: return .moodGood
        case .neutral: return .moodNeutral
        case .bad: return .moodBad
        case .sad: return .moodSad
        }
    }

    static func from(_ value: String?) -> Mood? {
        guard let value = value, !value.isEmpty else { return nil }

        // 直接匹配 emoji
        switch value {
        case "😊", "😄", "😃", "😁", "😆", "🥳", "🤩":
            return .happy
        case "🙂", "😉", "😊", "😌", "😎", "🤓":
            return .good
        case "😐", "😑", "😶", "🙄", "😏":
            return .neutral
        case "😔", "🙁", "😕", "😟", "😳", "😥":
            return .bad
        case "😢", "😭", "😿", "🥺", "💔":
            return .sad
        default:
            break
        }

        // 尝试匹配文字
        let lowercased = value.lowercased()
        if lowercased.contains("开心") || lowercased.contains("happy") || lowercased.contains("joy") {
            return .happy
        } else if lowercased.contains("愉快") || lowercased.contains("good") || lowercased.contains("nice") {
            return .good
        } else if lowercased.contains("一般") || lowercased.contains("neutral") || lowercased.contains("normal") {
            return .neutral
        } else if lowercased.contains("糟糕") || lowercased.contains("bad") || lowercased.contains("terrible") {
            return .bad
        } else if lowercased.contains("难过") || lowercased.contains("sad") || lowercased.contains("upset") {
            return .sad
        }
        return nil
    }
}

// MARK: - 活动分类

enum ActivityCategory: String {
    case fitness = "运动"
    case work = "工作"
    case leisure = "休闲"
    case other = "其他"

    var color: Color {
        switch self {
        case .fitness: return .fitnessGreen
        case .work: return .workBlue
        case .leisure: return .leisurePurple
        case .other: return .pink
        }
    }

    var shortLabel: String {
        switch self {
        case .fitness: return "运动"
        case .work: return "工作"
        case .leisure: return "休闲"
        case .other: return "其他"
        }
    }

    static func from(tags: [String]) -> ActivityCategory {
        let fitnessKeywords = ["运动", "健身", "跑步", "锻炼", "跑步", "游泳", "瑜伽", "fitness", "gym", "run"]
        let workKeywords = ["工作", "会议", "编码", "开发", "文档", "work", "meeting", "code"]
        let leisureKeywords = ["休闲", "休息", "娱乐", "游戏", "阅读", "音乐", "leisure", "rest", "game"]

        let lowercasedTags = tags.map { $0.lowercased() }

        for tag in lowercasedTags {
            if fitnessKeywords.contains(where: { tag.contains($0.lowercased()) }) {
                return .fitness
            }
            if workKeywords.contains(where: { tag.contains($0.lowercased()) }) {
                return .work
            }
            if leisureKeywords.contains(where: { tag.contains($0.lowercased()) }) {
                return .leisure
            }
        }
        return .other
    }
}

// MARK: - 主视图

struct ActivityListView: View {
    @StateObject private var viewModel = ActivityListViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Date Switcher - 始终显示
                DatePickerHeader(
                    dateText: viewModel.dateText,
                    canGoBack: viewModel.canGoBack,
                    canGoForward: viewModel.canGoForward,
                    onPrevious: { viewModel.previousDay() },
                    onNext: { viewModel.nextDay() }
                )

                if viewModel.isLoading && viewModel.activities.isEmpty {
                    ProgressView("加载中...")
                        .foregroundStyle(Color.watchTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.error, viewModel.activities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.watchTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            Task { await viewModel.loadData() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 20)
                } else if viewModel.activities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "timeline")
                            .font(.title)
                            .foregroundStyle(Color.watchTextSecondary)
                        Text("暂无活动记录")
                            .font(.caption)
                            .foregroundStyle(Color.watchTextSecondary)
                        Text("在手机上添加活动")
                            .font(.caption2)
                            .foregroundStyle(Color.watchTextSecondary)
                    }
                    .padding(.top, 20)
                } else {
                    // Stats Summary
                    StatsSummary(
                        count: viewModel.activities.count,
                        totalDuration: viewModel.totalDuration
                    )

                    // Timeline Section
                    TimelineSection(activities: viewModel.activities)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .refreshable {
            await viewModel.loadData()
        }
        .navigationTitle("活动")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadData() }
    }
}

// MARK: - 日期选择器

struct DatePickerHeader: View {
    let dateText: String
    let canGoBack: Bool
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Text("<")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(canGoBack ? Color.fitnessGreen : Color.watchTextSecondary)
            }
            .disabled(!canGoBack)
            .buttonStyle(.plain)

            Spacer()

            Text(dateText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onNext) {
                Text(">")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(canGoForward ? Color.fitnessGreen : Color.watchTextSecondary)
            }
            .disabled(!canGoForward)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - 统计摘要

struct StatsSummary: View {
    let count: Int
    let totalDuration: Int

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("COUNT")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.watchTextSecondary)
                Text("\(count) Activities")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.watchTextSecondary)
                Text(formatDuration(totalDuration))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .fill(Color.watchGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - 时间线区域

struct TimelineSection: View {
    let activities: [ActivityRecord]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 垂直时间线
            Rectangle()
                .fill(Color(hex: "3a3a3c"))
                .frame(width: 2)
                .offset(x: 7, y: 8)

            // 活动列表
            LazyVStack(spacing: 16) {
                ForEach(activities) { activity in
                    TimelineItem(activity: activity)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - 时间线项目

struct TimelineItem: View {
    let activity: ActivityRecord
    var category: ActivityCategory {
        ActivityCategory.from(tags: activity.tags)
    }
    var mood: Mood? {
        Mood.from(activity.mood)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线圆点 - 增大尺寸
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .offset(y: 4)

            // 内容区域
            VStack(alignment: .leading, spacing: 2) {
                // 标题和心情
                HStack(alignment: .top) {
                    Text(activity.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // 心情显示
                    if let mood = mood {
                        Text(mood.emoji)
                            .font(.system(size: 12))
                    }
                }

                // 标签列表
                if !activity.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(activity.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.watchTextSecondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.watchGray.opacity(0.8))
                                )
                        }
                    }
                }

                // 描述
                if let desc = activity.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.watchTextSecondary)
                        .lineLimit(1)
                }

                // 时间和时长
                HStack(alignment: .center) {
                    Text(formatTimeRange())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.watchTextSecondary)

                    Spacer()

                    // 持续时间 - 圆角badge和背景色
                    Text(formatDuration(activity.duration))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.durationBadgeBg)
                        )
                }
            }
        }
    }

    private func formatTimeRange() -> String {
        let start = formatTime(activity.startTime)
        let end = formatTime(activity.endTime)
        return "\(start) - \(end)"
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: isoString) {
            return formatter.string(from: date)
        }

        // 尝试解析其他可能的格式
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: isoString) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                return timeFormatter.string(from: date)
            }
        }

        // 如果都无法解析，尝试提取时间部分
        if let regex = try? NSRegularExpression(pattern: "(\\d{2}):(\\d{2})"),
           let match = regex.firstMatch(in: isoString, range: NSRange(isoString.startIndex..., in: isoString)),
           let hourRange = Range(match.range(at: 1), in: isoString),
           let minuteRange = Range(match.range(at: 2), in: isoString) {
            return "\(isoString[hourRange]):\(isoString[minuteRange])"
        }

        return isoString
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h" : "\(hours)h"
        }
    }
}

// MARK: - ViewModel

@MainActor
class ActivityListViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var activities: [ActivityRecord] = []
    @Published var isLoading = false
    @Published var error: String?

    private let calendar = Calendar.current
    private let maxDaysBack = 30

    var dateText: String {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)

        if selected == today {
            return "今天"
        } else if selected == calendar.date(byAdding: .day, value: -1, to: today)! {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_Hans")
            return formatter.string(from: selectedDate)
        }
    }

    var totalDuration: Int {
        activities.reduce(0) { $0 + $1.duration }
    }

    var canGoBack: Bool {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        let daysBack = calendar.dateComponents([.day], from: selected, to: today).day ?? 0
        return daysBack < maxDaysBack
    }

    var canGoForward: Bool {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }

    func previousDay() {
        guard canGoBack else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
        Task { await loadData() }
    }

    func nextDay() {
        guard canGoForward else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
        Task { await loadData() }
    }

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: selectedDate)

            let fetchedActivities = try await WCSessionManager.shared.getActivityData(date: dateString)

            // 按开始时间排序
            activities = fetchedActivities.sorted { activity1, activity2 in
                return activity1.startTime < activity2.startTime
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ActivityListView()
    }
}
