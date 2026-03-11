//
//  ContentView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct DemoCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct ContentView: View {
    private let demoCards = [
        DemoCard(title: "待办事项", subtitle: "2个任务", icon: "checkmark.circle", color: .blue),
        DemoCard(title: "频道聊天", subtitle: "消息频道", icon: "message.fill", color: .indigo),
        DemoCard(title: "健康数据", subtitle: "今日步数", icon: "heart.fill", color: .red),
        DemoCard(title: "天气", subtitle: "晴朗 23°C", icon: "sun.max.fill", color: .orange),
        DemoCard(title: "日程", subtitle: "2个会议", icon: "calendar", color: .green),
        DemoCard(title: "提醒", subtitle: "1个提醒", icon: "bell.fill", color: .purple),
        DemoCard(title: "设置", subtitle: "偏好设置", icon: "gear", color: .gray)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(demoCards) { card in
                    NavigationLink {
                        destinationView(for: card.title)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(card.color.opacity(0.2))
                                    .frame(width: 50, height: 50)

                                Image(systemName: card.icon)
                                    .font(.title2)
                                    .foregroundStyle(card.color)
                            }

                            Text(card.title)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(card.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Demo 展示")
    }

    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "待办事项":
            TodoListView()
        case "频道聊天":
            ChatChannelView()
        case "健康数据":
            HealthDataView()
        default:
            Text("功能开发中...")
                .navigationTitle(title)
        }
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}
