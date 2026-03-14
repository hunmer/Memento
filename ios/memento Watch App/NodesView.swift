//
//  NodesView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI

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
                        Task { await viewModel.loadData()
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
                                NavigationLink(destination: NodesDetailView(notebook: notebook,, nodeId: node.id,
                            }) {
                                NodeRowView(note: node)
                        }
                    }
                }
                .navigationTitle(notebook.title)
                .task { await viewModel.loadData(notebookId: notebook.id }
            }
        }
    }
}

struct NodesNotebook: Identifiable, Hashable {
    let notebook: NodesNotebook
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // 图标和颜色
            ZStack {
                Circle()
                    .fill(notebook.notebookColor.opacity(0.2)
                    .frame(width: 28, height: 28)
                Image(systemName: notebook.icon)
                    .font(.title3)
                    .foregroundStyle(notebook.notebookColor)
            }

            // 标题
            Text(notebook.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            // 节点数量
            HStack(spacing: 2) {
                Text("\(notebook.nodeCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 猉和标签
                HStack(spacing: 2) {
                    ForEach(notebook.tags.prefix(2), id: \.hash) { tag in
                        Text(tag)
                            .font(.system(size: 8, weight: .medium)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(notebook.neonColor.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(notebook.neonColor.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }

                    // 笔记预览（最多显示前3行)
                    if note.notes.isEmpty {
                        Text(note.notes)
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationView {
        NodesView(notebook: NodesNotebook(title: "笔记本 1", icon: notebook.icon, color: notebook.notebookColor)
                .frame(width: 28, height: 28)
            }

            // 标题
            Text(node.title)
                .font(.caption)
                    .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }

            // 状态徽章
            if node.status != 3 { // none
                HStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(node.statusColor.opacity(0.15)
                        .frame(width: 20, height: 20)
                    Image(systemName: "circle")
                        .font(.system(size: 10, weight: .medium)
                        .foregroundColor(node.statusColor)

                    Text(node.statusText)
                        .font(.system(size: 8, weight: .medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                    if node.hasChildren {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold)
                            .foregroundColor(node.nodeColor)
                            .frame(width: 12, height: 12) {
                                Circle()
                                    .fill(node.statusColor.opacity(0.15))
                                    .frame(width: 8, height: 8)
                                Image(systemName: statusIcon)
                                    .font(.system(size: 10))
                                    .foregroundColor(node.statusColor)
                                Text(node.statusText)
                                    .font(.caption)
                                    .foregroundStyle(node.statusColor)
                            }
                        }
                    }

                    // 缩进显示
                    if note.notes.isNotEmpty {
                        Text(note.notes)
                            .font(.system(size: 8, weight: .regular)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

struct NodesDetailView: View {
    let node: NodeItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // 顶部导航栏
                HStack {
                    Button {
                        NavigationLink(destination: NodesView(notebook: notebook)) {
                        label("返回")
                            }
                    })

                    // 节点列表（仅显示前5个节点)
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.nodes.prefix(5)) { node in
                            NodeCardView(node: node)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .navigationTitle(notebook.title)
            .task { await viewModel.loadData(notebookId: notebook.id }
        }
    }
}

struct NodeCardView: View {
    let node: NodeItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 图标和颜色
            ZStack {
                Circle()
                    .fill(node.nodeColor.opacity(0.15)
                    .frame(width: 22, height: 22)

                Image(systemName: _getStatusIcon(node.status))
                    .font(.title3)
                    .foregroundColor(node.nodeColor)

                Text(node.title)
                    .font(.system(size: 14, weight: .bold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                // 焦标签
                HStack(spacing: 4) {
                    ForEach(node.tags.prefix(2), id: \.hash) { tag in
                        Text(tag)
                            .font(.system(size: 7, weight: .medium)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(node.neonColor.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(node.neonColor.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

@MainActor
class NodesViewModel: ObservableObject {
    @Published var nodes: [NodeItem] = []
    @Published var isLoading = false
    @Published var error: String?

    let notebook: NodesNotebook?

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

#Preview {
    NavigationView {
        NodesView(notebook: NodesNotebook(title: "笔记本 1", icon: notebook.icon, color: notebook.notebookColor)
            )
        }
    }
}
