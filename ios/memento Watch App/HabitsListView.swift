//
//  HabitsListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/13.
//

import SwiftUI
import Combine

struct HabitsListView: View {
    @StateObject private var viewModel = HabitsListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task { await viewModel.loadData() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.habits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("暂无习惯")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("请在手机上添加习惯")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.habits) { habit in
                            HabitItemRow(habit: habit)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("习惯")
        .task { await viewModel.loadData() }
    }
}

// MARK: - 习惯卡片组件

struct HabitItemRow: View {
    let habit: HabitItem

    // 根据技能颜色值生成 SwiftUI Color
    private var skillColor: Color {
        Color(
            red: Double((habit.skillColor >> 16) & 0xFF) / 255.0,
            green: Double((habit.skillColor >> 8) & 0xFF) / 255.0,
            blue: Double(habit.skillColor & 0xFF) / 255.0
        )
    }

    // 霓虹发光版本的颜色
    private var neonColor: Color {
        Color(
            red: min(1.0, Double((habit.skillColor >> 16) & 0xFF) / 255.0 * 1.2 + 0.2),
            green: min(1.0, Double((habit.skillColor >> 8) & 0xFF) / 255.0 * 1.2 + 0.2),
            blue: min(1.0, Double(habit.skillColor & 0xFF) / 255.0 * 1.2 + 0.2)
        )
    }

    // 计算进度百分比
    private var progress: Double {
        guard habit.targetMinutes > 0 else { return 0 }
        return min(Double(habit.todayMinutes) / Double(habit.targetMinutes), 1.0)
    }

    // 根据图标 codePoint 映射到 SF Symbols
    private var iconName: String {
        // 默认图标映射
        guard let iconStr = habit.icon else { return "star.fill" }

        // 检查是否是数字（codePoint）
        if let codePoint = Int(iconStr) {
            switch codePoint {
            case 0xe3ff: return "figure.run"          // 运动相关
            case 0xe3e8: return "brain.head.profile"  // 冥想/心理
            case 0xe1ac: return "book.fill"           // 阅读
            case 0xe566: return "figure.walk"         // 健身
            case 0xe518: return "sun.max.fill"        // 早起
            case 0xe1b7: return "drop.fill"           // 喝水
            case 0xe52f: return "dumbbell.fill"       // 健身房
            case 0xe25b: return "pencil"              // 写作
            case 0xe3af: return "music.note"          // 音乐
            case 0xe0e7: return "bed.double.fill"     // 睡眠
            default: return "star.fill"
            }
        }

        // 如果不是数字，直接返回
        return "star.fill"
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左侧霓虹色条
            skillColor
                .frame(width: 3)

            // 主要内容
            VStack(alignment: .leading, spacing: 6) {
                // 顶部：图标、标题、时长
                HStack(spacing: 6) {
                    // 图标容器
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(skillColor.opacity(0.2))
                            .frame(width: 28, height: 28)

                        Image(systemName: iconName)
                            .font(.system(size: 13))
                            .foregroundStyle(neonColor)
                    }

                    // 标题和技能名
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(.white)

                        Text(habit.skillName.uppercased())
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(neonColor.opacity(0.6))
                    }

                    Spacer()

                    // 今日进度
                    HStack(spacing: 4) {
                        Text(formatDuration(habit.todayMinutes, target: habit.targetMinutes))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)

                        // 播放按钮
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(neonColor)
                    }
                }

                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 1)
                            .fill(skillColor)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 3)
                .padding(.vertical, 2)

                // 周热力图
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.white.opacity(0.3))

                    // 7 天热力图方块
                    ForEach(0..<7, id: \.self) { index in
                        let minutes = habit.dailyMinutes.indices.contains(index) ? habit.dailyMinutes[index] : 0
                        let hasActivity = minutes > 0
                        let isToday = index == (Calendar.current.component(.weekday, from: Date()) - 1 + 7) % 7

                        ZStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(hasActivity ? skillColor : skillColor.opacity(0.2))
                                .frame(width: 16, height: 16)

                            // 显示日期数字
                            Text("\(index + 1)")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundStyle(hasActivity ? .black : .white.opacity(0.4))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isToday ? neonColor : .clear, lineWidth: 1)
                        )
                        .shadow(
                            color: hasActivity ? skillColor.opacity(0.4) : .clear,
                            radius: 1
                        )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(skillColor.opacity(0.3), lineWidth: 0.5)
        )
    }

    // 格式化时长显示
    private func formatDuration(_ minutes: Int, target: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        let targetHours = target / 60
        let targetMins = target % 60

        if targetHours > 0 {
            if hours > 0 {
                return "\(hours)h/\(targetHours)h"
            } else {
                return "\(mins)m/\(targetHours)h"
            }
        } else {
            return "\(mins)m/\(targetMins)m"
        }
    }
}

// MARK: - ViewModel

@MainActor
class HabitsListViewModel: ObservableObject {
    @Published var habits: [HabitItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            habits = try await WCSessionManager.shared.getHabits()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        HabitsListView()
    }
}
