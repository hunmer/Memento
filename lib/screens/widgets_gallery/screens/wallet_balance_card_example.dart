import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 钱包余额概览卡片示例
class WalletBalanceCardExample extends StatelessWidget {
  const WalletBalanceCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('钱包余额概览卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: WalletBalanceCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
            availableBalance: 8317.45,
            totalBalance: 12682.50,
            changePercent: 12,
            income: 24000,
            expenses: 1720,
          ),
        ),
      ),
    );
  }
}

/// 钱包余额概览小组件
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

  const WalletBalanceCardWidget({
    super.key,
    required this.avatarUrl,
    required this.availableBalance,
    required this.totalBalance,
    required this.changePercent,
    required this.income,
    required this.expenses,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory WalletBalanceCardWidget.fromProps(
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
    final progress = widget.availableBalance / widget.totalBalance;

    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像和余额信息
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  widget.avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)} Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AnimatedFlipCounter(
                          value: widget.totalBalance * _animation.value,
                          fractionDigits: 2,
                          prefix: '\$',
                          textStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.shade900.withOpacity(0.4)
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${widget.changePercent}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
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
          const SizedBox(height: 32),

          // 进度条
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress * _animation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (progress * 300) - 10,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade200 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
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
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatLabel(isDark, 'Income:', '\$${widget.income}'),
                  _buildStatLabel(isDark, 'Expenses:', '\$${widget.expenses}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Send',
                  primaryColor,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  isDark,
                  'Receive',
                  btnSecondaryColor,
                  isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(width: 12),
              _buildAddButton(isDark, btnSecondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(bool isDark, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
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
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark, Color bgColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        color: isDark ? Colors.white : Colors.grey.shade900,
        size: 24,
      ),
    );
  }
}
