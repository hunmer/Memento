//
//  DayListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct DayListView: View {
    @StateObject private var viewModel = DayListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("加载失败")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task {
                            await viewModel.loadItems()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无纪念日")
                        .font(.headline)
                    Text("在 iPhone 上添加纪念日\n会同步到这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.items) { item in
                            DayItemCard(item: item)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .refreshable {
                    await viewModel.loadItems()
                }
            }
        }
        .navigationTitle("纪念日")
        .task {
            await viewModel.loadItems()
        }
    }
}

// MARK: - 纪念日卡片视图

struct DayItemCard: View {
    let item: DayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题和图标
            HStack {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(item.accentColor)
            }

            // 目标日期
            Text(formatDate(item.targetDate))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            // 状态标签
            HStack(spacing: 4) {
                Text(statusText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(item.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(item.accentColor.opacity(0.15))
                    )
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(item.accentColor.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: item.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }

    // 根据状态返回图标名称
    private var iconName: String {
        if item.isToday {
            return "star.fill"
        } else if item.isExpired {
            return "checkmark.circle.fill"
        } else if item.daysRemaining <= 7 {
            return "bell.fill"
        } else {
            return "calendar"
        }
    }

    // 状态文本
    private var statusText: String {
        if item.isToday {
            return "今天是纪念日"
        } else if item.isExpired {
            return "已过 \(-item.daysRemaining) 天"
        } else {
            return "还有 \(item.daysRemaining) 天"
        }
    }

    // 格式化日期
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel

@MainActor
class DayListViewModel: ObservableObject {
    @Published var items: [DayItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadItems() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            items = try await WCSessionManager.shared.getDayItems()
            // 按剩余天数排序（未过期的在前）
            items.sort { first, second in
                if first.isExpired == second.isExpired {
                    return first.daysRemaining < second.daysRemaining
                }
                return !first.isExpired && second.isExpired
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        DayListView()
    }
}
