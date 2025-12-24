import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/index.dart';
import 'components/selector_header.dart';
import 'components/selector_breadcrumb.dart';
import 'components/selector_search_bar.dart';
import 'views/list_selection_view.dart';
import 'views/grid_selection_view.dart';
import 'views/calendar_selection_view.dart';

/// 数据选择器 Sheet
///
/// 使用 smooth_sheets 实现多级导航的数据选择器
class DataSelectorSheet extends StatefulWidget {
  /// 选择器定义
  final SelectorDefinition definition;

  /// 选择器配置
  final SelectorConfig config;

  const DataSelectorSheet({
    super.key,
    required this.definition,
    required this.config,
  });

  @override
  State<DataSelectorSheet> createState() => _DataSelectorSheetState();
}

class _DataSelectorSheetState extends State<DataSelectorSheet> {
  // 当前步骤索引
  int _currentStepIndex = 0;

  // 选择路径记录
  final List<SelectionPathItem> _selectionPath = [];

  // 已选数据 (步骤ID -> 选中项的 rawData)
  final Map<String, dynamic> _selections = {};

  // 搜索关键词
  String _searchQuery = '';

  // 当前步骤数据
  List<SelectableItem> _currentItems = [];

  // 加载状态
  bool _isLoading = false;

  // 错误信息
  String? _errorMessage;

  // 多选模式下的选中项 ID
  final Set<String> _selectedIds = {};

  // 导航历史（用于页面切换动画）
  final List<int> _navigationHistory = [0];

  SelectorStep get _currentStep => widget.definition.steps[_currentStepIndex];

