//
//  TodoListView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct TodoListView: View {
    var body: some View {
        List {
            TodoItem(title: "完成项目文档", isDone: false)
            TodoItem(title: "代码审查", isDone: true)
            TodoItem(title: "团队会议", isDone: false)
        }
        .navigationTitle("待办事项")
    }
}

struct TodoItem: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .gray)
            Text(title)
                .strikethrough(isDone)
        }
    }
}

#Preview {
    NavigationView {
        TodoListView()
    }
}
