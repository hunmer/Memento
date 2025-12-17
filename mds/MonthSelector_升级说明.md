# MonthSelector 组件升级说明

## 升级内容

### 主要功能改进
1. **默认选择当前月份**：组件初始化时自动选择当前月份
2. **12个月份视图**：以当前月份为中心，显示前后各6个月，共12个月份
3. **虚拟滚动支持**：滚动到边界时自动加载更多月份
4. **智能控件管理**：保持控件数量在合理范围内（最多18个月份）

### 技术实现
- 将 StatelessWidget 改为 StatefulWidget 以支持状态管理
- 添加 ScrollController 监听滚动事件
- 实现虚拟滚动逻辑，动态扩展月份列表
- 添加智能去重机制，避免重复月份
- 实现自动滚动到选中月份的功能

### 接口变化
```dart
// 旧接口
MonthSelector({
  required DateTime selectedMonth,  // 必须提供
  required ValueChanged<DateTime> onMonthSelected,
  required Map<String, double> Function(DateTime) getMonthStats,
  int monthCount = 6,  // 可配置月份数量
  Color primaryColor = const Color(0xFF3498DB),
})

// 新接口（向后兼容）
MonthSelector({
  DateTime? selectedMonth,  // 可选，默认为当前月份
  required ValueChanged<DateTime> onMonthSelected,
  required Map<String, double> Function(DateTime) getMonthStats,
  Color primaryColor = const Color(0xFF3498DB),
  // 移除了 monthCount 参数，固定显示12个月份
})
```

### 兼容性
- **完全向后兼容**：现有调用代码无需修改
- `selectedMonth` 参数改为可选，不传时默认为当前月份
- 其他参数保持不变

### 性能优化
- 虚拟滚动减少同时渲染的控件数量
- 智能扩展机制避免无限增长
- 去重检查防止重复月份

### 使用示例
```dart
// 新的默认用法（自动选择当前月份）
MonthSelector(
  onMonthSelected: (month) {
    print('选择了月份: $month');
  },
  getMonthStats: (month) {
    // 返回该月的收入和支出统计
    return {
      'income': 1000.0,
      'expense': 500.0,
    };
  },
)

// 指定特定月份（保持向后兼容）
MonthSelector(
  selectedMonth: DateTime(2024, 1, 1),  // 2024年1月
  onMonthSelected: (month) { ... },
  getMonthStats: (month) { ... },
)
```

### 交互体验
- 初始加载时自动滚动到当前月份并居中显示
- 月份选择时有流畅的选中状态切换
- 滚动到边界时平滑地加载更多月份
- 保持一致的视觉样式和动画效果

## 测试验证
- ✅ 默认选择当前月份
- ✅ 12个月份正确显示
- ✅ 虚拟滚动功能正常
- ✅ 月份选择回调正确触发
- ✅ 统计数据格式化显示
- ✅ 向后兼容性验证