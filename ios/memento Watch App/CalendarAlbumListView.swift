//
//  CalendarAlbumListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct CalendarAlbumListView: View {
    @StateObject private var viewModel = CalendarAlbumListViewModel()

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
                            await viewModel.loadEntries()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无相册")
                        .font(.headline)
                    Text("本月还没有照片日记\n在 iPhone 上添加照片后会同步到这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 按日期分组显示
                        ForEach(viewModel.groupedEntries.keys.sorted(by: >), id: \.self) { dateKey in
                            if let entries = viewModel.groupedEntries[dateKey] {
                                // 日期分组标题
                                Text(formatDateHeader(dateKey))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                // 相册卡片
                                ForEach(entries) { entry in
                                    NavigationLink(destination: CalendarAlbumDetailView(entry: entry)) {
                                        AlbumEntryCard(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable {
                    await viewModel.loadEntries()
                }
            }
        }
        .navigationTitle("Albums")
        .task {
            await viewModel.loadEntries()
        }
    }

    private func formatDateHeader(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else {
            return dateKey
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 相册卡片组件

struct AlbumEntryCard: View {
    let entry: CalendarAlbumEntry

    // 从 neonBorderColor 整数创建 Color
    private var neonColor: Color {
        Color(
            red: Double((entry.neonBorderColor >> 16) & 0xFF) / 255.0,
            green: Double((entry.neonBorderColor >> 8) & 0xFF) / 255.0,
            blue: Double(entry.neonBorderColor & 0xFF) / 255.0
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title.isEmpty ? "无标题" : entry.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    Text(entry.dateStr)
                        .font(.caption2)
                        .foregroundStyle(neonColor.opacity(0.8))
                }

                Spacer()

                // 心情表情
                if let mood = entry.mood, !mood.isEmpty {
                    Text(mood)
                        .font(.body)
                }
            }

            // 图片数量指示
            HStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.caption2)
                    .foregroundStyle(neonColor)

                Text("\(entry.imageCount)")
                    .font(.caption)
                    .fontWeight(.medium)

                if let wordCount = entry.wordCount, wordCount > 0 {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(wordCount)字")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 位置信息
            if let location = entry.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(neonColor)
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // 标签
            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(neonColor.opacity(0.2))
                            .foregroundColor(neonColor)
                            .cornerRadius(4)
                    }
                    if entry.tags.count > 3 {
                        Text("+\(entry.tags.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(neonColor, lineWidth: 2)
                        .opacity(0.5)
                )
        )
        .shadow(color: neonColor.opacity(0.1), radius: 4)
    }
}

// MARK: - 视图模型

@MainActor
class CalendarAlbumListViewModel: ObservableObject {
    @Published var entries: [CalendarAlbumEntry] = []
    @Published var groupedEntries: [String: [CalendarAlbumEntry]] = [:]
    @Published var isLoading = false
    @Published var error: String?

    func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            entries = try await WCSessionManager.shared.getCalendarAlbumEntries()
            // 按日期分组
            groupEntriesByDate()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func groupEntriesByDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: [CalendarAlbumEntry]] = [:]
        for entry in entries {
            // 从 createdAt 提取日期
            let isoFormatter = ISO8601DateFormatter()
            guard let date = isoFormatter.date(from: entry.createdAt) else { continue }
            let dateKey = formatter.string(from: date)
            grouped[dateKey, default: []].append(entry)
        }
        groupedEntries = grouped
    }
}

// MARK: - 相册详情视图

struct CalendarAlbumDetailView: View {
    let entry: CalendarAlbumEntry

    // 从 neonBorderColor 整数创建 Color
    private var neonColor: Color {
        Color(
            red: Double((entry.neonBorderColor >> 16) & 0xFF) / 255.0,
            green: Double((entry.neonBorderColor >> 8) & 0xFF) / 255.0,
            blue: Double(entry.neonBorderColor & 0xFF) / 255.0
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题和日期
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title.isEmpty ? "无标题" : entry.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    HStack {
                        Text(entry.dateStr)
                            .font(.caption)
                            .foregroundStyle(neonColor)

                        if let timeStr = entry.timeStr {
                            Text(timeStr)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let mood = entry.mood, !mood.isEmpty {
                        Text("心情: \(mood)")
                            .font(.caption)
                    }
                }

                Divider()

                // 图片数量
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("照片")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(entry.imageCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(neonColor)
                    }

                    Spacer()

                    if let wordCount = entry.wordCount {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("字数")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(wordCount)")
                                .font(.headline)
                        }
                    }
                }

                Divider()

                // 位置
                if let location = entry.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(neonColor)
                        Text(location)
                            .font(.body)
                    }
                }

                // 天气
                if let weather = entry.weather, !weather.isEmpty {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(neonColor)
                        Text(weather)
                            .font(.body)
                    }
                }

                // 标签
                if !entry.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 6) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(neonColor.opacity(0.2))
                                    .foregroundColor(neonColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Divider()

                // 内容预览
                if !entry.contentPreview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(entry.contentPreview)
                            .font(.body)
                            .lineLimit(nil)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("相册详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationView {
        CalendarAlbumListView()
    }
}
