# 活动周视图小组件热力图优化 - 修改总结

## 问题描述
1. 热力图显示模糊，无法显示清晰的网格效果
2. 周切换按钮无法正常工作，缺少对应的 Flutter 端监听器
3. 缺少星期标签和时间标签

## 解决方案

### 1. 热力图布局优化

#### 新增文件
- **`widget_heatmap_grid.xml`**: 创建168个格子的网格布局（7天×24小时）
  - 使用 `<include>` 标签引用到主布局
  - 每个格子间距0.5dp，形成清晰的网格线

#### 修改文件
- **`widget_activity_weekly.xml`**:
  - 移除模糊的 ImageView
  - 添加顶部星期标签（周一到周日）
  - 添加左侧时间标签（0, 6, 12, 18, 24小时）
  - 包含热力图网格布局

- **`ActivityWeeklyWidgetProvider.kt`**:
  - 移除 `generateHeatmapBitmap()` 方法
  - 新增 `setHeatmapGridColors()` 方法，直接设置168个格子的背景色
  - 根据活动密度计算颜色强度（白色→强调色渐变）

### 2. 周切换按钮逻辑

#### Flutter 端 (home_widget_service.dart)
- 新增 `_registerBroadcastReceiver()` 方法
- 通过 MethodChannel `github.hunmer.memento/widget_broadcast` 注册广播监听
- 监听以下广播：
  - `REFRESH_ACTIVITY_WEEKLY_WIDGET`
  - `REFRESH_HABITS_WEEKLY_WIDGET`
  - `REFRESH_CHECKIN_WEEKLY_WIDGET`
- 收到广播后：
  1. 更新 SharedPreferences 中的 `weekOffset`
  2. 调用 `PluginWidgetSyncHelper.instance.syncActivityWeeklyWidget()`
  3. 通过 `HomeWidget.updateWidget()` 通知 Android 刷新界面

#### Android 端 (MementoWidgetsPlugin.kt)
- 新增广播 MethodChannel 处理
- 创建 `WidgetBroadcastReceiver` 类
- 通过 `FlutterPluginBinding.applicationContext` 注册广播接收器
- 将接收到的广播转发给 Flutter 端

#### 权限配置
- **`AndroidManifest.xml`**:
  - 添加自定义广播权限声明
  - 注册 ActivityWeeklyWidgetProvider（已设置 `exported="true"`）

## 工作流程

### 周切换按钮点击
1. **Android 小组件**: 用户点击上一周/下一周按钮
2. **Android Provider**:
   - 更新 `currentWeekOffset`
   - 发送广播 `REFRESH_ACTIVITY_WEEKLY_WIDGET`（包含 widgetId 和 weekOffset）
3. **Android Plugin**: 接收广播并转发给 Flutter
4. **Flutter 端**:
   - 接收广播事件
   - 更新 SharedPreferences 中的 weekOffset
   - 调用 `syncActivityWeeklyWidget()` 重新计算数据
   - 调用 `updateWidget()` 通知 Android 刷新
5. **Android Provider**: 重新渲染界面（热力图+周标题+标签列表）

### 热力图渲染
1. **Android Provider**: 接收热力图数据
2. **热力图计算**: 根据活动密度计算168个格子的颜色
3. **格子着色**: 循环设置每个格子的背景色
4. **界面显示**: 显示清晰的网格（包含星期和時間标签）

## 技术细节

### 热力图颜色计算
```kotlin
val maxCount = heatmap.flatten().maxOrNull() ?: 1
val intensity = if (maxCount > 0) count.toFloat() / maxCount else 0f
val color = interpolateColor(Color.WHITE, accentColor, intensity)
```

### 网格布局
- 总共168个 View（7行×24列）
- 每行平均分配空间：`android:layout_weight="1"`
- 格子间距：0.5dp

### 广播数据
```kotlin
// 发送广播
val refreshIntent = Intent("github.hunmer.memento.REFRESH_ACTIVITY_WEEKLY_WIDGET").apply {
    putExtra("widgetId", widgetId)
    putExtra("weekOffset", newOffset)
}

// 接收数据
final widgetId = data?['widgetId'] as int?;
final weekOffset = data?['weekOffset'] as int?;
```

## 文件清单

### 新增文件
1. `/memento_widgets/android/src/main/res/layout/widget_heatmap_grid.xml` - 热力图网格布局

### 修改文件
1. `/memento_widgets/android/src/main/res/layout/widget_activity_weekly.xml` - 主布局（添加标签和网格）
2. `/memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/ActivityWeeklyWidgetProvider.kt` - Provider（网格渲染）
3. `/memento_widgets/android/src/main/kotlin/github/hunmer/memento_widgets/MementoWidgetsPlugin.kt` - 广播支持
4. `/memento_widgets/android/src/main/AndroidManifest.xml` - 权限声明
5. `/lib/core/app_widgets/home_widget_service.dart` - Flutter 广播监听

## 注意事项

1. **应用状态**: 广播监听器仅在应用运行时有效，应用完全关闭后无法接收广播
2. **共享数据**: 使用 home_widget 插件的 SharedPreferences 存储小组件数据
3. **平台限制**: 广播功能仅在 Android 平台启用（UniversalPlatform.isAndroid 检查）
4. **资源消耗**: 168个格子的颜色设置可能会消耗一些性能，但影响很小

## 预期效果

- ✅ 热力图显示清晰的网格（不再模糊）
- ✅ 顶部显示星期标签（周一到周日）
- ✅ 左侧显示时间标签（0, 6, 12, 18, 24小时）
- ✅ 周切换按钮正常工作（点击刷新数据）
- ✅ 根据活动密度显示颜色深浅（未活动=白色，频繁活动=深色）
