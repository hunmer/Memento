//
//  TimerListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/13.
//

import SwiftUI

/// 计时器列表视图
struct TimerListView: View {
    @StateObject private var viewModel = TimerListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button("重试") {
                        Task { await viewModel.loadTimers() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.timers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.largeTitle)
                        .foregroundStyle(.blueGrey)

                    Text("暂无计时器")
                        .font(.headline)

                    Text("请在手机上添加计时器")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(viewModel.timers) { timer in
                    NavigationLink(destination: TimerDetailView(timer: timer)) {
                        TimerRowView(timer: timer)
                    }
                }
                .listStyle(.carousel)
                .refreshable {
                    await viewModel.loadTimers()
                }
            }
        }
        .navigationTitle("计时器")
        .task {
            await viewModel.loadTimers()
        }
    }
}

/// 计时器行视图
struct TimerRowView: View {
    let timer: TimerTaskItem

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(timer.color).opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: getIconName(timer.icon))
                    .font(.system(size: 16))
                    .foregroundStyle(Color(timer.color))
            }

            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    // 状态指示
                    if timer.isRunning {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("运行中")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else if timer.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("已完成")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatTimerCount(timer.timerItems.count))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // 显示活动计时器
                if let activeId = timer.activeTimerId,
                   let activeTimer = timer.timerItems.first(where: { $0.id == activeId }) {
                    Text(formatTime(activeTimer.completedDuration))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(timer.color))
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func getIconName(_ codePoint: Int) -> String {
        // 常用图标映射
        switch codePoint {
        case 58223: return "timer"
        case 58224: return "timer"
        case 57853: return "hourglass"
        case 57854: return "hourglass"
        case 58334: return "cup.and.saucer.fill"
        default: return "timer"
        }
    }

    private func formatTimerCount(_ count: Int) -> String {
        return "\(count)个计时器"
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

/// 计时器详情视图
struct TimerDetailView: View {
    let timer: TimerTaskItem

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头部信息
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(timer.color).opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: getIconName(timer.icon))
                            .font(.title)
                            .foregroundStyle(Color(timer.color))
                    }

                    Text(timer.name)
                        .font(.headline)

                    // 状态标签
                    HStack(spacing: 8) {
                        if timer.isRunning {
                            Label("运行中", systemImage: "play.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if timer.isCompleted {
                            Label("已完成", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("待运行", systemImage: "pause.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if timer.repeatCount > 1 {
                            Label("×\(timer.repeatCount)", systemImage: "repeat")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Divider()

                // 计时器列表
                VStack(spacing: 12) {
                    ForEach(timer.timerItems) { item in
                        TimerItemCard(item: item, color: Color(timer.color))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(timer.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func getIconName(_ codePoint: Int) -> String {
        switch codePoint {
        case 58223, 58224: return "timer"
        case 57853, 57854: return "hourglass"
        case 58334: return "cup.and.saucer.fill"
        default: return "timer"
        }
    }
}

/// 计时器项卡片
struct TimerItemCard: View {
    let item: TimerSubItem
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部：名称和类型
            HStack {
                Label(item.name, systemImage: getTimerTypeIcon(item.type))
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                if item.isRunning {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                } else if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // 时间显示
            HStack {
                if item.type == 1 { // 倒计时
                    Text(formatTime(max(0, item.duration - item.completedDuration)))
                        .font(.system(size: 20, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTime(item.completedDuration))
                            .font(.system(size: 20, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(color)

                        Text("/ \(formatTime(item.duration))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 进度条
            if item.duration > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: min(CGFloat(item.completedDuration) / CGFloat(item.duration) * geometry.size.width, geometry.size.width), height: 4)
                    }
                }
                .frame(height: 4)
            }

            // 番茄钟信息
            if item.type == 2, let cycles = item.cycles, let currentCycle = item.currentCycle {
                HStack(spacing: 4) {
                    if let isWorkPhase = item.isWorkPhase {
                        Text(isWorkPhase ? "工作" : "休息")
                            .font(.caption2)
                            .foregroundStyle(isWorkPhase ? .red : .green)
                    }

                    Text("循环 \(currentCycle)/\(cycles)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    private func getTimerTypeIcon(_ type: Int) -> String {
        switch type {
        case 0: return "arrow.up"
        case 1: return "arrow.down"
        case 2: return "cup.and.saucer.fill"
        default: return "timer"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

/// 计时器列表视图模型
@MainActor
class TimerListViewModel: ObservableObject {
    @Published var timers: [TimerTaskItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadTimers() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            timers = try await WCSessionManager.shared.getTimers()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        TimerListView()
    }
}
