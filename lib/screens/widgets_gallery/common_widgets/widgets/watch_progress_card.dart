import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 观看项目数据模型
class WatchProgressItem {
  final String title;
  final String? thumbnailUrl;

  const WatchProgressItem({
    required this.title,
    this.thumbnailUrl,
  });

  /// 从 JSON 创建
  factory WatchProgressItem.fromJson(Map<String, dynamic> json) {
    return WatchProgressItem(
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// 观看进度卡片组件
///
/// 适用于媒体进度追踪场景，如观看电影、剧集、书籍等
class WatchProgressCardWidget extends StatefulWidget {
  /// 用户名称
  final String userName;

  /// 最后观看时间描述（如 "2 days ago"）
  final String lastWatched;

  /// 当前进度数量
  final int currentCount;

  /// 总数量
  final int totalCount;

  /// 观看项目列表
  final List<WatchProgressItem> items;

  /// 进度颜色
  final Color? progressColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  /// 是否启用头部
  final bool enableHeader;

  const WatchProgressCardWidget({
    super.key,
    required this.userName,
    required this.lastWatched,
    required this.currentCount,
    required this.totalCount,
    required this.items,
    this.progressColor,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
    this.enableHeader = true,
  });

  /// 从 props 创建实例
  factory WatchProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = props['items'] as List<dynamic>?;
    final items = itemsList
            ?.map((item) =>
                item is Map<String, dynamic>
                    ? WatchProgressItem.fromJson(item)
                    : null)
            .whereType<WatchProgressItem>()
            .toList() ??
        [];

    return WatchProgressCardWidget(
      userName: props['userName'] as String? ?? 'User',
      lastWatched: props['lastWatched'] as String? ?? '',
      currentCount: props['currentCount'] as int? ?? 0,
      totalCount: props['totalCount'] as int? ?? 0,
      items: items,
      progressColor: props['progressColor'] != null
          ? Color(props['progressColor'] as int)
          : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
      enableHeader: props['enableHeader'] as bool? ?? true,
    );
  }

  /// 转换为 props
  Map<String, dynamic> toProps() {
    return {
      'userName': userName,
      'lastWatched': lastWatched,
      'currentCount': currentCount,
      'totalCount': totalCount,
      'items': items.map((item) => item.toJson()).toList(),
      'progressColor': progressColor?.value,
      'enableHeader': enableHeader,
    };
  }

  @override
  State<WatchProgressCardWidget> createState() =>
      _WatchProgressCardWidgetState();
}

class _WatchProgressCardWidgetState extends State<WatchProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const double _baseEnd = 0.6;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    // 固定为3个元素：header(progress)、progressSection、itemsList
    final elementCount = 3;
    final maxStep = (1.0 - _baseEnd) / (elementCount - 1);
    final step = maxStep * 0.9;
    final headerOffset = widget.enableHeader ? 1 : 0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: widget.size.getPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildChildren(isDark, step, headerOffset),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren(bool isDark, double step, int headerOffset) {
    final List<Widget> children = [];
    int index = 0;

    if (widget.enableHeader) {
      children.add(_buildHeader(isDark, index, step));
      index++;
      children.add(SizedBox(height: widget.size.getTitleSpacing()));
    }

    children.add(_buildProgressSection(isDark, index, step));
    index++;
    children.add(SizedBox(height: widget.size.getTitleSpacing()));
    children.add(_buildItemsList(isDark, step, index));

    return children;
  }

  Widget _buildHeader(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    final hasTitle = widget.userName.isNotEmpty;
    final hasSubtitle = widget.lastWatched.isNotEmpty;

    // 如果标题和副标题都为空，返回空容器
    if (!hasTitle && !hasSubtitle) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.white,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 24),
                ),
              ),
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTitle)
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                if (hasTitle && hasSubtitle)
                  SizedBox(height: widget.size.getItemSpacing() * 0.15),
                if (hasSubtitle)
                  Text(
                    widget.lastWatched,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    final progress = widget.currentCount / widget.totalCount;
    final effectiveProgressColor =
        widget.progressColor ?? (isDark ? Colors.white : const Color(0xFF111827));

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.currentCount}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing() * 0.25),
                Text(
                  '/${widget.totalCount}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.size.getItemSpacing() * 0.25),
            Text(
              'Watched Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
              ),
            ),
            SizedBox(height: widget.size.getItemSpacing()),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: progress * itemAnimation.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveProgressColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      topRight: Radius.circular(1),
                      bottomRight: Radius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(bool isDark, double step, int index) {
    final items = <Widget>[];

    for (int i = 0; i < widget.items.length; i++) {
      if (i > 0) {
        items.add(SizedBox(height: widget.size.getItemSpacing() * 1.25));
      }
      items.add(_buildItem(widget.items[i], isDark, index, step));
    }

    // 计算每个 item 的近似高度，设置固定高度（最多显示 3 个 item）
    final itemHeight = widget.size.getItemSpacing() * 3;
    final listHeight = (itemHeight * widget.items.length).clamp(itemHeight * 2, itemHeight * 3);

    return SizedBox(
      height: listHeight,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(WatchProgressItem item, bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              child: const Icon(Icons.movie, size: 20),
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
