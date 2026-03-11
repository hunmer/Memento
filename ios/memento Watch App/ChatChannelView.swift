//
//  ChatChannelView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct ChatChannelView: View {
    private let channels = [
        Channel(name: "项目讨论", lastMessage: "进度怎么样？", time: "10:30", unread: 2),
        Channel(name: "日常闲聊", lastMessage: "今天天气不错", time: "09:15", unread: 0),
        Channel(name: "技术交流", lastMessage: "新框架发布", time: "昨天", unread: 5),
    ]

    var body: some View {
        List {
            ForEach(channels) { channel in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(channel.name)
                            .font(.headline)
                        Text(channel.lastMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(channel.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if channel.unread > 0 {
                            Text("\(channel.unread)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(.red))
                        }
                    }
                }
            }
        }
        .navigationTitle("频道")
    }
}

struct Channel: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unread: Int
}

#Preview {
    NavigationView {
        ChatChannelView()
    }
}
