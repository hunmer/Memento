# SuperCupertinoNavigationWrapper 使用指南

## 概述

`SuperCupertinoNavigationWrapper` 是一个增强的导航容器组件，基于 iOS 风格的大标题导航栏设计，提供了搜索、过滤、底部栏等功能的统一封装。本指南将详细介绍如何使用这个组件及其在笔记插件中的应用示例。

## 主要特性

### 1. 大标题 (Large Title)
- iOS 风格的动态大标题
- 支持折叠和展开效果
- 可配置大标题操作按钮

### 2. 内置搜索栏
- 实时搜索文本变化监听
- 自定义占位符文本
- 支持搜索提交回调

### 3. 过滤栏支持
- 可自定义过滤栏高度
- 支持任意 Widget 作为过滤内容
- 过滤条件变更回调

### 4. 高级搜索条件
- 支持多个搜索条件筛选器
- 条件变更自动同步到回调

### 5. 底部栏（保持向后兼容）
- 传统底部栏支持
- 与过滤栏的灵活切换

## 基本用法

### 1. 基础示例

```dart
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';

class MyScreen extends StatelessWidget {
  final List<String> items = ['Apple', 'Banana', 'Orange', 'Grape'];
  List<String> filteredItems = [];

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: const Text('我的应用'),
      largeTitle: '水果列表',
      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: '搜索水果...',
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: _onSearchSubmitted,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(),
        ),
      ],
      largeTitleActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addItem(),
        ),
      ],
      onCollapsed: (isCollapsed) {
        debugPrint('导航栏折叠状态: $isCollapsed');
      },
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filteredItems[index]),
          onTap: () => _onItemTap(filteredItems[index]),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredItems = items;
    } else {
      filteredItems = items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void _onSearchSubmitted(String query) {
    debugPrint('搜索提交: $query');
  }
}
```

### 2. 带过滤栏的示例

```dart
class FilteredListScreen extends StatefulWidget {
  @override
  State<FilteredListScreen> createState() => _FilteredListScreenState();
}

class _FilteredListScreenState extends State<FilteredListScreen> {
  String? selectedCategory;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: const Text('列表'),
      largeTitle: '过滤列表',
      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableFilterBar: true,
      filterBarHeight: 60,
      filterBarChild: _buildFilterBar(),
      searchPlaceholder: '搜索列表项...',
      onSearchChanged: _onSearchChanged,
      onFilterChanged: _onFilterChanged,
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.category_outlined,
            label: selectedCategory ?? '全部分类',
            onTap: _showCategoryPicker,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.calendar_today,
            label: selectedDate != null
                ? DateFormat('yyyy/MM/dd').format(selectedDate!)
                : '全部日期',
            onTap: _showDatePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _onFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      selectedCategory = filters['category'] as String?;
      selectedDate = filters['date'] as DateTime?;
    });
  }
}
```

### 3. 高级搜索条件示例

```dart
class AdvancedSearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: const Text('高级搜索'),
      largeTitle: '搜索结果',
      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableAdvancedSearch: true,
      searchFilters: [
        _buildSearchFilterChip('类型', '全部'),
        _buildSearchFilterChip('状态', '进行中'),
        _buildSearchFilterChip('优先级', '高'),
      ],
      onAdvancedSearchChanged: (filters) {
        debugPrint('搜索条件变更: $filters');
      },
    );
  }

  Widget _buildSearchFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text('$label: $value'),
      selected: false,
      onSelected: (selected) {
        // 处理选择
      },
    );
  }
}
```

## 笔记插件应用示例

### 重构前的代码

```dart
// 传统实现方式 - 使用 Scaffold 和 AppBar
class NotesMainView extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                onChanged: handleSearch,
              )
            : Text(currentFolder?.name ?? '笔记'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Filter Bar - 需要手动实现
          SliverToBoxAdapter(
            child: _buildFilterBar(),
          ),
          // 笔记列表
          SliverList(...),
        ],
      ),
    );
  }
}
```

### 重构后的代码

