# iOS Shortcuts 功能设置指南

## ✅ 已完成的代码实现

所有代码文件已经创建并配置完成！现在需要在 Xcode 中完成最后的设置步骤。

---

## 📋 在 Xcode 中添加 Swift 文件

### 步骤 1：打开 Xcode 项目

```bash
cd /Users/Zhuanz/Documents/Memento
open ios/Runner.xcworkspace
```

⚠️ **注意**：必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj`！

---

### 步骤 2：添加 Swift 文件到项目

在 Xcode 中：

1. **在左侧导航栏中找到 `Runner` 文件夹**
2. **右键点击 `Runner` 文件夹 → `Add Files to "Runner"...`**
3. **导航到 `/Users/Zhuanz/Documents/Memento/ios/Runner/`**
4. **选择以下 3 个文件**（按住 Cmd 键多选）：
   - ✅ `SendToAgentChatIntent.swift`
   - ✅ `ConversationEntity.swift`
   - ✅ `ConversationQuery.swift`

5. **确保勾选以下选项**：
   - ✅ **Copy items if needed** （如果需要则复制项目）
   - ✅ **Create groups** （创建组）
   - ✅ **Add to targets: Runner** （添加到 Runner 目标）

6. **点击 "Add" 按钮**

---

### 步骤 3：验证文件已添加

在 Xcode 左侧导航栏中，你应该能看到这 3 个文件显示在 `Runner` 文件夹下：

```
Runner
├── AppDelegate.swift
├── SendToAgentChatIntent.swift      ← 新添加
├── ConversationEntity.swift         ← 新添加
├── ConversationQuery.swift          ← 新添加
├── Assets.xcassets
└── Info.plist
```

---

### 步骤 4：清理并构建

在 Xcode 中：

1. **Product → Clean Build Folder** （快捷键：Cmd + Shift + K）
2. **Product → Build** （快捷键：Cmd + B）

或者在终端中运行：

```bash
flutter clean
flutter pub get
cd ios && pod install
cd ..
flutter build ios --debug
```

---

## 🧪 测试步骤

### 1. 在真机上运行应用

⚠️ **Shortcuts 功能必须在真机上测试，模拟器不支持！**

```bash
flutter run -d <你的设备ID>
```

查看可用设备：
```bash
flutter devices
```

---

### 2. 在 Shortcuts 应用中测试

#### 方法 A：通过 Shortcuts 应用

1. **打开系统的"快捷指令"应用**
2. **点击右上角 "+" 创建新快捷指令**
3. **搜索 "发送消息到AI聊天"** 或 "Memento"
4. **添加该动作到快捷指令**
5. **配置参数**：
   - 消息内容：输入测试文本
   - 图片：选择 1-3 张图片（可选）
   - 频道：选择已有频道或留空（可选）
6. **点击播放按钮运行**

#### 方法 B：通过 Siri（可选，需要添加 AppShortcuts.swift）

对 Siri 说：
- "发送消息到 Memento"
- "给AI发消息"

---

### 3. 验证功能

运行快捷指令后，应该看到：

✅ Memento 应用自动打开
✅ 跳转到 AI 聊天界面
✅ 显示你发送的消息
✅ 如果有图片，图片正确显示为附件
✅ 如果未选择频道，自动创建"快捷指令消息"临时会话

---

## 🐛 常见问题排查

### 问题 1：找不到"发送消息到AI聊天"动作

**原因**：Swift 文件未正确添加到 Xcode 项目

**解决**：
1. 检查 Xcode 左侧是否显示这 3 个 Swift 文件
2. 选中 `SendToAgentChatIntent.swift`，在右侧面板检查 "Target Membership" 是否勾选了 "Runner"
3. 重新构建项目

---

### 问题 2：运行快捷指令时应用崩溃

**查看日志**：
```bash
# 连接设备后运行
flutter logs
```

或在 Xcode 中查看控制台输出（Window → Devices and Simulators → 选择设备 → View Device Logs）

**常见原因**：
- Flutter 插件未初始化完成
- 图片文件路径无效
- 频道 ID 不存在

---

### 问题 3：图片未显示

**检查**：
1. 查看日志中的图片路径：`[ShortcutsHandler] 处理了 X 张图片`
2. 确认临时文件存在：
   ```bash
   ls -la /Users/Zhuanz/Library/Developer/CoreSimulator/.../tmp/shortcut_image_*
   ```
3. 检查照片访问权限是否授予

---

### 问题 4：频道列表为空

**原因**：频道同步未成功

**解决**：
1. 在应用中创建一个新的 AI 聊天频道
2. 检查日志：`[ConversationSync] 已同步 X 个频道到 iOS`
3. 重新打开 Shortcuts 应用刷新

---

## 📊 调试技巧

### 查看详细日志

在 Flutter 应用中，所有关键步骤都有日志输出：

```
[ShortcutsHandler] iOS Shortcuts 监听器已启动
[ShortcutsHandler] 收到 Shortcut 数据: {"action":"send_to_agent_chat",...}
[ShortcutsHandler] 未指定频道，创建临时会话
[ShortcutsHandler] 处理了 2 张图片
[ShortcutsHandler] 消息已保存到数据库
[ShortcutsHandler] 已导航到聊天界面
[ConversationSync] 已同步 5 个频道到 iOS
```

在 iOS 端：

```
[SendToAgentChat] 已发送数据到 Flutter: {...}
[AppDelegate] Intelligence 插件已配置
[AppDelegate] 已清理 3 个旧临时文件
```

---

## 🎯 下一步优化（可选）

### 添加 Siri 语音支持

创建 `/ios/Runner/AppShortcuts.swift`：

```swift
import AppIntents

struct AgentChatAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendToAgentChatIntent(),
            phrases: [
                "发送消息到 \(.applicationName)",
                "给AI发消息",
                "Ask AI in \(.applicationName)"
            ]
        )
    }
}
```

然后在 Xcode 中添加此文件到项目。

---

## 📝 技术细节

### 数据传递格式

iOS → Flutter 的 JSON 格式：

```json
{
  "action": "send_to_agent_chat",
  "message": "用户输入的文本",
  "conversationId": "频道ID（可选）",
  "imagePaths": [
    "/tmp/shortcut_image_0_1735057890.123.jpg",
    "/tmp/shortcut_image_1_1735057890.456.jpg"
  ],
  "timestamp": 1735057890.123
}
```

### 临时文件生命周期

- **创建时机**：Shortcuts 运行时
- **存储位置**：`FileManager.default.temporaryDirectory`
- **命名规则**：`shortcut_image_{index}_{timestamp}.jpg`
- **清理时机**：应用启动时清理 24 小时前的文件

---

## ✅ 完成检查清单

在测试前，确保：

- [ ] 已在 Xcode 中添加 3 个 Swift 文件
- [ ] 已成功构建项目（无编译错误）
- [ ] 已在真机上安装应用
- [ ] 已创建至少 1 个 AI 聊天频道
- [ ] 已打开"快捷指令"应用

测试时：

- [ ] 能在 Shortcuts 中找到"发送消息到AI聊天"动作
- [ ] 输入文本能成功发送
- [ ] 选择图片能正确附加
- [ ] 选择频道能发送到指定频道
- [ ] 未选择频道时自动创建临时会话

---

## 🆘 需要帮助？

如果遇到问题，请提供：

1. **完整的错误日志**（Flutter logs 或 Xcode 控制台）
2. **Xcode 版本**（Xcode → About Xcode）
3. **iOS 版本**（设置 → 通用 → 关于本机）
4. **测试步骤**（你做了什么操作）

---

**祝测试顺利！🎉**
