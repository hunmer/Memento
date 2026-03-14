//
//  CalendarListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct CalendarListView: View {
    @StateObject private var viewModel = CalendarListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .scaledToFit()
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
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
                        Task { await viewModel.loadData() }
                    }
                    .buttonStyle(.borderless)
                }
            } else if viewModel.events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("暂无日程")
                        .font(.headline)
                    Text("未来7天没有安排")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.events) { event in
                            CalendarEventCard(event: event)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .navigationTitle("日程")
        .task { await viewModel.loadData() }
    }
}

// MARK: - 事件卡片
struct CalendarEventCard: View {
    let event: CalendarEventItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 头部：复选框 + 标题
            HStack(spacing: 8) {
                // 复选框样式装饰
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(event.neonColor, lineWidth: 1.5)
                        .frame(width: 20, height: 20)

                    // 空心框，仅作装饰
                }

                // 标题和时间
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(event.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Spacer()

                        Text(event.startTimeStr)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(event.neonColor)
                    }

                    if let desc = event.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // 底部：创建日期和截止状态
            HStack {
                Text("Created: \(event.createdDate)")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Due: \(event.dateStatus)")
                    .font(.system(size: 8))
                    .fontWeight(.bold)
                    .foregroundStyle(event.neonColor)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(event.neonColor.opacity(0.5), lineWidth: 1)
                        .shadow(color: event.neonColor.opacity(0.3), radius: 2, x: 0, y: 0)
                )
        )
    }
}

// MARK: - ViewModel
@MainActor
class CalendarListViewModel: ObservableObject {
    @Published var events: [CalendarEventItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            events = try await WCSessionManager.shared.getCalendarEvents()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        CalendarListView()
    }
}
