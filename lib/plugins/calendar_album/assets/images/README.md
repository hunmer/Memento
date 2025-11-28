# 日历相册背景图片

此目录用于存储日历相册插件中使用的背景图片。

## 图片要求

- **格式**: PNG、JPG
- **尺寸**: 建议 100x100 像素或以上
- **透明度**: 背景图片应该具有一定的透明度，确保文字可读性
- **风格**: 建议使用简洁、柔和的设计

## 图片用途

- `flower_bg.png` - 有图片的日期背景（花朵主题）
- `star_bg.png` - 有重要标签、生日、纪念日的日期背景（星星主题）
- `mood_bg.png` - 有心情记录的日期背景（心情主题）
- `location_bg.png` - 有位置信息的日期背景（地图主题）
- `multi_entry_bg.png` - 多条日记的日期背景（特殊标记主题）

## 智能背景图片支持

日历组件现在支持多种图片来源：

### 1. Asset图片
```dart
backgroundImage = 'lib/plugins/calendar_album/assets/images/flower_bg.png';
// 自动转换为: assets/plugins/calendar_album/flower_bg.png
```

### 2. 网络图片
```dart
backgroundImage = 'https://picsum.photos/100/100?random=1';
```

### 3. 本地文件图片
```dart
backgroundImage = './local/path/image.jpg';
backgroundImage = '/absolute/path/image.jpg';
```

### 4. 标准Asset路径
```dart
backgroundImage = 'assets/images/common_bg.png';
```

## 背景图片自动选择逻辑

系统会根据日记内容自动选择背景图片：

### 优先获取第一张图片作为背景

1. **图片获取优先级**：
   - 首先检查日记的直接图片URLs (`entry.imageUrls`)
   - 然后检查Markdown内容中提取的图片 (`entry.extractImagesFromMarkdown()`)
   - 按日记顺序，获取第一张可用的图片作为日历背景

2. **智能图片加载**：
   - 支持网络图片、Asset图片、本地文件图片
   - 自动识别图片类型并使用合适的 `ImageProvider`
   - 加载失败时优雅降级为纯色背景

3. **视觉效果**：
   - 背景图片透明度设置为 0.7
   - 添加轻微暗色调叠加确保文字可读性
   - 选中状态时显示纯色背景，不显示图片

### 示例场景

```dart
// 场景1：日记中有直接图片URLs
entry.imageUrls = ['./photo1.jpg', './photo2.jpg']
// 使用: './photo1.jpg' 作为背景

// 场景2：Markdown中有图片
entry.content = "今天天气很好! ![风景](https://example.com/view.jpg)"
// 使用: 'https://example.com/view.jpg' 作为背景

// 场景3：同时有直接URLs和Markdown图片
entry.imageUrls = ['./local.jpg']
entry.content = "![网络图](https://example.com/remote.jpg)"
// 使用: './local.jpg' (直接URLs优先)

// 场景4：多日记同一天
- 日记1: 包含图片1
- 日记2: 包含图片2
- 日记3: 包含图片3
// 使用: 图片1 (第一篇日记的第一张图片)
```

## 添加自定义背景图片

1. 将图片文件放入此目录
2. 在 `calendar_screen.dart` 中的 `_getCalendarDayData()` 方法中添加相应的逻辑
3. 使用相对于项目根目录的路径引用图片

```dart
// 示例：添加自定义背景图片
if (entries.any((entry) => entry.tags.contains('生日'))) {
  backgroundImage = 'lib/plugins/calendar_album/assets/images/birthday_bg.png';
}
```