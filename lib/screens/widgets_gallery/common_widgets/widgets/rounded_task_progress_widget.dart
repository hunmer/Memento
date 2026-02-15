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
      pendingTasks: (props['pendingTasks'] as List<dynamic>?)?.cast<String>() ?? const [],
      commentCount: props['commentCount'] as int? ?? 0,
      attachmentCount: props['attachmentCount'] as int? ?? 0,
      teamAvatars: (props['teamAvatars'] as List<dynamic>?)?.cast<String>() ?? const [],
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<RoundedTaskProgressWidget> createState() => _RoundedTaskProgressWidgetState();
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
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
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
    final progress = (widget.completedTasks / widget.totalTasks).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * _progressAnimation.value,
          child: Opacity(
            opacity: _progressAnimation.value,
            child: Container(
              width: widget.inline ? double.maxFinite : 380,
              constraints: const BoxConstraints(minHeight: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(title: widget.title, subtitle: widget.subtitle, isDark: isDark),
                    const SizedBox(height: 32),
                    _ProgressSection(
                      completedTasks: widget.completedTasks,
                      totalTasks: widget.totalTasks,
                      progress: progress,
                      animation: _progressAnimation,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),
                    _PendingTasksSection(tasks: widget.pendingTasks, isDark: isDark),
                    const SizedBox(height: 32),
                    _FooterSection(
                      commentCount: widget.commentCount,
                      attachmentCount: widget.attachmentCount,
                      teamAvatars: widget.teamAvatars,
                      isDark: isDark,
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

  const _HeaderSection({required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937), height: 1.2)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF))),
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

  const _ProgressSection({
    required this.completedTasks,
    required this.totalTasks,
    required this.progress,
    required this.animation,
    required this.isDark,
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
                Icon(Icons.format_list_bulleted, size: 18, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Text('Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF))),
              ],
            ),
            Text('$completedTasks / $totalTasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress * animation.value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(4)),
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

class _PendingTasksSection extends StatelessWidget {
  final List<String> tasks;
  final bool isDark;

  const _PendingTasksSection({required this.tasks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF))),
        const SizedBox(height: 8),
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                tasks.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6), width: 1))),
                    child: Text(tasks[index], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937), height: 1.3)),
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

  const _FooterSection({
    required this.commentCount,
    required this.attachmentCount,
    required this.teamAvatars,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _ActionButton(icon: Icons.chat_bubble_outline, count: commentCount, isDark: isDark),
            const SizedBox(width: 20),
            _ActionButton(icon: Icons.attach_file, count: attachmentCount, rotate: true, isDark: isDark),
          ],
        ),
        Row(
          children: List.generate(
            teamAvatars.length,
            (index) => Padding(
              padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    teamAvatars[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        child: Icon(Icons.person, size: 16, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
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

  const _ActionButton({required this.icon, required this.count, this.rotate = false, required this.isDark});

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
                size: 18,
                color: _isHovered ? (widget.isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563)) : (widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isHovered ? (widget.isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563)) : (widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
