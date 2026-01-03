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
                "用\${applicationName}写日记",
                "在\${applicationName}记录今天的日记",
                "打开\${applicationName}写日记"
            ],
            shortTitle: "写日记",
            systemImageName: "book.fill"
        )

        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "用\${applicationName}创建待办任务",
                "在\${applicationName}添加新任务",
                "用\${applicationName}提醒我"
            ],
            shortTitle: "创建任务",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "用\${applicationName}创建笔记",
                "在\${applicationName}记录笔记",
                "打开\${applicationName}添加新笔记"
            ],
            shortTitle: "创建笔记",
            systemImageName: "note.text"
        )

        AppShortcut(
            intent: CreateBillIntent(),
            phrases: [
                "用\${applicationName}记录支出",
                "在\${applicationName}添加账单",
                "用\${applicationName}记花了多少钱"
            ],
            shortTitle: "记录账单",
            systemImageName: "creditcard.fill"
        )

        AppShortcut(
            intent: CreateActivityIntent(),
            phrases: [
                "用\${applicationName}记录活动",
                "在\${applicationName}开始活动",
                "打开\${applicationName}添加新活动"
            ],
            shortTitle: "记录活动",
            systemImageName: "figure.run"
        )

        AppShortcut(
            intent: CreateHabitIntent(),
            phrases: [
                "用\${applicationName}打卡习惯",
                "在\${applicationName}完成习惯",
                "用\${applicationName}记录习惯"
            ],
            shortTitle: "习惯打卡",
            systemImageName: "checkmark.seal.fill"
        )

        AppShortcut(
            intent: SendToAgentChatIntent(),
            phrases: [
                "用\${applicationName}发送消息给AI",
                "在\${applicationName}和AI聊天",
                "打开\${applicationName}问AI"
            ],
            shortTitle: "AI对话",
            systemImageName: "bubble.left.and.bubble.right.fill"
        )
    }
}
