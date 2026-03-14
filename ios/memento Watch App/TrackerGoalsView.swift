//
//  TrackerGoalsView.swift
//  memento Watch App
//
//  目标追踪 watchOS 视图
//

import SwiftUI
import Combine

struct TrackerGoalsView: View {
    @StateObject private var viewModel = TrackerGoalsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .foregroundStyle(.secondary)
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task { await viewModel.loadData() }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            } else if viewModel.goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无目标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.goals) { goal in
                            TrackerGoalCard(goal: goal)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadData() }
    }
}

// MARK: - 目标卡片组件

struct TrackerGoalCard: View {
    let goal: TrackerGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部：图标和名称
            HStack(spacing: 8) {
                // 图标容器
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(goal.neonColor.opacity(0.2))
                        .frame(width: 28, height: 28)

                    // 使用 SF Symbol 作为占位符图标
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(goal.neonColor)
                }

                Text(goal.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                // 快速操作按钮
                Button(action: {
                    // TODO: 快速记录功能
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(goal.neonColor)
                }
                .buttonStyle(.borderless)
            }

            // 进度信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.dateSettingsType == "daily" ? "Daily" : goal.dateSettingsType?.capitalized ?? "Progress")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(goal.progressText)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(goal.neonColor)
                }

                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)

                        // 进度条
                        RoundedRectangle(cornerRadius: 2)
                            .fill(goal.neonColor)
                            .frame(width: max(0, min(CGFloat(goal.progressPercent) / 100 * geometry.size.width, geometry.size.width)), height: 6)
                            .shadow(color: goal.neonColor.opacity(0.6), radius: 3)
                    }
                }
                .frame(height: 6)
            }

            // 本周完成情况
            if let dailyCompleted = goal.dailyCompleted, dailyCompleted.count == 7 {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        let dayLetter = weekDayLetter(for: index)
                        let isToday = index == (Calendar.current.component(.weekday, from: Date()) - 1 + 6) % 7

                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(dailyCompleted[index] ? goal.neonColor : (isToday ? goal.neonColor.opacity(0.3) : Color.gray.opacity(0.2)))
                                .frame(width: 18, height: 18)

                            Text(dayLetter)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(dailyCompleted[index] ? .black : (isToday ? goal.neonColor : .gray))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(goal.neonColor.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: goal.neonColor.opacity(0.3), radius: 4)
    }

    // 获取星期几字母
    private func weekDayLetter(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }

    // 根据目标名称获取 SF Symbol 图标名
    private var iconName: String {
        let name = goal.name.lowercased()

        if name.contains("步") || name.contains("walk") || name.contains("step") {
            return "figure.walk"
        } else if name.contains("跑") || name.contains("run") || name.contains("跑步") {
            return "figure.run"
        } else if name.contains("水") || name.contains("water") || name.contains("喝") {
            return "drop.fill"
        } else if name.contains("读") || name.contains("read") || name.contains("书") || name.contains("学习") {
            return "book.fill"
        } else if name.contains("运动") || name.contains("健身") || name.contains("exercise") || name.contains("gym") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("睡") || name.contains("sleep") || name.contains("休息") {
            return "bed.double.fill"
        } else if name.contains("冥想") || name.contains("meditation") {
            return "brain.head.profile"
        } else if name.contains("写") || name.contains("write") || name.contains("日记") {
            return "pencil.and.outline"
        } else if name.contains("吃") || name.contains("eat") || name.contains("餐") || name.contains("饭") {
            return "fork.knife"
        } else if name.contains("钱") || name.contains("money") || name.contains("省钱") {
            return "banknote.fill"
        } else {
            return "target"
        }
    }
}

// MARK: - ViewModel

@MainActor
class TrackerGoalsViewModel: ObservableObject {
    @Published var goals: [TrackerGoal] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            goals = try await WCSessionManager.shared.getTrackerGoals()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        TrackerGoalsView()
    }
}
