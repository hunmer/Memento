import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 圆角任务进度小组件
class RoundedTaskProgressWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int completedTasks;
  final int totalTasks;
  final List<String> pendingTasks;
  final int commentCount;
  final int attachmentCount;
  final List<String> teamAvatars;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const RoundedTaskProgressWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedTasks,
    required this.totalTasks,
    required this.pendingTasks,
    required this.commentCount,
    required this.attachmentCount,
    required this.teamAvatars,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RoundedTaskProgressWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return RoundedTaskProgressWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      completedTasks: props['completedTasks'] as int? ?? 0,
      totalTasks: props['totalTasks'] as int? ?? 0,
      pendingTasks:
          (props['pendingTasks'] as List<dynamic>?)?.cast<String>() ?? const [],
      commentCount: props['commentCount'] as int? ?? 0,
      attachmentCount: props['attachmentCount'] as int? ?? 0,
      teamAvatars:
          (props['teamAvatars'] as List<dynamic>?)?.cast<String>() ?? const [],
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<RoundedTaskProgressWidget> createState() =>
      _RoundedTaskProgressWidgetState();
}

class _RoundedTaskProgressWidgetState extends State<RoundedTaskProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (widget.completedTasks / widget.totalTasks).clamp(
      0.0,
      1.0,
    );

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * _progressAnimation.value,
          child: Opacity(
            opacity: _progressAnimation.value,
            child: Container(
              width: widget.inline ? double.maxFinite : 380,
              constraints: widget.size.getHeightConstraints(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40 * widget.size.scale,
                    offset: Offset(0, 20 * widget.size.scale),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      isDark: isDark,
                      size: widget.size,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing() * 0.5),
                    _ProgressSection(
                      completedTasks: widget.completedTasks,
                      totalTasks: widget.totalTasks,
                      progress: progress,
                      animation: _progressAnimation,
                      isDark: isDark,
                      size: widget.size,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing() * 0.5),
                    Expanded(
                      child: _PendingTasksSection(
                        tasks: widget.pendingTasks,
                        isDark: isDark,
                        size: widget.size,
                      ),
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    _FooterSection(
                      commentCount: widget.commentCount,
                      attachmentCount: widget.attachmentCount,
                      teamAvatars: widget.teamAvatars,
                      isDark: isDark,
                      size: widget.size,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final HomeWidgetSize size;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size.getTitleFontSize(),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
        SizedBox(height: size.getSmallSpacing()),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final double progress;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _ProgressSection({
    required this.completedTasks,
    required this.totalTasks,
    required this.progress,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: size.getIconSize() * 0.75,
                  color:
                      isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF9CA3AF),
                ),
                SizedBox(width: size.getSmallSpacing() * 2),
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            Text(
              '$completedTasks / $totalTasks',
              style: TextStyle(
                fontSize: size.getSubtitleFontSize(),
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        SizedBox(height: size.getSmallSpacing() * 2),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4 * size.scale),
              child: Stack(
                children: [
                  Container(
                    height: size.getStrokeWidth(),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress * animation.value,
                    child: Container(
                      height: size.getStrokeWidth(),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4 * size.scale),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PendingTasksSection extends StatefulWidget {
  final List<String> tasks;
  final bool isDark;
  final HomeWidgetSize size;

  const _PendingTasksSection({
    required this.tasks,
    required this.isDark,
    required this.size,
  });

  @override
  State<_PendingTasksSection> createState() => _PendingTasksSectionState();
}

class _PendingTasksSectionState extends State<_PendingTasksSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending',
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            color:
                widget.isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF9CA3AF),
          ),
        ),
        SizedBox(height: widget.size.getSmallSpacing() * 2),
        Expanded(
          child: Scrollbar(
            thickness: 6 * widget.size.scale,
            radius: Radius.circular(3 * widget.size.scale),
            thumbVisibility: false,
            controller: _scrollController,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  widget.tasks.length,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.size.getSmallSpacing(),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                widget.isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFF3F4F6),
                            width: 1 * widget.size.scale,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.tasks[index],
                        style: TextStyle(
                          fontSize: widget.size.getSubtitleFontSize(),
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isDark
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  final int commentCount;
  final int attachmentCount;
  final List<String> teamAvatars;
  final bool isDark;
  final HomeWidgetSize size;

  const _FooterSection({
    required this.commentCount,
    required this.attachmentCount,
    required this.teamAvatars,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _ActionButton(
              icon: Icons.chat_bubble_outline,
              count: commentCount,
              isDark: isDark,
              size: size,
            ),
            SizedBox(width: size.getSmallSpacing() * 5),
            _ActionButton(
              icon: Icons.attach_file,
              count: attachmentCount,
              rotate: true,
              isDark: isDark,
              size: size,
            ),
          ],
        ),
        Row(
          children: List.generate(
            teamAvatars.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? size.getSmallSpacing() * 3 : 0,
              ),
              child: Container(
                width: size.getIconSize(),
                height: size.getIconSize(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 2 * size.scale,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    teamAvatars[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color:
                            isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                        child: Icon(
                          Icons.person,
                          size: 16 * size.scale,
                          color:
                              isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool rotate;
  final bool isDark;
  final HomeWidgetSize size;

  const _ActionButton({
    required this.icon,
    required this.count,
    this.rotate = false,
    required this.isDark,
    required this.size,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            Transform.rotate(
              angle: widget.rotate ? 45 * 3.14159 / 180 : 0,
              child: Icon(
                widget.icon,
                size: widget.size.getIconSize() * 0.75,
                color:
                    _isHovered
                        ? (widget.isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF4B5563))
                        : (widget.isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF9CA3AF)),
              ),
            ),
            SizedBox(width: widget.size.getSmallSpacing()),
            Text(
              widget.count.toString(),
              style: TextStyle(
                fontSize: widget.size.getLegendFontSize(),
                fontWeight: FontWeight.w600,
                color:
                    _isHovered
                        ? (widget.isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF4B5563))
                        : (widget.isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