  Color get _themeColor =>
      widget.config.themeColor ??
      widget.definition.color ??
      Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _loadCurrentStepData();
  }

  Future<void> _loadCurrentStepData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _currentStep.dataLoader(_selections);
      if (mounted) {
        setState(() {
          _currentItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载数据失败: $e';
        });
      }
      debugPrint('加载选择器数据失败: $e');
    }
  }

  void _onItemSelected(SelectableItem item) {
    if (widget.definition.selectionMode == SelectionMode.multiple &&
        _currentStep.isFinalStep) {
      // 多选模式：切换选中状态
      setState(() {
        if (_selectedIds.contains(item.id)) {
          _selectedIds.remove(item.id);
        } else {
          // 检查最大选择数量
          if (widget.definition.maxSelectionCount > 0 &&
              _selectedIds.length >= widget.definition.maxSelectionCount) {
            _showMaxSelectionWarning();
            return;
          }
          _selectedIds.add(item.id);
        }
      });
    } else {
      // 单选模式或非最终步骤
      _selections[_currentStep.id] = item.rawData;
      _selectionPath.add(SelectionPathItem(
        stepId: _currentStep.id,
        stepTitle: _currentStep.title,
        selectedItem: item,
      ));

      if (_currentStep.isFinalStep) {
        // 完成选择
        _completeSelection(item.rawData);
      } else {
        // 进入下一步
        setState(() {
          _currentStepIndex++;
          _navigationHistory.add(_currentStepIndex);
          _searchQuery = '';
          _selectedIds.clear();
        });
        _loadCurrentStepData();
      }
    }
  }

  void _showMaxSelectionWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('最多只能选择 ${widget.definition.maxSelectionCount} 项'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goBack() {
    if (_currentStepIndex > 0) {
      // 移除当前步骤的选择
      _selections.remove(_currentStep.id);
      if (_selectionPath.isNotEmpty) {
        _selectionPath.removeLast();
      }
      _navigationHistory.removeLast();

      setState(() {
        _currentStepIndex--;
        _searchQuery = '';
        _selectedIds.clear();
      });
      _loadCurrentStepData();
    } else {
      // 取消选择
      _cancelSelection();
    }
  }

  void _navigateToStep(int index) {
    if (index < _currentStepIndex) {
      // 移除后续选择
      while (_selectionPath.length > index) {
        final removed = _selectionPath.removeLast();
        _selections.remove(removed.stepId);
      }

      setState(() {
        _currentStepIndex = index;
        _navigationHistory.removeRange(index + 1, _navigationHistory.length);
        _searchQuery = '';
        _selectedIds.clear();
      });
      _loadCurrentStepData();
    }
  }

  void _completeSelection(dynamic data) {
    final result = SelectorResult(
      pluginId: widget.definition.pluginId,
      selectorId: widget.definition.id,
      path: _selectionPath,
      data: data,
    );
    Navigator.of(context).pop(result);
  }

  void _confirmMultiSelection() {
    // 获取所有选中的项
    final selectedItems = _currentItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一项'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = MultiSelectorResult(
      pluginId: widget.definition.pluginId,
      selectorId: widget.definition.id,
      path: _selectionPath,
      selectedItems: selectedItems,
    );
    Navigator.of(context).pop(result);
  }

  void _cancelSelection() {
    Navigator.of(context).pop(SelectorResult.cancelled());
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  List<SelectableItem> get _filteredItems {
    return _currentStep.performSearch(_currentItems, _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * widget.config.minHeightRatio,
        maxHeight: MediaQuery.of(context).size.height * widget.config.maxHeightRatio,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          SelectorHeader(
            title: widget.config.title ?? widget.definition.name,
            stepTitle: _currentStep.title,
            themeColor: _themeColor,
            showBackButton: _currentStepIndex > 0,
            showCloseButton: widget.config.showCloseButton,
            onBack: _currentStepIndex > 0 ? _goBack : null,
            onClose: _cancelSelection,
          ),

          // 面包屑导航
          if (widget.config.showBreadcrumb && _selectionPath.isNotEmpty)
            SelectorBreadcrumb(
              path: _selectionPath,
              currentStep: _currentStep.title,
              themeColor: _themeColor,
              allowTap: widget.config.allowBackNavigation,
              onStepTap: widget.config.allowBackNavigation ? _navigateToStep : null,
            ),

          // 搜索框
          if (widget.definition.searchable && widget.config.showSearch)
            SelectorSearchBar(
              hintText: widget.config.searchHint ?? '搜索${_currentStep.title}...',
              themeColor: _themeColor,
              onSearch: _onSearchChanged,
            ),

          // 内容区域
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildContent(),
            ),
          ),

          // 多选模式的底部确认栏
          if (widget.definition.selectionMode == SelectionMode.multiple &&
              _currentStep.isFinalStep)
            _buildMultiSelectFooter(theme),

          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }


  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _themeColor),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentStepData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey('step_$_currentStepIndex'),
      child: _buildSelectionView(),
    );
  }

  Widget _buildSelectionView() {
    final items = _filteredItems;

    switch (_currentStep.viewType) {
      case SelectorViewType.list:
        return ListSelectionView(
          items: items,
          onItemSelected: _onItemSelected,
          selectionMode: widget.definition.selectionMode,
          selectedIds: _selectedIds,
          themeColor: _themeColor,
          emptyText: _currentStep.emptyText,
          emptyWidget: widget.config.emptyStateWidget,
        );

      case SelectorViewType.grid:
        return GridSelectionView(
          items: items,
          onItemSelected: _onItemSelected,
          selectionMode: widget.definition.selectionMode,
          selectedIds: _selectedIds,
          themeColor: _themeColor,
          emptyText: _currentStep.emptyText,
          emptyWidget: widget.config.emptyStateWidget,
          crossAxisCount: _currentStep.gridCrossAxisCount,
          childAspectRatio: _currentStep.gridChildAspectRatio,
        );

      case SelectorViewType.calendar:
        return CalendarSelectionView(
          items: items,
          onItemSelected: _onItemSelected,
          selectionMode: widget.definition.selectionMode,
          selectedIds: _selectedIds,
          themeColor: _themeColor,
          emptyText: _currentStep.emptyText,
          emptyWidget: widget.config.emptyStateWidget,
        );
    }
  }

  Widget _buildMultiSelectFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 选中数量
          Text(
            '已选择 ${_selectedIds.length} 项',
            style: theme.textTheme.bodyMedium,
          ),
          if (widget.definition.maxSelectionCount > 0)
            Text(
              ' / ${widget.definition.maxSelectionCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          const Spacer(),
          // 取消按钮
          TextButton(
            onPressed: _cancelSelection,
            child: Text(widget.config.cancelText ?? '取消'),
          ),
          const SizedBox(width: 8),
          // 确认按钮
          FilledButton(
            onPressed: _selectedIds.isNotEmpty ? _confirmMultiSelection : null,
            style: FilledButton.styleFrom(
              backgroundColor: _themeColor,
            ),
            child: Text(widget.config.confirmText ?? '确定'),
          ),
        ],
      ),
    );
  }
}
