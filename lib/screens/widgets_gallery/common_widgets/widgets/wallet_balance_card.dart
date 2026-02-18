import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 钱包余额概览卡片小组件
///
/// 显示钱包余额、可用余额、收入支出统计和操作按钮
class WalletBalanceCardWidget extends StatefulWidget {
  /// 头像 URL
  final String avatarUrl;

  /// 可用余额
  final double availableBalance;

  /// 总余额
  final double totalBalance;

  /// 变化百分比
  final int changePercent;

  /// 收入
  final double income;

  /// 支出
  final double expenses;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const WalletBalanceCardWidget({
    super.key,
    required this.avatarUrl,
    required this.availableBalance,
    required this.totalBalance,
    required this.changePercent,
    required this.income,
    required this.expenses,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static WalletBalanceCardWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return WalletBalanceCardWidget(
      avatarUrl: props['avatarUrl'] as String? ?? '',
      availableBalance: (props['availableBalance'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (props['totalBalance'] as num?)?.toDouble() ?? 0.0,
      changePercent: props['changePercent'] as int? ?? 0,
      income: (props['income'] as num?)?.toDouble() ?? 0.0,
      expenses: (props['expenses'] as num?)?.toDouble() ?? 0.0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<WalletBalanceCardWidget> createState() =>
      _WalletBalanceCardWidgetState();
}

class _WalletBalanceCardWidgetState extends State<WalletBalanceCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = const Color(0xFF18181B);
    final btnSecondaryColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6);

    // 计算进度比例
    final progress = (widget.availableBalance / widget.totalBalance).clamp(
      0.0,
      1.0,
    );

    // 根据尺寸计算各元素大小
    final iconSize = widget.size.getIconSize();
    final avatarSize = iconSize * widget.size.iconContainerScale;
    final labelFontSize = widget.size.getSubtitleFontSize();
    final balanceFontSize = widget.size.getTitleFontSize() * 0.5;
    final changePercentFontSize = widget.size.getLegendFontSize();
    final changePercentPadding = EdgeInsets.symmetric(
      horizontal: widget.size.getSmallSpacing() * 2,
      vertical: widget.size.getSmallSpacing(),
    );
    final progressHeight = widget.size.getStrokeWidth() * 0.5;
    final indicatorSize = widget.size.getIconSize() * 0.8;
    final indicatorBorderWidth = widget.size.getStrokeWidth() * 0.3;
    final statFontSize = widget.size.getSubtitleFontSize();
    final buttonHeight = iconSize * widget.size.iconContainerScale;
    final buttonFontSize = widget.size.getSubtitleFontSize() * 1.2;
    final buttonIconSize = iconSize;

    return Container(
      width: widget.inline ? double.maxFinite : 340,
      padding: widget.size.getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 头像和余额信息
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  widget.avatarUrl,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: avatarSize,
                      height: avatarSize,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.person, size: iconSize * 0.6),
                    );
                  },
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)} Available',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: widget.size.getItemSpacing() / 2),
                    Row(
                      children: [
                        AnimatedFlipCounter(
                          value: widget.totalBalance * _animation.value,
                          fractionDigits: 2,
                          prefix: '\$',
                          textStyle: TextStyle(
                            fontSize: balanceFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(width: widget.size.getItemSpacing()),
                        Container(
                          padding: changePercentPadding,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.green.shade900.withOpacity(0.4)
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${widget.changePercent}%',
                            style: TextStyle(
                              fontSize: changePercentFontSize,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? Colors.green.shade400
                                      : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 进度条
          _buildProgressBar(
            isDark,
            primaryColor,
            progress,
            widget.income,
            widget.expenses,
            progressHeight,
            indicatorSize,
            indicatorBorderWidth,
            statFontSize,
          ),
          const Spacer(),

          // 操作按钮 - 固定在底部
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Send',
                  primaryColor,
                  Colors.white,
                  buttonHeight,
                  buttonFontSize,
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Receive',
                  btnSecondaryColor,
                  isDark ? Colors.white : Colors.grey.shade900,
                  buttonHeight,
                  buttonFontSize,
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              _buildAddButton(
                isDark,
                btnSecondaryColor,
                buttonHeight,
                buttonIconSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    bool isDark,
    Color primaryColor,
    double progress,
    double income,
    double expenses,
    double height,
    double indicatorSize,
    double indicatorBorderWidth,
    double fontSize,
  ) {
    final isWideMode = widget.size is WideSize || widget.size is Wide2Size;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final progressWidth = constraints.maxWidth;
            // 限制圆点位置在有效范围内，避免超出边界
            final clampedProgress = (progress * _animation.value).clamp(
              indicatorSize / 2 / progressWidth,
              1 - indicatorSize / 2 / progressWidth,
            );
            final indicatorLeft =
                clampedProgress * progressWidth - indicatorSize / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress * _animation.value,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
                Positioned(
                  left: indicatorLeft,
                  top: -(indicatorSize - height) / 2,
                  child: Container(
                    width: indicatorSize,
                    height: indicatorSize,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade200 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor,
                        width: indicatorBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        // 非宽屏模式下换行显示，宽屏模式下并排显示
        if (isWideMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatLabel(isDark, 'Income:', '\$$income', fontSize),
              _buildStatLabel(isDark, 'Expenses:', '\$$expenses', fontSize),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatLabel(isDark, 'Income:', '\$$income', fontSize),
              SizedBox(height: widget.size.getSmallSpacing()),
              _buildStatLabel(isDark, 'Expenses:', '\$$expenses', fontSize),
            ],
          ),
      ],
    );
  }

  Widget _buildStatLabel(
    bool isDark,
    String label,
    String value,
    double fontSize,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing() / 2),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    bool isDark,
    String text,
    Color bgColor,
    Color textColor,
    double height,
    double fontSize,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height * 0.36),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAddButton(
    bool isDark,
    Color bgColor,
    double height,
    double iconSize,
  ) {
    return Container(
      width: height,
      height: height,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(
        Icons.add,
        color: isDark ? Colors.white : Colors.grey.shade900,
        size: iconSize,
      ),
    );
  }
}
