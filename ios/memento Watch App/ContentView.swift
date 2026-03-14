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
    case calendarAlbum = "相册"
    case reminder = "提醒"
    case checkin = "打卡"
    case contacts = "联系人"
    case habits = "习惯"
    case timers = "计时器"
    case day = "纪念日"
    case tracker = "目标追踪"
    case billing = "账单"
    case notes = "笔记"
    case store = "商店"
    case goods = "物品"
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
        DemoCard(title: "日程", subtitle: "未来7天", icon: "calendar", color: .green, destination: .calendar),
        DemoCard(title: "相册", subtitle: "照片日记", icon: "photo.fill", color: Color(red: 245/255, green: 210/255, blue: 52/255), destination: .calendarAlbum),
        DemoCard(title: "打卡", subtitle: "习惯养成", icon: "checkmark.circle.fill", color: .teal, destination: .checkin),
        DemoCard(title: "习惯", subtitle: "追踪进度", icon: "figure.run", color: .green, destination: .habits),
        DemoCard(title: "联系人", subtitle: "通讯录", icon: "person.2.fill", color: .cyan, destination: .contacts),
        DemoCard(title: "计时器", subtitle: "时间管理", icon: "timer", color: .gray, destination: .timers),
        DemoCard(title: "纪念日", subtitle: "重要日期", icon: "heart.fill", color: .orange, destination: .day),
        DemoCard(title: "目标追踪", subtitle: "进度管理", icon: "target", color: Color(red: 0.22, green: 1.0, blue: 0.08), destination: .tracker),
        DemoCard(title: "账单", subtitle: "财务记录", icon: "wallet.pass", color: .green, destination: .billing),
        DemoCard(title: "笔记", subtitle: "快速笔记", icon: "note.text", color: Color(red: 0.0, green: 0.949, blue: 1.0), destination: .notes),
        DemoCard(title: "商店", subtitle: "物品兑换", icon: "storefront", color: Color(red: 236/255, green: 91/255, blue: 19/255), destination: .store),
        DemoCard(title: "物品", subtitle: "仓库管理", icon: "shippingbox", color: Color(red: 207/255, green: 77/255, blue: 116/255), destination: .goods),
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
            CalendarListView()
        case .calendarAlbum:
            CalendarAlbumListView()
        case .checkin:
            CheckinListView()
        case .contacts:
            ContactListView()
        case .habits:
            HabitsListView()
        case .timers:
            TimerListView()
        case .day:
            DayListView()
        case .tracker:
            TrackerGoalsView()
        case .billing:
            BillingListView()
        case .notes:
            NotesListView()
        case .store:
            StoreListView()
        case .goods:
            GoodsWarehouseListView()
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
