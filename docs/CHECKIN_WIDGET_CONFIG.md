# 打卡小组件配置功能实现文档

## 功能概述

为打卡小组件（`CheckinItemWidgetProvider`）增加了配置选择功能，允许用户在添加小组件后选择要显示的打卡项目，并展示该项目的七日打卡记录。

## 实现流程

### 1. 添加小组件到桌面
- 用户长按桌面 → 添加小组件 → 选择"打卡"小组件
- 小组件默认显示提示文本："点击选择打卡项目"

### 2. 点击配置
- 用户点击小组件
- 打开app，跳转到打卡项目选择界面（`CheckinItemSelectorScreen`）
- 界面展示所有可用的打卡项目，包括：
  - 项目图标和颜色
  - 项目名称和分组
  - 当前打卡状态（已打卡/未打卡）
  - 连续打卡天数

### 3. 选择项目
- 用户点击选中一个打卡项目
- 点击"确认选择"按钮

### 4. 保存配置并更新小组件
- 保存 `appWidgetId` → `checkinItemId` 的映射关系到 SharedPreferences
- 计算该打卡项目的七日打卡记录（周一到周日）
- 同步数据到小组件
- 刷新小组件显示

### 5. 小组件展示
- 显示打卡项目名称
- 显示本周打卡次数（大数字）
- 显示七日打卡状态（✓图标表示已打卡，空白表示未打卡）

## 关键文件修改

### Android 端

#### 1. `CheckinItemWidgetProvider.kt`
**路径**: `memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/CheckinItemWidgetProvider.kt`

**主要修改**:
- 添加了 SharedPreferences 存储配置的逻辑
- 实现了未配置状态的处理（显示提示文本）
- 修改了 `setupCustomWidget` 方法，支持根据配置的 `checkinItemId` 显示特定项目数据
- 添加了 `onDeleted` 方法，在小组件删除时清理配置

**关键方法**:
```kotlin
// 获取配置的打卡项目ID
private fun getConfiguredCheckinItemId(context: Context, appWidgetId: Int): String?

// 保存配置的打卡项目ID
fun saveConfiguredCheckinItemId(context: Context, appWidgetId: Int, checkinItemId: String)

// 设置未配置状态的小组件
private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int)

// 设置已配置状态的小组件
private fun setupCustomWidget(views: RemoteViews, data: JSONObject, checkinItemId: String): Boolean
```

#### 2. `widget_checkin_item.xml`
**路径**: `memento_widgets/android/src/main/res/layout/widget_checkin_item.xml`

**主要修改**:
- 添加了 `widget_hint_text` TextView 用于显示"点击选择打卡项目"提示

### Flutter 端

#### 1. `CheckinItemSelectorScreen.dart` (新增)
**路径**: `lib/plugins/checkin/screens/checkin_item_selector_screen.dart`

**功能**:
- 展示所有打卡项目列表
- 支持选择打卡项目
- 保存配置到 SharedPreferences
- 计算七日打卡记录并同步到小组件

**关键方法**:
```dart
// 选中打卡项目
void _onItemSelected(CheckinItem item)

// 保存配置并关闭界面
Future<void> _saveAndFinish()

// 同步打卡项目数据到小组件
Future<void> _syncCheckinItemToWidget(CheckinItem item)
```

#### 2. `route.dart`
**路径**: `lib/screens/route.dart`

**主要修改**:
- 导入了 `CheckinItemSelectorScreen`
- 添加了 `/checkin_item_selector` 路由常量
- 在 `generateRoute` 中添加了路由处理逻辑，支持解析 `widgetId` 参数

#### 3. `main.dart`
**路径**: `lib/main.dart`

**主要修改**:
- 在 `_handleWidgetClick` 函数中添加了对打卡小组件配置路由的特殊处理
- 将 `/checkin_item/config?widgetId=xxx` 转换为 `/checkin_item_selector?widgetId=xxx`

## 数据格式

### SharedPreferences 存储

#### 配置映射
- **Key**: `checkin_item_id_{appWidgetId}`
- **Value**: 打卡项目的 ID（字符串）
- **存储位置**: `checkin_item_widget_prefs`

#### 小组件数据
- **Key**: `checkin_item_widget_data`
- **Value**: JSON 字符串
- **格式**:
```json
{
  "items": [
    {
      "id": "1234567890",
      "name": "早起",
      "weekChecks": "1,1,1,1,1,0,0"
    }
  ]
}
```

