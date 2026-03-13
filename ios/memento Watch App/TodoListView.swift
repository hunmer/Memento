//
//  TodoListView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel = TodoListViewModel()

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
            } else if viewModel.tasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("暂无任务")
                        .font(.headline)
                    Text("所有任务都完成了！")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.tasks) { task in
                            TodoTaskCard(task: task)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .navigationTitle("待办事项")
        .task { await viewModel.loadData() }
    }
}

// MARK: - 任务卡片
struct TodoTaskCard: View {
    let task: TodoTaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 头部：复选框 + 标题
            HStack(spacing: 8) {
                // 复选框
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(task.isCompleted ? Color.green : quadrantColor, lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                // 标题和描述
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if let desc = task.taskDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            // 四象限标签
            HStack {
                Text(task.quadrant)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(quadrantColor.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundStyle(quadrantColor)

                Spacer()

                // 子任务进度
                if task.subtaskCount > 0 {
                    Text("\(task.completedSubtaskCount)/\(task.subtaskCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 标签
            if !task.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(task.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 20)
            }

            // 日期
            if task.dueDate != nil {
                Text(formatDateRange())
                    .font(.caption2)
                    .foregroundStyle(quadrantColor)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(quadrantColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // 计算四象限颜色
    private var quadrantColor: Color {
        switch task.priority {
        case 0: return .red      // Q1: 紧急
        case 1: return .green    // Q2: 重要
        case 2: return .orange   // Q3: 一般
        case 3: return .blue     // Q4: 低优
        default: return .gray
        }
    }

    // 格式化日期范围
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "zh_CN")

        var result = ""
        if let start = task.startDate, let startDate = isoFormatter.date(from: start) {
            result = formatter.string(from: startDate)
        }
        if let due = task.dueDate, let dueDate = isoFormatter.date(from: due) {
            if !result.isEmpty {
                result += " - "
            }
            result += formatter.string(from: dueDate)
        }
        return result
    }

    private var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}

// MARK: - ViewModel
@MainActor
class TodoListViewModel: ObservableObject {
    @Published var tasks: [TodoTaskItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            tasks = try await WCSessionManager.shared.getTodoTasks()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        TodoListView()
    }
}
