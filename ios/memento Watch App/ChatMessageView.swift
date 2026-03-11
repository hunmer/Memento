//
//  ChatMessageView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/11.
//

import SwiftUI

struct ChatMessageView: View {
    @StateObject private var sessionManager = WCSessionManager.shared
    let channelId: String
    let channelName: String

    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("重试") {
                        loadMessages()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("暂无消息")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        ChatMessageBubble(message: message)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(channelName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
        .refreshable {
            loadMessages()
        }
    }

    private func loadMessages() {
        guard sessionManager.isReachable else {
            errorMessage = "无法连接到手机\n请确保手机 App 已打开"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedMessages = try await sessionManager.getChatMessages(channelId: channelId)
                await MainActor.run {
                    self.messages = loadedMessages
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - 消息气泡

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isMe == true {
                Spacer()
            }

            VStack(alignment: message.isMe == true ? .trailing : .leading, spacing: 4) {
                // 发送者名称
                if let senderName = message.senderName, message.isMe != true {
                    Text(senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 消息内容
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isMe == true ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundStyle(message.isMe == true ? .white : .primary)

                // 时间戳
                if let timestamp = formatTimestamp(message.timestamp) {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 180, alignment: message.isMe == true ? .trailing : .leading)

            if message.isMe != true {
                Spacer()
            }
        }
    }

    private func formatTimestamp(_ dateString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return nil }

        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if components.day! > 0 {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM/dd HH:mm"
            return displayFormatter.string(from: date)
        } else if components.hour! > 0 {
            return "\(components.hour!)小时前"
        } else if components.minute! > 0 {
            return "\(components.minute!)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationView {
        ChatMessageView(channelId: "1", channelName: "示例频道")
    }
}
