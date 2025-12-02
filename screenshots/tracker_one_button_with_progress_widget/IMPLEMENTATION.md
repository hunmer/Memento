# 目标追踪进度增减小组件（进度条样式）实现说明

## 概述

基于参考设计创建了一个新的 2x2 目标追踪小组件，采用白色卡片样式，带有进度条显示。

## 设计特点

- **白色卡片背景**：圆角设计，带轻微阴影效果
- **顶部标题栏**：左侧显示目标名称，右侧是圆形加号按钮
- **中间进度显示**：大号字体显示当前值和目标值（例如：8/16）
- **底部进度条**：百分比文本 + 水平进度条（蓝色）

## 创建的文件

### 1. 布局文件

**文件**: `memento_widgets/android/src/main/res/layout/widget_tracker_goal_progress.xml`

- 采用 LinearLayout 垂直布局
- 顶部使用 RelativeLayout 实现左右布局
- 使用 ProgressBar 组件显示水平进度条
- 复用现有的 widget ID 以兼容交互逻辑

### 2. Drawable 资源

#### widget_white_background.xml
白色卡片背景，带圆角和阴影效果。

#### widget_circle_button_background.xml
圆形加号按钮背景，白色填充 + 灰色边框 + 轻微阴影。

#### widget_progress_drawable.xml
进度条样式定义：
- 背景：灰色（#E0E0E0）
- 前景：蓝色（#64B5F6）
- 圆角：4dp

#### widget_tracker_goal_progress_preview.xml
小组件预览图，展示白色背景 + 进度条 + 加号按钮的效果。

### 3. 配置文件

**文件**: `memento_widgets/android/src/main/res/xml/widget_tracker_goal_progress_info.xml`

- 尺寸：2x2 (110dp x 110dp)
- 更新周期：30分钟 (1800000ms)
- 引用布局：`widget_tracker_goal_progress`
- 预览图：`widget_tracker_goal_progress_preview`

### 4. 字符串资源

在 `values/strings.xml` 中添加：
- `widget_tracker_goal_progress_label`: "目标进度（进度条）"
- `widget_tracker_goal_progress_description`: "显示目标进度条，快速增加进度"

### 5. Provider 类

**文件**: `TrackerGoalProgressWidgetProvider.kt`

继承自 `TrackerGoalWidgetProvider`，主要功能：
- 使用新的进度条布局
- 计算并显示百分比进度
- 使用 ProgressBar 组件显示进度条
- 复用父类的增减逻辑
- 点击加号按钮增加进度，显示 Toast 提示

### 6. AndroidManifest 注册

在 `AndroidManifest.xml` 中注册新的小组件 Provider：
```xml
<receiver
    android:name="github.hunmer.memento.widgets.providers.TrackerGoalProgressWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_tracker_goal_progress_info" />
</receiver>
```

## 交互逻辑

1. **未配置状态**：显示"点击设置小组件"提示，点击跳转到配置界面
2. **已配置状态**：
   - 显示目标名称、当前值/目标值、百分比、进度条
   - 点击加号按钮：进度 +1，显示 Toast 提示，刷新小组件
   - 点击小组件主体：跳转到目标详情页

## 数据同步

- 使用 SharedPreferences 存储小组件配置和临时数据
- 按钮点击后记录待同步变更（`tracker_goal_pending_changes`）
- 应用启动时由 Flutter 端同步变更到实际数据

## 与参考设计的对照

| 参考设计元素 | 实现方式 |
|------------|---------|
| 白色圆角卡片 | `widget_white_background.xml` (28dp 圆角) |
| 顶部标题（左） | TextView (14sp, 灰色) |
| 圆形加号按钮（右） | FrameLayout + ImageView (32dp, 白色背景 + 边框) |
| 大号进度数字 | TextView (56sp, 深灰色) |
| 小号目标值 | TextView (44sp, 浅灰色) |
| 百分比文本 | TextView (13sp, 灰色) |
| 水平进度条 | ProgressBar (8dp 高度, 蓝色前景) |

## 使用说明

1. 在桌面长按添加小组件
2. 选择"目标进度（进度条）"
3. 点击小组件进入配置界面，选择要追踪的目标
4. 返回桌面，小组件显示进度信息
5. 点击加号按钮快速增加进度

## 注意事项

- 小组件复用了现有的 `TrackerGoalWidgetProvider` 交互逻辑
- 进度条使用 Android 标准 ProgressBar 组件，确保兼容性
- 颜色和字体大小已根据参考设计调整
- 保持了与现有小组件系统的一致性

---

**创建时间**: 2025-12-02
**参考设计**: `screenshots/tracker_one_button_with_progress_widget/screen.png` 和 `code.html`
