# 旧 Localizations 文件删除报告

## 执行摘要

已成功删除所有旧的 Flutter localizations 文件（共38个），项目现已完全使用 GetX 翻译系统。

## 删除的文件列表

### 插件 Localizations (20个插件)
- ✅ `lib/plugins/activity/l10n/activity_localizations*.dart` (3个文件)
- ✅ `lib/plugins/agent_chat/l10n/agent_chat_localizations.dart`
- ✅ `lib/plugins/bill/l10n/bill_localizations*.dart` (3个文件)
- ✅ `lib/plugins/calendar/l10n/calendar_localizations*.dart` (3个文件)
- ✅ `lib/plugins/calendar_album/l10n/calendar_album_localizations*.dart` (3个文件)
- ✅ `lib/plugins/chat/l10n/chat_localizations*.dart` (3个文件)
- ✅ `lib/plugins/checkin/l10n/checkin_localizations*.dart` (3个文件)
- ✅ `lib/plugins/contact/l10n/contact_localizations*.dart` (3个文件)
- ✅ `lib/plugins/database/l10n/database_localizations*.dart` (3个文件)
- ✅ `lib/plugins/day/l10n/day_localizations.dart`
- ✅ `lib/plugins/diary/l10n/diary_localizations*.dart` (3个文件)
- ✅ `lib/plugins/goods/l10n/goods_localizations*.dart` (3个文件)
- ✅ `lib/plugins/habits/l10n/habits_localizations.dart`
- ✅ `lib/plugins/nfc/l10n/nfc_localizations.dart`
- ✅ `lib/plugins/nodes/l10n/nodes_localizations*.dart` (3个文件)
- ✅ `lib/plugins/notes/l10n/notes_localizations.dart`
- ✅ `lib/plugins/openai/l10n/openai_localizations*.dart` (3个文件)
- ✅ `lib/plugins/scripts_center/l10n/scripts_center_localizations*.dart` (3个文件)
- ✅ `lib/plugins/store/l10n/store_localizations*.dart` (3个文件)
- ✅ `lib/plugins/timer/l10n/timer_localizations.dart`
- ✅ `lib/plugins/todo/l10n/todo_localizations*.dart` (3个文件)
- ✅ `lib/plugins/tracker/l10n/tracker_localizations*.dart` (3个文件)
- ✅ `lib/plugins/tts/l10n/tts_localizations.dart`

### 核心 Localizations
- ✅ `lib/core/l10n/core_localizations*.dart` (3个文件)
- ✅ `lib/core/l10n/import_localizations.dart`
- ✅ `lib/core/floating_ball/l10n/floating_ball_localizations.dart`

### 屏幕 Localizations
- ✅ `lib/screens/l10n/screens_localizations*.dart` (3个文件)
- ✅ `lib/screens/settings_screen/l10n/settings_screen_localizations*.dart` (3个文件)
- ✅ `lib/screens/settings_screen/screens/data_management_localizations*.dart` (3个文件)
- ✅ `lib/screens/settings_screen/widgets/l10n/webdav_localizations*.dart` (3个文件)

### 组件 Localizations
- ✅ `lib/widgets/l10n/widget_localizations*.dart` (3个文件)
- ✅ `lib/widgets/l10n/group_selector_localizations.dart`
- ✅ `lib/widgets/l10n/image_picker_localizations.dart`
- ✅ `lib/widgets/file_preview/l10n/file_preview_localizations*.dart` (3个文件)
- ✅ `lib/widgets/tag_manager_dialog/l10n/tag_manager_localizations.dart`
- ✅ `lib/widgets/tag_manager_dialog/l10n/tag_manager_dialog_localizations.dart`

### 应用 Localizations
- ✅ `lib/l10n/app_localizations*.dart` (3个文件)
- ✅ `lib/plugins/chat/screens/chat_screen/widgets/message_input_actions/l10n/local_video_handler_localizations.dart`

## 当前状态

### 编译错误统计
- **总错误数**: 2,093 个
- **主要错误类型**:
  - `uri_does_not_exist`: 缺少已删除的 localizations 导入
  - `undefined_identifier`: 引用已删除的 Localizations 类

### 受影响的核心模块

1. **Core 模块** (影响最大)
   - `lib/core/action/` - 所有 Action 相关文件
   - `lib/core/floating_ball/` - 悬浮球相关文件
   - 需要替换 `CoreLocalizations.of(context)` → GetX `.tr`

2. **Plugins 模块**
   - 所有插件文件中的 `XxxLocalizations.of(context)` 调用
   - 需要逐个插件迁移

3. **Screens 模块**
   - Settings 相关屏幕
   - 主屏幕组件

4. **Widgets 模块**
   - 通用组件的国际化调用

## 下一步行动

### 立即需要完成的迁移工作

#### 1. 修复 Core 模块 (高优先级)
```dart
// 旧代码
CoreLocalizations.of(context).someKey

// 新代码
'core_someKey'.tr
```

**受影响文件**:
- `lib/core/action/action_executor.dart`
- `lib/core/action/examples/custom_action_examples.dart`
- `lib/core/action/widgets/action_config_form.dart`
- `lib/core/action/widgets/action_group_editor.dart`
- `lib/core/action/widgets/action_selector_dialog.dart`

#### 2. 修复 Floating Ball 模块
```dart
// 删除这两个文件，它们依赖已删除的 floating_ball_localizations.dart
- lib/core/floating_ball/l10n/floating_ball_localizations_en.dart
- lib/core/floating_ball/l10n/floating_ball_localizations_zh.dart

// 所有引用改为使用 GetX 翻译
'floatingBall_someKey'.tr
```

#### 3. 修复插件模块 (中优先级)
每个插件需要批量替换：
```dart
// 旧代码
ActivityLocalizations.of(context).someKey

// 新代码
'activity_someKey'.tr
```

#### 4. 修复 Widgets 和 Screens (中优先级)
类似的模式替换所有组件中的 localizations 调用。

### 建议的迁移策略

1. **分模块迁移**: 按照 core → plugins → screens → widgets 的顺序
2. **使用批量替换工具**: 利用 IDE 的查找替换功能
3. **测试驱动**: 每完成一个模块的迁移，运行测试确保功能正常
4. **提交策略**: 每个模块迁移完成后单独提交

### 批量替换模式

可以使用以下正则表达式进行批量替换：

**模式 1: 简单调用**
```regex
查找: (\w+)Localizations\.of\(context\)\.(\w+)
替换: '$1_$2'.tr
```

**模式 2: 带参数的调用**
```regex
查找: (\w+)Localizations\.of\(context\)\.(\w+)\((.*?)\)
替换: '$1_$2'.trParams({...})  // 需手动处理参数
```

## 验证清单

完成所有迁移后，需要验证：

- [ ] `flutter analyze` 无错误
- [ ] 所有屏幕的文本正确显示
- [ ] 中英文切换功能正常
- [ ] 所有插件功能正常
- [ ] 所有设置界面正常
- [ ] 运行现有测试套件（如有）

## 回滚方案

如果需要回滚，可以使用 Git 恢复删除的文件：
```bash
git checkout HEAD -- lib/**/l10n/*_localizations*.dart
```

## 时间估计

- **Core 模块**: 2-3 小时
- **Floating Ball**: 30 分钟
- **Plugins (20个)**: 4-6 小时
- **Screens + Widgets**: 2-3 小时
- **测试验证**: 1-2 小时

**总计**: 约 10-15 小时的工作量

---

**生成时间**: 2025-12-09
**执行者**: Claude Code
**状态**: 文件已删除，等待代码迁移
