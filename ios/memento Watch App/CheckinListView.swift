//
//  CheckinListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/12.
//

import SwiftUI
import Combine

struct CheckinListView: View {
    @StateObject private var viewModel = CheckinListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack {
                    Text(error)
                    Button("重试") { Task { await viewModel.loadData() } }
                }
            } else if viewModel.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("暂无打卡项目")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            CheckinItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("打卡")
        .task { await viewModel.loadData() }
    }
}

struct CheckinItemRow: View {
    let item: CheckinItem

    private var itemColor: Color {
        Color(red: Double((item.color >> 16) & 0xFF) / 255.0,
              green: Double((item.color >> 8) & 0xFF) / 255.0,
              blue: Double(item.color & 0xFF) / 255.0)
    }

    private var neonColor: Color {
        Color(red: min(1.0, Double((item.color >> 16) & 0xFF) / 255.0 * 1.2 + 0.2),
              green: min(1.0, Double((item.color >> 8) & 0xFF) / 255.0 * 1.2 + 0.2),
              blue: min(1.0, Double(item.color & 0xFF) / 255.0 * 1.2 + 0.2))
    }

    private var iconName: String {
        // 根据 icon codePoint 映射到 SF Symbols
        switch item.icon {
        case 0xe518: return "water_drop"      // Icons.wb_sunny
        case 0xe566: return "self_improvement" // Icons.directions_run
        case 0xe3ff: return "fitness_center"  // Icons.menu_book
        case 0xe1b7: return "local_drink"     // Icons.local_drink
        case 0xe1ac: return "book"            // Icons.book
        case 0xe52f: return "workout"         // Icons.fitness_center
        case 0xe3e8: return "self_improvement" // Icons.self_improvement
        default: return "star.fill"
        }
    }

    // 获取当前日期的日（1-31）
    private var currentDay: String {
        String(Calendar.current.component(.day, from: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(neonColor)

                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                Spacer()

                if let lastTime = item.lastCheckinTime {
                    Text(lastTime)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            // Week days - 小方块显示日期数字
            HStack(spacing: 3) {
                ForEach(item.weekDays.indices, id: \.self) { index in
                    let dayInfo = item.weekDays[index]
                    let isToday = dayInfo.day == currentDay
                    let isChecked = dayInfo.checked

                    Text(dayInfo.day)
                        .font(.system(size: 8, weight: isToday ? .bold : .medium))
                        .foregroundStyle(
                            isChecked
                                ? .white
                                : (isToday ? .primary : .secondary)
                        )
                        .frame(width: 18, height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    isChecked
                                        ? itemColor
                                        : (isToday ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(
                                    isToday ? neonColor : .clear,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isChecked ? itemColor.opacity(0.4) : .clear,
                            radius: 1
                        )
                }

                Spacer()

                // Checkin button
                Button {
                    // TODO: 快速打卡功能
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(itemColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

@MainActor
class CheckinListViewModel: ObservableObject {
    @Published var items: [CheckinItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            items = try await WCSessionManager.shared.getCheckinItems()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        CheckinListView()
    }
}
