import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 账户余额卡片示例
class AccountBalanceCardExample extends StatelessWidget {
  const AccountBalanceCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('账户余额卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: AccountBalanceCardWidget(
            accountName: 'Citibank',
            currency: 'USD',
            balance: 1964.45,
            income: 4700,
            expense: 2800,
          ),
        ),
      ),
    );
  }
}

/// 账户余额小组件
class AccountBalanceCardWidget extends StatefulWidget {
  /// 账户名称（如银行名）
  final String accountName;

  /// 货币代码
  final String currency;

  /// 当前余额
  final double balance;

  /// 收入金额
  final double income;

  /// 支出金额
  final double expense;

  const AccountBalanceCardWidget({
    super.key,
    required this.accountName,
    required this.currency,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<AccountBalanceCardWidget> createState() =>
      _AccountBalanceCardWidgetState();
}

class _AccountBalanceCardWidgetState extends State<AccountBalanceCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late List<Animation<double>> _statAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // 为收入和支出创建延迟动画
    _statAnimations = List.generate(
      2,
      (index) => CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.3 + index * 0.15,
          0.6 + index * 0.15,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant AccountBalanceCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当数据变化时，重新播放动画以更新 UI
    if (oldWidget.balance != widget.balance ||
        oldWidget.income != widget.income ||
        oldWidget.expense != widget.expense) {
      _animationController.forward(from: 0);
    }
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
      animation: Listenable.merge([..._statAnimations, _fadeInAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：账户名称 + 货币标签
                  _buildHeader(isDark),
                  // 中部：余额显示
                  _buildBalanceSection(isDark),
                  // 底部：收入/支出统计
                  _buildStatsSection(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头部（账户名称 + 货币标签）
  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.accountName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.currency.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93),
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建余额部分
  Widget _buildBalanceSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 180,
                height: 52,
                child: AnimatedFlipCounter(
                  value: widget.balance * _fadeInAnimation.value,
                  fractionDigits: 2,
                  textStyle: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: Text(
            'Current balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93),
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建统计部分（收入/支出）
  Widget _buildStatsSection(bool isDark) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.north,
          iconColor: const Color(0xFF10B981), // Emerald green
          value: widget.income,
          isDark: isDark,
          index: 0,
        ),
        const SizedBox(width: 32),
        _buildStatItem(
          icon: Icons.south,
          iconColor: const Color(0xFFF43F5E), // Rose red
          value: widget.expense,
          isDark: isDark,
          index: 1,
        ),
      ],
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required double value,
    required bool isDark,
    required int index,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 24,
          child: AnimatedFlipCounter(
            value: value * _statAnimations[index].value,
            fractionDigits: value % 1 != 0 ? 1 : 0,
            prefix: value >= 1000 ? '' : '',
            suffix: value >= 1000 ? 'k' : '',
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
