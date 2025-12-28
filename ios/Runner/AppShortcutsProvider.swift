import AppIntents

/// AppShortcutsProvider - Siri Shortcuts 捐赠配置
///
/// 为所有 Intent 提供统一的 Shortcut 定义，让 Siri 能够识别并推荐
@MainActor
struct MementoAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateDiaryIntent(),
            phrases: [
                "写日记",
                "记录今天的日记",
                "用 Memento 写日记"
            ],
            shortTitle: "写日记",
            systemImageName: "book.fill"
        )

        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "创建待办任务",
                "添加新任务",
                "提醒我"
            ],
            shortTitle: "创建任务",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "创建笔记",
                "记录笔记",
                "添加新笔记"
            ],
            shortTitle: "创建笔记",
            systemImageName: "note.text"
        )

        AppShortcut(
            intent: CreateBillIntent(),
            phrases: [
                "记录支出",
                "添加账单",
                "记花了多少钱"
            ],
            shortTitle: "记录账单",
            systemImageName: "creditcard.fill"
        )

        AppShortcut(
            intent: CreateActivityIntent(),
            phrases: [
                "记录活动",
                "开始活动",
                "添加新活动"
            ],
            shortTitle: "记录活动",
            systemImageName: "figure.run"
        )

        AppShortcut(
            intent: CreateHabitIntent(),
            phrases: [
                "打卡习惯",
                "完成习惯",
                "记录习惯"
            ],
            shortTitle: "习惯打卡",
            systemImageName: "checkmark.seal.fill"
        )

        AppShortcut(
            intent: SendToAgentChatIntent(),
            phrases: [
                "发送消息给AI",
                "和AI聊天",
                "问AI"
            ],
            shortTitle: "AI对话",
            systemImageName: "bubble.left.and.bubble.right.fill"
        )
    }
}
