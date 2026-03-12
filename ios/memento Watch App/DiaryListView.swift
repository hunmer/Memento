//
//  DiaryListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/12.
//

import SwiftUI
import Combine

struct DiaryListView: View {
    @StateObject private var viewModel = DiaryListViewModel()

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
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无日记")
                        .font(.headline)
                    Text("本月还没有日记记录\n在 iPhone 上写日记后会同步到这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(viewModel.entries) { entry in
                    NavigationLink(destination: DiaryDetailView(entry: entry)) {
                        DiaryEntryRow(entry: entry)
                    }
                }
                .refreshable {
                    await viewModel.loadEntries()
                }
            }
        }
        .navigationTitle("日记")
        .task {
            await viewModel.loadEntries()
        }
    }
}

struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 日期和心情
            HStack {
                Text(formatDate(entry.date))
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if let mood = entry.mood, !mood.isEmpty {
                    Text(mood)
                        .font(.title3)
                }
            }

            // 标题（如果有）
            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            // 内容预览
            Text(entry.contentPreview)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // 字数和时间
            HStack {
                Text("\(entry.wordCount) 字")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatTime(entry.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM月dd日"
            return formatter.string(from: date)
        }
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        return displayFormatter.string(from: date)
    }
}

@MainActor
class DiaryListViewModel: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            entries = try await WCSessionManager.shared.getDiaryEntries()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - 日记详情视图

struct DiaryDetailView: View {
    let entry: DiaryEntry
    @State private var detail: DiaryEntryDetail?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        loadDetail()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let detail = detail {
                VStack(alignment: .leading, spacing: 12) {
                    // 日期和心情
                    HStack {
                        Text(formatDate(detail.date))
                            .font(.headline)

                        Spacer()

                        if let mood = detail.mood, !mood.isEmpty {
                            Text(mood)
                                .font(.title2)
                        }
                    }

                    // 标题
                    if !detail.title.isEmpty {
                        Text(detail.title)
                            .font(.headline)
                    }

                    Divider()

                    // 内容
                    Text(detail.content)
                        .font(.body)

                    Divider()

                    // 统计信息
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("字数")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(detail.wordCount)")
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("更新于")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatDateTime(detail.updatedAt))
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("日记详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDetail()
        }
    }

    private func loadDetail() {
        isLoading = true
        error = nil

        Task {
            do {
                detail = try await WCSessionManager.shared.getDiaryEntry(date: entry.date)
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM/dd HH:mm"
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        DiaryListView()
    }
}
