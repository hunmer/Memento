//
//  NotesListView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct NotesListView: View {
    @StateObject private var viewModel = NotesListViewModel()

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
            } else if viewModel.notes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无笔记")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.notes) { note in
                            NoteCardView(note: note)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("笔记")
        .task { await viewModel.loadData() }
    }
}

struct NoteCardView: View {
    let note: NoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题和文件夹图标
            HStack(alignment: .top) {
                Text(note.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // 文件夹图标
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundColor(note.neonColor)
                    .padding(4)
                    .background(note.neonColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // 更新时间和预览
            HStack(spacing: 4) {
                Text(note.formattedUpdateTime)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            Text(note.contentPreview)
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .lineLimit(1)

            // 标签
            if !note.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(note.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(note.neonColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(note.neonColor.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(note.neonColor.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    if note.tags.count > 2 {
                        Text("+\(note.tags.count - 2)")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(note.neonColor.opacity(0.3), lineWidth: 1)
        )
    }
}

@MainActor
class NotesListViewModel: ObservableObject {
    @Published var notes: [NoteItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            notes = try await WCSessionManager.shared.getNotes()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        NotesListView()
    }
}