```dart
// 使用 SuperCupertinoNavigationWrapper - 现代化实现
class NotesMainView extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text(currentFolder?.name ?? '笔记'),
      largeTitle: '我的笔记',
      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableFilterBar: true,
      filterBarHeight: 50,
      filterBarChild: _buildFilterBar(),
      searchPlaceholder: '搜索笔记、标签、内容...',
      onSearchChanged: _handleSearchChanged,
      onSearchSubmitted: _handleSearchSubmitted,
      onFilterChanged: _handleFilterChanged,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
      largeTitleActions: [
        IconButton(
          icon: const Icon(Icons.grid_view),
          onPressed: _toggleViewMode,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showAdvancedFilters,
        ),
      ],
      onCollapsed: (isCollapsed) {
        if (isCollapsed) {
          _saveScrollPosition();
        }
      },
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.folder_outlined,
            label: currentFolder?.name ?? 'Root',
            onTap: _showFolderPicker,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.label_outline,
            label: _selectedTag ?? 'All Tags',
            onTap: _showTagPicker,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.calendar_today,
            label: _selectedDate != null
                ? DateFormat('yyyy/MM/dd').format(_selectedDate!)
                : 'All Dates',
            onTap: _showDatePicker,
          ),
        ],
      ),
    );
  }

  void _handleSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        loadCurrentFolder();
      });
    } else {
      setState(() {
        isSearching = true;
      });
      handleSearch(query);
      if (_selectedTag != null || _selectedDate != null) {
        notes = plugin.controller.searchNotes(
          query: query,
          tags: _selectedTag != null ? [_selectedTag!] : null,
          startDate: _selectedDate,
          endDate: _selectedDate,
        );
      }
    }
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      _selectedTag = filters['tag'] as String?;
      _selectedDate = filters['date'] as DateTime?;
      _applyFilters();
    });
  }
}
```

## API 参考

### 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | `Widget` | - | 导航栏标题（必需） |
| `body` | `Widget` | - | 页面主体内容（必需） |
| `largeTitle` | `String` | `''` | 大标题文本 |
| `enableLargeTitle` | `bool` | `true` | 是否启用大标题 |
| `enableSearchBar` | `bool` | `false` | 是否启用搜索栏 |
| `enableFilterBar` | `bool` | `false` | 是否启用过滤栏 |
| `filterBarHeight` | `double` | `50` | 过滤栏高度 |
| `filterBarChild` | `Widget?` | `null` | 过滤栏内容 |
| `onFilterChanged` | `Function(Map)?` | `null` | 过滤条件变更回调 |
| `enableAdvancedSearch` | `bool` | `false` | 是否启用高级搜索 |
| `searchFilters` | `List<Widget>?` | `null` | 搜索条件筛选器 |
| `onAdvancedSearchChanged` | `Function(Map)?` | `null` | 高级搜索变更回调 |
| `searchPlaceholder` | `String` | `'搜索'` | 搜索框占位符 |
| `onSearchChanged` | `Function(String)?` | `null` | 搜索文本变化回调 |
| `onSearchSubmitted` | `Function(String)?` | `null` | 搜索提交回调 |
| `actions` | `List<Widget>?` | `null` | 导航栏操作按钮 |
| `largeTitleActions` | `List<Widget>?` | `null` | 大标题操作按钮 |
| `backgroundColor` | `Color?` | `null` | 背景颜色 |
| `automaticallyImplyLeading` | `bool` | `true` | 自动返回按钮 |
| `previousPageTitle` | `String?` | `null` | 返回按钮文字 |
| `onCollapsed` | `Function(bool)?` | `null` | 折叠状态回调 |
| `stretch` | `bool` | `true` | 拉伸效果 |

## 最佳实践

### 1. 过滤栏设计

```dart
// ✅ 推荐：简洁明了的过滤条件
Widget _buildFilterBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('全部分类', Icons.category),
          const SizedBox(width: 8),
          _buildFilterChip('全部状态', Icons.info_outline),
        ],
      ),
    ),
  );
}

// ❌ 避免：过多或过于复杂的过滤条件
```

### 2. 搜索实现

```dart
// ✅ 推荐：实时搜索 + 防抖处理
void _onSearchChanged(String query) {
  _debounce(() {
    final results = _performSearch(query);
    setState(() => _filteredResults = results);
  }, const Duration(milliseconds: 300));
}

// ❌ 避免：在每次按键时立即执行搜索（性能问题）
```

