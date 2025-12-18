# Android小组件图标PNG支持

本功能允许Flutter应用将图标名称传递给Android小组件，小组件将从Flutter assets中加载对应的PNG图标进行渲染。

## 功能概述

- ✅ 支持Material Icons PNG图标（1136个图标）
- ✅ 从Flutter assets动态加载图标
- ✅ 小组件显示高质量PNG图标而非emoji
- ✅ 支持自定义图标名称和回退机制

## 实现架构

### 1. 图标资源管理

**Python脚本**: `scripts/copy_icons.py`
- 自动将`png/black/baseline-4x.png`文件复制到`assets/icons/material/`
- 重命名为对应的图标名称（如`star.png`, `home.png`等）
- 复制了1136个Material Icons

**Flutter配置**: `pubspec.yaml`
```yaml
flutter:
  assets:
    - assets/icons/material/  # Material Icons for Android widgets
```

### 2. 小组件布局修改

**分组项布局**: `memento_widgets/android/src/main/res/layout/widget_habit_group_item.xml`
```xml
<!-- 原来的TextView (emoji) -->
<TextView android:id="@+id/group_icon" ... />

<!-- 现在的ImageView (PNG) -->
<ImageView android:id="@+id/group_icon" ... />
```

**习惯项布局**: `memento_widgets/android/src/main/res/layout/widget_habit_list_item.xml`
```xml
<!-- 原来的TextView (emoji) -->
<TextView android:id="@+id/habit_icon" ... />

<!-- 现在的ImageView (PNG) -->
<ImageView android:id="@+id/habit_icon"
    android:scaleType="centerInside"
    android:padding="8dp" />
```

### 3. 图标加载逻辑

**RemoteViewsFactory**: `HabitGroupListRemoteViewsFactory.kt`

新增`loadIconFromAssets()`方法：
```kotlin
private fun loadIconFromAssets(iconName: String): Bitmap? {
    return try {
        // 路径: flutter_assets/assets/icons/material/{iconName}.png
        val assetPath = "flutter_assets/assets/icons/material/$iconName.png"
        context.assets.open(assetPath).use { inputStream ->
            BitmapFactory.decodeStream(inputStream)
        }
    } catch (e: Exception) {
        Log.w(TAG, "Failed to load icon '$iconName': ${e.message}")
        null
    }
}
```

**渲染逻辑**:
```kotlin
// 分组图标
val iconBitmap = loadIconFromAssets(group.icon)
if (iconBitmap != null) {
    views.setImageViewBitmap(R.id.group_icon, iconBitmap)
} else {
    views.setImageViewResource(R.id.group_icon, android.R.drawable.ic_menu_gallery)
}

// 习惯图标
val iconName = habit.icon ?: "star"
val iconBitmap = loadIconFromAssets(iconName)
if (iconBitmap != null) {
    views.setImageViewBitmap(R.id.habit_icon, iconBitmap)
} else {
    views.setImageViewResource(R.id.habit_icon, android.R.drawable.ic_menu_gallery)
}
```

## Flutter端数据传递

### 传递图标名称

在Flutter端，小组件数据应包含图标的**名称**而非ID或emoji：

```json
{
  "groups": [
    {
      "id": "group1",
      "name": "运动",
      "icon": "fitness_center"  // 图标名称（非emoji）
    }
  ],
  "habits": [
    {
      "id": "habit1",
      "title": "跑步",
      "icon": "run_circle",      // 图标名称（非emoji）
      "group": "group1"
    }
  ]
}
```

### 可用图标

所有1136个Material Icons都可用，包括：
- `star` - 星形图标
- `home` - 主页图标
- `settings` - 设置图标
- `fitness_center` - 健身中心
- `run_circle` - 跑步圈
- 等等...

**完整列表**: 查看`assets/icons/material/`目录

## 使用流程

### 1. 首次设置

```bash
# 复制图标到Flutter assets
python scripts/copy_icons.py

# 运行Flutter应用
flutter run
```

### 2. 配置小组件数据

Flutter端通过SharedPreferences传递数据给小组件：

```dart
// 保存小组件数据
final prefs = await SharedPreferences.getInstance();
await prefs.setString('habit_group_list_widget_data', jsonEncode({
  'groups': [
    {
      'id': 'exercise',
      'name': '运动',
      'icon': 'fitness_center',  // 图标名称
    }
  ],
  'habits': [
    {
      'id': 'running',
      'title': '晨跑',
      'icon': 'run_circle',      // 图标名称
      'group': 'exercise'
    }
  ]
}));

// 刷新小组件
HabitGroupListWidgetProvider.refreshAllWidgets(context);
```

### 3. 小组件显示

Android小组件会自动：
1. 从SharedPreferences读取数据
2. 根据`icon`字段的值加载PNG图标
3. 显示在小组件中

## 错误处理

### 图标加载失败

- 如果指定的图标文件不存在，会记录警告日志
- 自动回退到默认图标：`android.R.drawable.ic_menu_gallery`
- 小组件不会崩溃，继续正常显示

### 日志调试

查看图标加载日志：
```bash
adb logcat | grep "HabitGroupListFactory"
```

示例日志：
```
D/HabitGroupListFactory: Loading icon: flutter_assets/assets/icons/material/star.png
W/HabitGroupListFactory: Failed to load icon 'non_existent': ...
```

## 性能优化

### 1. 图标缓存

当前实现每次渲染都重新加载图标。优化建议：
- 在RemoteViewsFactory中缓存已加载的Bitmap
- 使用LruCache限制内存使用

### 2. 图标尺寸

- 复制的图标是4x分辨率（高分辨率）
- ImageView设置了`android:scaleType="centerInside"`
- 自动缩放到合适大小

### 3. 加载时机

- 图标在`getViewAt()`中按需加载
- 避免在`onDataSetChanged()`中预加载所有图标

## 扩展其他小组件

如果要为其他小组件添加PNG图标支持：

1. **复制布局修改**：
   - 将TextView图标改为ImageView

2. **更新RemoteViewsFactory**：
   - 添加`loadIconFromAssets()`方法
   - 修改图标渲染逻辑

3. **传递图标名称**：
   - 从Flutter端传递图标名称而非emoji

## 注意事项

1. **路径格式**：Flutter assets路径始终以`flutter_assets/`开头
2. **文件扩展名**：图标文件名自动添加`.png`后缀
3. **大小写敏感**：图标名称区分大小写（如`Star.png` ≠ `star.png`）
4. **资源声明**：确保在`pubspec.yaml`中声明了`assets/icons/material/`

## 更新日志

- **2025-12-04**: 初始实现，支持1136个Material Icons
  - Python脚本自动复制图标
  - 修改小组件布局支持ImageView
  - 实现从Flutter assets加载PNG图标
  - 添加错误处理和回退机制

## 相关文件

- `scripts/copy_icons.py` - 图标复制脚本
- `pubspec.yaml` - Flutter资源声明
- `memento_widgets/android/src/main/res/layout/widget_habit_group_item.xml` - 分组布局
- `memento_widgets/android/src/main/res/layout/widget_habit_list_item.xml` - 习惯布局
- `memento_widgets/android/src/main/kotlin/.../HabitGroupListRemoteViewsFactory.kt` - 渲染逻辑
