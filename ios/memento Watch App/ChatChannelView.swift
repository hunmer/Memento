//
//  ChatChannelView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI
import Combine

struct ChatChannelView: View {
    @StateObject private var viewModel = ChatChannelViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
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
                        Task {
                            await viewModel.loadChannels()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.channels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无频道")
                        .font(.headline)
                    Text("在 iPhone 上创建频道后\n数据会同步到这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(viewModel.channels) { channel in
                    NavigationLink(destination: ChatMessageView(channelId: channel.id, channelName: channel.name)) {
                        ChannelRow(channel: channel)
                    }
                }
                .refreshable {
                    await viewModel.loadChannels()
                }
            }
        }
        .navigationTitle("频道")
        .task {
            await viewModel.loadChannels()
        }
    }
}

struct ChannelRow: View {
    let channel: ChatChannel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)

                if let description = channel.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let lastActiveAt = channel.lastActiveAt {
                    Text(formatTime(lastActiveAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(.red))
                }
            }
        }
    }

    private func formatTime(_ isoString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoString) else {
            return ""
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

@MainActor
class ChatChannelViewModel: ObservableObject {
    @Published var channels: [ChatChannel] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadChannels() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            channels = try await WCSessionManager.shared.getChatChannels()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        ChatChannelView()
    }
}
