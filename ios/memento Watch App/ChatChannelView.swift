//
//  ChatChannelView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/11.
//

import SwiftUI

struct ChatChannelView: View {
    @StateObject private var sessionManager = WCSessionManager.shared
    @State private var channels: [ChatChannel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowInsets(EdgeInsets())
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
                        loadChannels()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
            } else if channels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("暂无频道")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(channels) { channel in
                    NavigationLink(destination: ChatMessageView(channel: channel)) {
                        ChatChannelRow(channel: channel)
                    }
                }
            }
        }
        .navigationTitle("频道聊天")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadChannels()
        }
        .refreshable {
            loadChannels()
        }
    }

    private func loadChannels() {
        guard sessionManager.isReachable else {
            errorMessage = "无法连接到手机\n请确保手机 App 已打开"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedChannels = try await sessionManager.getChatChannels()
                await MainActor.run {
                    self.channels = loadedChannels
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

// MARK: - 频道行

struct ChatChannelRow: View {
    let channel: ChatChannel

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)

                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let description = channel.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 未读标记
            if channel.unreadCount > 0 {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)

                    Text(channel.unreadCount > 99 ? "99+" : "\(channel.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 预览

#Preview {
    NavigationView {
        ChatChannelView()
    }
}
