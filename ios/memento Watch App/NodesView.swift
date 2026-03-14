//
//  NodesView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

struct NodesView: View {
    @StateObject private var viewModel = NodesViewModel()
    let notebook: NodesNotebook

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
                        Task { await viewModel.loadData(notebookId: notebook.id) }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.nodes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无节点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.nodes) { node in
                            if node.hasChildren {
                                NavigationLink(destination: NodesDetailView(notebook: notebook, nodeId: node.id)) {
                                    NodeRowView(note: node)
                                }
                            } else {
                                NodeRowView(note: node)
                            }
                        }
                    }
                }
                .navigationTitle(notebook.title)
            }
        }
        .task { await viewModel.loadData(notebookId: notebook.id) }
    }
}

/// 节点行组件
struct NodeRowView: View {
    let note: NodeItem

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 图标和颜色
            ZStack {
                Circle()
                    .fill(note.nodeColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: iconName(for: Int32(note.status)))
                    .font(.title3)
                    .foregroundStyle(note.nodeColor)
            }

            // 标题
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // 笔记预览
                if let notes = note.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }

            Spacer()

            // 状态徽章
            if note.status != 3 {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(note.statusColor)
            }

            // 子节点指示器
            if note.hasChildren {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(note.nodeColor)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// 根据状态返回图标名称
private func iconName(for status: Int32) -> String {
    switch status {
    case 0: return "circle"
    case 1: return "checkmark.circle"
    case 2: return "ellipsis.circle"
    default: return "circle.dotted"
    }
}

/// 节点详情视图
struct NodesDetailView: View {
    @StateObject private var viewModel = NodesDetailViewModel()
    let notebook: NodesNotebook
    let nodeId: String

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
                        Task { await viewModel.loadData(notebookId: notebook.id, nodeId: nodeId) }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.nodes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无子节点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.nodes) { node in
                            if node.hasChildren {
                                NavigationLink(destination: NodesDetailView(notebook: notebook, nodeId: node.id)) {
                                    NodeRowView(note: node)
                                }
                            } else {
                                NodeRowView(note: node)
                            }
                        }
                    }
                }
                .navigationTitle("子节点")
            }
        }
        .task { await viewModel.loadData(notebookId: notebook.id, nodeId: nodeId) }
    }
}

/// 视图模型
@MainActor
class NodesViewModel: ObservableObject {
    @Published var nodes: [NodeItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData(notebookId: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            nodes = try await WCSessionManager.shared.getNodes(notebookId: notebookId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

/// 详情视图模型
@MainActor
class NodesDetailViewModel: ObservableObject {
    @Published var nodes: [NodeItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData(notebookId: String, nodeId: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            // 获取所有节点，然后过滤出子节点
            let allNodes = try await WCSessionManager.shared.getNodes(notebookId: notebookId)
            // TODO: 实现子节点过滤逻辑
            nodes = allNodes
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        NodesView(notebook: NodesNotebook(
            id: "1",
            title: "笔记本 1",
            icon: 0,
            color: 0x0a84ff,
            nodeCount: 5
        ))
    }
}
