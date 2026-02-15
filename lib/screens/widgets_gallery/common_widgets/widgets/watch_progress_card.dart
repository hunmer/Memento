import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 观看项目数据模型
class WatchProgressItem {
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;

  const WatchProgressItem({
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
  });

  /// 从 JSON 创建
  factory WatchProgressItem.fromJson(Map<String, dynamic> json) {
    return WatchProgressItem(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'title': title, 'subtitle': subtitle, 'thumbnailUrl': thumbnailUrl};
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

  /// 进度描述文本（如 "Watched Items"）
  final String progressLabel;

  const WatchProgressCardWidget({
    super.key,
    required this.userName,
    required this.lastWatched,
    required this.currentCount,
    required this.totalCount,
    required this.items,
    this.progressColor,
    this.inline = false,
    this.size = const MediumSize(),
    this.enableHeader = true,
    this.progressLabel = 'Watched Items',
  });

  /// 从 props 创建实例
  factory WatchProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = props['items'] as List<dynamic>?;
    final items =
        itemsList
            ?.map(
              (item) =>
                  item is Map<String, dynamic>
                      ? WatchProgressItem.fromJson(item)
                      : null,
            )
            .whereType<WatchProgressItem>()
            .toList() ??
        [];

    return WatchProgressCardWidget(
      userName: props['userName'] as String? ?? 'User',
      lastWatched: props['lastWatched'] as String? ?? '',
      currentCount: props['currentCount'] as int? ?? 0,
      totalCount: props['totalCount'] as int? ?? 0,
      items: items,
      progressColor:
          props['progressColor'] != null
              ? Color(props['progressColor'] as int)
              : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
      enableHeader: props['enableHeader'] as bool? ?? true,
      progressLabel: props['progressLabel'] as String? ?? 'Watched Items',
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
      'progressLabel': progressLabel,
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
  late ScrollController _scrollController;
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
    _scrollController = ScrollController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    isDark
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
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
      children.add(SizedBox(height: widget.size.getSmallSpacing()));
    }

    children.add(_buildProgressSection(isDark, index, step));
    index++;
    children.add(SizedBox(height: widget.size.getSmallSpacing()));
    // 使用 Expanded 让 items list 自适应剩余空间
    children.add(Expanded(child: _buildItemsList(isDark, step, index)));

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
              width: widget.size.getIconSize() * widget.size.iconContainerScale,
              height:
                  widget.size.getIconSize() * widget.size.iconContainerScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.white,
                  width: 2 * widget.size.scale,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  child: Icon(Icons.person, size: widget.size.getIconSize()),
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
                      fontSize: widget.size.getTitleFontSize() - 6,
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
                      fontSize: widget.size.getLegendFontSize(),
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

    final progress = (widget.currentCount / widget.totalCount).clamp(0.0, 1.0);
    final effectiveProgressColor =
        widget.progressColor ??
        (isDark ? Colors.white : const Color(0xFF111827));

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
                    fontSize: widget.size.getLargeFontSize() - 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing() * 0.25),
                Text(
                  '/${widget.totalCount}',
                  style: TextStyle(
                    fontSize: widget.size.getLargeFontSize() - 24,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.size.getItemSpacing() * 0.25),
            Text(
              widget.progressLabel,
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize(),
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
              ),
            ),
            SizedBox(height: widget.size.getItemSpacing()),
            Container(
              height:
                  widget.size.getStrokeWidth() *
                  widget.size.progressStrokeScale *
                  2,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(
                  widget.size.getStrokeWidth() *
                      widget.size.progressStrokeScale,
                ),
              ),
              child: FractionallySizedBox(
                widthFactor: progress * itemAnimation.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveProgressColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        widget.size.getStrokeWidth() *
                            widget.size.progressStrokeScale,
                      ),
                      bottomLeft: Radius.circular(
                        widget.size.getStrokeWidth() *
                            widget.size.progressStrokeScale,
                      ),
                      topRight: Radius.circular(
                        widget.size.getStrokeWidth() *
                            widget.size.progressStrokeScale *
                            0.33,
                      ),
                      bottomRight: Radius.circular(
                        widget.size.getStrokeWidth() *
                            widget.size.progressStrokeScale *
                            0.33,
                      ),
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

    // 计算每个 item 的实际高度（考虑图标容器和文本）
    // 图标容器高度: getIconSize() * 1.5
    // 文本高度: getSubtitleFontSize()
    // 副标题高度: getLegendFontSize()（可选）
    // 间距: getItemSpacing()
    final itemHeight =
        (widget.size.getIconSize() * 1.5) +
        widget.size.getSubtitleFontSize() +
        widget.size.getSmallSpacing() * 2;

    // 使用 ConstrainedBox 设置最大高度约束，而不是固定高度
    final maxDisplayItems = widget.size.height >= 2 ? 3 : 2;
    final maxHeight = itemHeight * maxDisplayItems;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return (widget.progressColor ??
                  (isDark ? Colors.grey.shade600 : Colors.grey.shade400));
            }
            return (widget.progressColor ??
                    (isDark ? Colors.grey.shade700 : Colors.grey.shade300))
                .withOpacity(0.6);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
            }
            return Colors.transparent;
          }),
          thickness: WidgetStateProperty.all(4 * widget.size.scale),
          radius: const Radius.circular(2),
          crossAxisMargin: 2,
          mainAxisMargin: 2,
          minThumbLength: 24,
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    WatchProgressItem item,
    bool isDark,
    int index,
    double step,
  ) {
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
              width: widget.size.getIconSize(),
              height: widget.size.getIconSize(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              child: Icon(Icons.movie, size: widget.size.getIconSize() * 0.75),
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: widget.size.getSubtitleFontSize(),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: widget.size.getItemSpacing() * 0.2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: widget.size.getLegendFontSize(),
                        fontWeight: FontWeight.w400,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
