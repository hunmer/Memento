# Flutter 布局问题诊断与修复

## 核心问题：子组件未填满可用空间

### 症状
- `Flexible` 或 `Expanded` 的子组件没有填满分配的宽度/高度
- 右侧/底部留有空白区域
- 使用 `SizedBox(width: double.infinity)` 无效

### 常见原因与解决方案

#### 1. Flexible 默认行为问题

**问题**：`Flexible` 默认 `fit: FlexFit.loose`，允许子组件不填满分配空间

```dart
// ❌ 问题代码 - 子组件可能不填满
Flexible(
  flex: 7,
  child: MyWidget(),
)

// ✅ 修复 - 强制填满
Flexible(
  flex: 7,
  fit: FlexFit.tight,  // 添加此参数
  child: MyWidget(),
)
```

#### 2. FractionallySizedBox 无宽度约束

**问题**：`FractionallySizedBox` 需要父级有确定的宽度约束，否则会报 "infinite width" 错误

```dart
// ❌ 问题代码 - 没有宽度约束
Row(
  children: [
    FractionallySizedBox(widthFactor: 0.3, ...),  // 报错！
    Expanded(child: ...),
  ],
)

// ✅ 修复 - 给固定宽度或用 Flexible 包裹
Row(
  children: [
    SizedBox(
      width: 40,  // 固定宽度
      child: MyChart(),  // 移除内部 FractionallySizedBox
    ),
    Expanded(child: MyLegend()),
  ],
)
```

#### 3. SingleChildScrollView 内部宽度约束丢失

**问题**：`SingleChildScrollView` 内的 `SizedBox(width: double.infinity)` 无法正确获取父级宽度

```dart
// ❌ 问题代码
Flexible(
  child: SingleChildScrollView(
    child: SizedBox(
      width: double.infinity,  // 无效
      child: Column(...),
    ),
  ),
)

// ✅ 修复 - 使用 LayoutBuilder 获取实际宽度
Flexible(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: SizedBox(
          width: constraints.maxWidth,  // 使用实际宽度
          child: Column(...),
        ),
      );
    },
  ),
)
```

#### 4. Row 内部空间分配不均

**问题**：左侧使用 `Flexible` 但内部只占用部分空间，导致右侧 `Flexible` 不会扩展填充

**解决方案**：
- 方案A：左侧不用 `Flexible`，使用固定宽度 `SizedBox`
- 方案B：左侧保持 `Flexible`，内部移除 `FractionallySizedBox` 填满分配空间
- 方案C：右侧改用 `Expanded` 填满剩余空间

```dart
// ✅ 推荐布局
Row(
  children: [
    SizedBox(width: 40, child: FixedWidthWidget()),  // 固定宽度
    SizedBox(width: 8),  // 间距
    Expanded(child: FillRemainingWidget()),  // 填满剩余
  ],
)
```

### 诊断流程

1. **检查约束链**：从根到叶子节点，确认每个节点都有有效的宽度/高度约束
2. **检查 Flex 组件**：`Row`/`Column` 中的子组件是否正确使用 `Flexible`/`Expanded`
3. **检查百分比组件**：`FractionallySizedBox` 是否有父级约束
4. **检查滚动组件**：`SingleChildScrollView` 内部是否用 `LayoutBuilder` 获取约束

### 组件选择指南

| 需求 | 推荐组件 |
|------|----------|
| 填满剩余空间 | `Expanded` |
| 按比例分配但不强制填满 | `Flexible(fit: FlexFit.loose)` |
| 按比例分配并强制填满 | `Flexible(fit: FlexFit.tight)` |
| 固定宽度/高度 | `SizedBox` 或 `ConstrainedBox` |
| 百分比尺寸（有约束时） | `FractionallySizedBox` |
| 在滚动视图中获取父级约束 | `LayoutBuilder` |

### 常见错误信息

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `BoxConstraints forces an infinite width` | `FractionallySizedBox`/百分比组件无父级约束 | 用 `SizedBox` 或 `Flexible` 包裹 |
| `RenderFlex children have non-zero flex but incoming width constraints are unbounded` | `Row` 内部 `Expanded` 但 `Row` 本身无宽度约束 | 给 `Row` 父级添加约束 |
| 子组件不填满可用空间 | `Flexible` 默认 `loose` 行为 | 改用 `Expanded` 或添加 `fit: FlexFit.tight` |
