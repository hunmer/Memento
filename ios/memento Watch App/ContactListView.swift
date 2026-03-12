//
//  ContactListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/13.
//

import SwiftUI
import Combine

struct ContactListView: View {
    @StateObject private var viewModel = ContactListViewModel()

    // 霓虹色彩
    private let neonGreen = Color(hex: "39ff14")
    private let neonBlue = Color(hex: "00f3ff")
    private let neonPurple = Color(hex: "bc13fe")
    private let primaryColor = Color(hex: "ec5b13")

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .foregroundStyle(.white)
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task { await viewModel.loadData() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryColor)
                }
            } else if viewModel.contacts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("暂无联系人")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.contacts) { contact in
                            ContactCardView(
                                contact: contact,
                                neonGreen: neonGreen,
                                neonBlue: neonBlue,
                                neonPurple: neonPurple
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("联系人")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadData() }
    }
}

// MARK: - 联系人卡片视图

struct ContactCardView: View {
    let contact: ContactItem
    let neonGreen: Color
    let neonBlue: Color
    let neonPurple: Color

    // 根据标签获取颜色
    private func getTagColor(_ tag: String) -> Color {
        let lowerTag = tag.lowercased()
        if lowerTag.contains("work") || lowerTag.contains("工作") {
            return neonGreen
        } else if lowerTag.contains("friend") || lowerTag.contains("朋友") {
            return neonBlue
        } else if lowerTag.contains("vip") || lowerTag.contains("重要") {
            return neonPurple
        } else if lowerTag.contains("family") || lowerTag.contains("家人") {
            return .orange
        }
        return neonGreen
    }

    // 性别图标
    private var genderIcon: (name: String, color: Color)? {
        guard let gender = contact.gender else { return nil }
        switch gender {
        case "male":
            return ("person.fill", neonBlue)
        case "female":
            return ("person.fill", neonPurple)
        default:
            return nil
        }
    }

    // 获取边框颜色（基于第一个标签）
    private var borderColor: Color {
        if let firstTag = contact.tags.first {
            return getTagColor(firstTag)
        }
        return neonGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 头像和名字
            HStack(spacing: 8) {
                // 头像
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)

                    if let avatar = contact.avatar, !avatar.isEmpty {
                        // 显示头像首字母作为占位
                        Text(String(contact.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(borderColor)
                    } else {
                        // 显示首字母
                        Text(String(contact.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(borderColor)
                    }
                }

                // 名字和备注
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(contact.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if let icon = genderIcon {
                            Image(systemName: icon.name)
                                .font(.system(size: 9))
                                .foregroundStyle(icon.color)
                        }
                    }

                    if let notes = contact.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 8))
                            .foregroundStyle(Color.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // 电话
            Text(contact.phone)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(borderColor)

            // 标签
            if !contact.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(contact.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(getTagColor(tag))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(getTagColor(tag).opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            // 底部统计
            HStack {
                // 交互次数
                HStack(spacing: 2) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8))
                    Text("\(contact.interactionCount) 次")
                        .font(.system(size: 7))
                }
                .foregroundStyle(Color.gray)

                Spacer()

                // 最近联系
                if let lastTime = contact.lastInteractionTime {
                    HStack(spacing: 2) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 7))
                        Text(lastTime)
                            .font(.system(size: 7))
                    }
                    .foregroundStyle(Color.gray.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: 2), alignment: .leading
        )
    }
}

// MARK: - ViewModel

@MainActor
class ContactListViewModel: ObservableObject {
    @Published var contacts: [ContactItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            contacts = try await WCSessionManager.shared.getContactItems()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ContactListView()
    }
}