### weekChecks 格式说明
- 逗号分隔的7个数字（0或1）
- 分别对应周一到周日
- 1表示已打卡，0表示未打卡
- 例如：`"1,1,1,1,1,0,0"` 表示周一到周五已打卡，周末未打卡

## Deep Link 路由

### 配置路由
- **格式**: `memento://widget/checkin_item/config?widgetId={appWidgetId}`
- **触发时机**: 用户点击未配置的打卡小组件
- **处理逻辑**:
  1. Android 端通过 PendingIntent 发送 Deep Link
  2. Flutter 端在 `main.dart` 的 `_handleWidgetClick` 中捕获
  3. 转换为 `/checkin_item_selector?widgetId={appWidgetId}` 路由
  4. 跳转到 `CheckinItemSelectorScreen`

### 示例
```
原始 URI: memento://widget/checkin_item/config?widgetId=123
处理后路由: /checkin_item_selector?widgetId=123
```

## 测试流程

### 1. 添加小组件
1. 确保应用中已创建至少一个打卡项目
2. 长按桌面 → 添加小组件
3. 选择 Memento 的打卡小组件（2x2）
4. **预期结果**: 小组件显示"打卡"标题，但打卡数为空，提示"点击选择打卡项目"

### 2. 配置小组件
1. 点击刚添加的小组件
2. **预期结果**: 打开app，进入打卡项目选择界面
3. 查看打卡项目列表
4. 选择一个打卡项目（点击项目卡片）
5. **预期结果**: 该项目卡片高亮显示，右侧显示选中图标
6. 点击底部"确认选择"按钮
7. **预期结果**:
   - 显示提示："已选择 {项目名称}"
   - 界面自动关闭
   - 返回桌面

### 3. 验证小组件显示
1. 回到桌面查看小组件
2. **预期结果**:
   - 标题显示为选中的打卡项目名称（如"早起"）
   - 大数字显示本周打卡次数（如"5"）
   - 底部显示七日打卡状态（周一到周日）
   - 已打卡的日期显示✓图标，未打卡的日期为空白

### 4. 多个小组件测试
1. 添加第二个打卡小组件到桌面
2. 点击配置，选择不同的打卡项目
3. **预期结果**: 两个小组件各自显示不同的打卡项目数据

### 5. 删除小组件测试
1. 长按小组件 → 移除
2. **预期结果**: 配置数据自动清理（通过 `onDeleted` 方法）

## 已知问题与优化建议

### 当前限制
1. 暂时没有实现小组件内的打卡操作（只展示数据）
2. 未支持重新配置（需要删除后重新添加）
3. 七日打卡记录是固定的周一到周日，不支持自定义

### 优化建议
1. **添加重新配置功能**: 允许用户长按小组件修改配置
2. **支持小组件内打卡**: 添加点击事件直接完成打卡
3. **添加自动刷新**: 当打卡状态变化时自动更新小组件
4. **优化空状态**: 当没有打卡项目时，提供创建打卡项目的快捷入口
5. **添加小组件尺寸选项**: 支持 1x1、2x1 等不同尺寸

## 开发者注意事项

### 数据同步时机
- 用户选择打卡项目后立即同步
- 建议在打卡记录变化时主动触发同步（通过 `PluginWidgetSyncHelper`）

### SharedPreferences Key 规范
- 配置Key: `checkin_item_id_{appWidgetId}`
- 数据Key: `checkin_item_widget_data`
- 不要与其他插件的Key冲突

### 调试技巧
1. 查看 Android 日志:
```bash
adb logcat | grep "CheckinItemWidget"
```

2. 查看 Flutter 日志:
```dart
debugPrint('打卡项目数据已同步: ${item.name}');
```

3. 检查 SharedPreferences:
```bash
adb shell
run-as github.hunmer.memento
cat shared_prefs/checkin_item_widget_prefs.xml
```

## 参考文档
- [小组件实现指南](./WIDGET_IMPLEMENTATION_GUIDE.md)
- [小组件快速参考](./WIDGET_QUICK_REFERENCE.md)
- [小组件配置参考](./widget_settings.md)

---

**实现日期**: 2025-12-01
**版本**: 1.0.0
**作者**: AI Assistant
