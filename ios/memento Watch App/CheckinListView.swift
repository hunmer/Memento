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
                    VStack(spacing: 8) {
                        ForEach(viewModel.items) { item in
                            CheckinItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 20)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(neonColor)

                Text(item.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)

                Spacer()

                if let lastTime = item.lastCheckinTime {
                    Text(lastTime)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            // Week days
            HStack(spacing: 4) {
                ForEach(item.weekDays.indices, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text(item.weekDays[index].day)
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(item.weekDays[index].checked ? itemColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 4)
                            .shadow(color: item.weekDays[index].checked ? itemColor.opacity(0.5) : .clear, radius: 2)
                    }
                }

                Spacer()

                // Add button
                Button {
                    // TODO: 快速打卡功能
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundStyle(itemColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
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
