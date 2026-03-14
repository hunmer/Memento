//
//  NodesNotebooksView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct NodesNotebooksView: View {
    @StateObject private var viewModel = NodesNotebooksViewModel()

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
            } else if viewModel.notebooks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无笔记本")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.notebooks) { notebook in
                            NavigationLink(destination: NodesView(notebook: notebook)) {
                                NotebookCardView(notebook: notebook)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("节点")
        .task { await viewModel.loadData() }
    }
}

struct NotebookCardView: View {
    let notebook: NodesNotebook

    var body: some View {
        HStack(spacing: 10) {
            // 图标
            ZStack {
                Circle()
                    .fill(notebook.notebookColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(notebook.notebookColor)
            }

            // 标题和信息
            VStack(alignment: .leading, spacing: 2) {
                Text(notebook.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text("\(notebook.nodeCount) 个节点")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

@MainActor
class NodesNotebooksViewModel: ObservableObject {
    @Published var notebooks: [NodesNotebook] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            notebooks = try await WCSessionManager.shared.getNodesNotebooks()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        NodesNotebooksView()
    }
}
