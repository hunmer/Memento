import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// 金额输入框组件
///
/// 用于账单编辑界面的金额输入，带有货币符号前缀和特殊样式
class AmountInputField extends StatefulWidget {
  /// 当前金额
  final double? amount;

  /// 金额变化回调
  final ValueChanged<double?> onAmountChanged;

  /// 文本控制器（可选）
  final TextEditingController? controller;

  /// 货币符号
  final String currencySymbol;

  /// 金额颜色（用于高亮显示）
  final Color? amountColor;

  /// 字体大小
  final double fontSize;

  /// 是否启用
  final bool enabled;

  /// 验证器
  final FormFieldValidator<String>? validator;

  const AmountInputField({
    super.key,
    required this.amount,
    required this.onAmountChanged,
    this.controller,
    this.currencySymbol = '¥',
    this.amountColor,
    this.fontSize = 40,
    this.enabled = true,
    this.validator,
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  late TextEditingController _controller;
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey();

  /// 标记是否为用户输入导致的更新，避免在输入时被子组件的值覆盖
  bool _isUserInput = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _updateText();
  }

  @override
  void didUpdateWidget(AmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果是用户输入导致的更新，跳过子组件的更新
    if (_isUserInput) {
      _isUserInput = false;
      return;
    }
    if (widget.amount != oldWidget.amount && _controller.text != _formatAmount(widget.amount)) {
      // 延迟到下一帧执行，避免在 build 过程中 setState
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateText();
        }
      });
    }
  }

  void _updateText() {
    final newText = _formatAmount(widget.amount);
    // 只有文本变化时才更新，避免不必要的重绘和光标重置
    if (_controller.text != newText) {
      _controller.value = _controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    // 只在控制器是我们创建的情况下才释放
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Color _getAmountColor(bool isDark) {
    if (widget.amountColor != null) return widget.amountColor!;
    return isDark ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _getAmountColor(isDark);

    return FormField<String>(
      key: _fieldKey,
      initialValue: _controller.text,
      validator: widget.validator,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.currencySymbol,
                  style: TextStyle(
                    fontSize: widget.fontSize - 4,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      errorText: fieldState.errorText,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    enabled: widget.enabled,
                    onChanged: (value) {
                      _isUserInput = true;
                      final amount = double.tryParse(value);
                      widget.onAmountChanged(amount);
                      fieldState.didChange(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