### 3. 状态管理

```dart
// ✅ 推荐：使用 setState 管理本地状态
void _handleFilterChanged(Map<String, dynamic> filters) {
  setState(() {
    _currentFilters = filters;
    _applyFilters();
  });
}

// ❌ 避免：直接修改状态而不调用 setState
```

### 4. 回调处理

```dart
// ✅ 推荐：统一处理搜索和过滤条件
void _handleSearchChanged(String query) {
  _searchQuery = query;
  _applyAllFilters();
}

void _handleFilterChanged(Map<String, dynamic> filters) {
  _currentFilters = filters;
  _applyAllFilters();
}

void _applyAllFilters() {
  final results = plugin.controller.searchNotes(
    query: _searchQuery,
    ..._currentFilters,
  );
  setState(() => _filteredResults = results);
}
```

## 常见问题

### Q1: 如何自定义搜索栏样式？

A: 通过修改 `SuperCupertinoNavigationWrapper` 的内部实现，或在 `searchFilters` 中添加自定义筛选器。

```dart
SuperCupertinoNavigationWrapper(
  // ... 其他参数
  enableAdvancedSearch: true,
  searchFilters: [
    _buildCustomSearchInput(),
  ],
);

Widget _buildCustomSearchInput() {
  return Container(
    width: 200,
    child: TextField(
      decoration: InputDecoration(
        hintText: '自定义搜索...',
        prefixIcon: Icon(Icons.search),
      ),
    ),
  );
}
```

### Q2: 如何处理搜索历史？

A: 在 `onSearchSubmitted` 回调中保存搜索历史，并在 `onSearchChanged` 中显示历史建议。

```dart
List<String> _searchHistory = [];

void _onSearchSubmitted(String query) {
  if (query.isNotEmpty && !_searchHistory.contains(query)) {
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory.removeLast();
    }
  }
}

void _onSearchChanged(String query) {
  if (query.isEmpty) {
    _showSearchHistory();
  } else {
    _performSearch(query);
  }
}
```

### Q3: 如何实现多选过滤？

A: 使用 `ChoiceChip` 或 `FilterChip` 组合实现多选过滤。

```dart
Widget _buildMultiSelectFilter() {
  return Wrap(
    spacing: 8,
    children: _availableTags.map((tag) {
      return FilterChip(
        label: Text(tag),
        selected: _selectedTags.contains(tag),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedTags.add(tag);
            } else {
              _selectedTags.remove(tag);
            }
            _applyFilters();
          });
        },
      );
    }).toList(),
  );
}
```

### Q4: 如何在过滤栏中添加清除按钮？

A: 检查过滤条件是否为空，决定是否显示清除按钮。

```dart
Widget _buildFilterBar() {
  return Row(
    children: [
      _buildFilterChip(...),
      if (_hasActiveFilters) _buildClearButton(),
    ],
  );
}

bool get _hasActiveFilters =>
    _selectedTag != null ||
    _selectedDate != null ||
    _searchQuery.isNotEmpty;
```

## 更新日志

### v2.0.0 (当前版本)
- ✨ 新增过滤栏支持 (`enableFilterBar`, `filterBarChild`)
- ✨ 新增高级搜索条件支持 (`enableAdvancedSearch`, `searchFilters`)
- ✨ 新增过滤条件变更回调 (`onFilterChanged`)
- ✨ 新增高级搜索变更回调 (`onAdvancedSearchChanged`)
- 🔄 重构搜索栏回调，同时触发 `onSearchChanged` 和 `onAdvancedSearchChanged`
- 📚 更新文档和使用示例

### v1.0.0
- 🎉 初始版本，支持大标题、搜索栏、底部栏

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个组件！

### 提交流程

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 遵循 Dart 代码风格指南
- 为公共 API 添加文档注释
- 编写单元测试（如果适用）
- 确保所有测试通过

## 许可证

本项目采用 MIT 许可证。详情请查看 [LICENSE](../LICENSE) 文件。

---

**维护者**: Memento 开发团队
**最后更新**: 2025-12-05
