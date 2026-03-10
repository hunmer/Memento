//
//  TodoListView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

struct TodoListView: View {
    @State private var todoItems = [
        TodoItem(title: "完成项目报告", isCompleted: false),
        TodoItem(title: "团队会议", isCompleted: true),
        TodoItem(title: "代码审查", isCompleted: false)
    ]

    var body: some View {
        List {
            ForEach($todoItems) { $item in
                Toggle(isOn: $item.isCompleted) {
                    Text(item.title)
                        .strikethrough(item.isCompleted)
                }
                .toggleStyle(.switch)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("待办事项")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: addNewItem) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        todoItems.remove(atOffsets: offsets)
    }

    private func addNewItem() {
        todoItems.append(TodoItem(title: "新任务", isCompleted: false))
    }
}

#Preview {
    NavigationView {
        TodoListView()
    }
}
