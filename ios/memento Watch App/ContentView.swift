//
//  ContentView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

enum CardDestination: String {
    case todo = "待办事项"
    case chat = "频道聊天"
    case diary = "日记"
    case activity = "活动"
    case health = "健康数据"
    case weather = "天气"
    case calendar = "日程"
    case reminder = "提醒"
    case checkin = "打卡"
    case contacts = "联系人"
    case settings = "设置"
}

struct DemoCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: CardDestination
}

struct ContentView: View {
    private let demoCards = [
        DemoCard(title: "待办事项", subtitle: "2个任务", icon: "checkmark.circle", color: .blue, destination: .todo),
        DemoCard(title: "频道聊天", subtitle: "消息频道", icon: "message.fill", color: .indigo, destination: .chat),
        DemoCard(title: "日记", subtitle: "今日记录", icon: "book.fill", color: .purple, destination: .diary),
        DemoCard(title: "活动", subtitle: "时间记录", icon: "stopwatch", color: .pink, destination: .activity),
        // DemoCard(title: "健康数据", subtitle: "今日步数", icon: "heart.fill", color: .red, destination: .health),
        // DemoCard(title: "天气", subtitle: "晴朗 23°C", icon: "sun.max.fill", color: .orange, destination: .weather),
        // DemoCard(title: "日程", subtitle: "2个会议", icon: "calendar", color: .green, destination: .calendar),
        DemoCard(title: "打卡", subtitle: "习惯养成", icon: "checkmark.circle.fill", color: .teal, destination: .checkin),
        DemoCard(title: "联系人", subtitle: "通讯录", icon: "person.2.fill", color: .cyan, destination: .contacts),
        // DemoCard(title: "提醒", subtitle: "1个提醒", icon: "bell.fill", color: .purple, destination: .reminder),
        // DemoCard(title: "设置", subtitle: "偏好设置", icon: "gear", color: .gray, destination: .settings)
    ]

    @ViewBuilder
    private func destinationView(for card: DemoCard) -> some View {
        switch card.destination {
        case .todo:
            TodoListView()
        case .chat:
            ChatChannelView()
        case .diary:
            DiaryListView()
        case .activity:
            ActivityListView()
        case .health:
            HealthDataView()
        case .weather:
            PlaceholderView(title: card.title, icon: card.icon, color: card.color)
        case .calendar:
            PlaceholderView(title: card.title, icon: card.icon, color: card.color)
        case .checkin:
            CheckinListView()
        case .contacts:
            ContactListView()
        case .reminder:
            PlaceholderView(title: card.title, icon: card.icon, color: card.color)
        case .settings:
            PlaceholderView(title: card.title, icon: card.icon, color: card.color)
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(demoCards) { card in
                    NavigationLink(destination: destinationView(for: card)) {
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
                    .buttonStyle(.borderless)
                }
            }
            .padding()
        }
        .navigationTitle("Demo 展示")
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}

// 占位视图 - 用于尚未实现的功能
struct PlaceholderView: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.headline)

            Text("功能开发中...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(title)
    }
}
