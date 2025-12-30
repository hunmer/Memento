import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';

/// Toast 测试页面
class ToastTestScreen extends StatefulWidget {
  const ToastTestScreen({super.key});

  @override
  State<ToastTestScreen> createState() => _ToastTestScreenState();
}

class _ToastTestScreenState extends State<ToastTestScreen> {
  String _selectedPosition = 'Bottom';
  String _selectedAnimation = 'Fade';
  String _selectedReverseAnimation = 'Fade';
  bool _fullWidth = false;
  bool _isIgnoring = true;
  bool _dismissOther = true;

  final List<String> _positions = ['Top', 'Center', 'Bottom'];
  final List<String> _animations = [
    'Fade',
    'SlideFromTop',
    'SlideFromBottom',
    'SlideFromLeft',
    'SlideFromRight',
    'Scale',
    'FadeScale',
    'Rotate',
    'FadeRotate',
    'ScaleRotate',
  ];

  ToastGravity _getGravity() {
    switch (_selectedPosition) {
      case 'Top':
        return ToastGravity.TOP;
      case 'Center':
        return ToastGravity.CENTER;
      case 'Bottom':
      default:
        return ToastGravity.BOTTOM;
    }
  }

  ToastAnimation _getAnimation() {
    switch (_selectedAnimation) {
      case 'Fade':
        return ToastAnimation.fade;
      case 'SlideFromTop':
        return ToastAnimation.slideFromTop;
      case 'SlideFromBottom':
        return ToastAnimation.slideFromBottom;
      case 'SlideFromLeft':
        return ToastAnimation.slideFromLeft;
      case 'SlideFromRight':
        return ToastAnimation.slideFromRight;
      case 'Scale':
        return ToastAnimation.scale;
      case 'FadeScale':
        return ToastAnimation.fadeScale;
      case 'Rotate':
        return ToastAnimation.rotate;
      case 'FadeRotate':
        return ToastAnimation.fadeRotate;
      case 'ScaleRotate':
        return ToastAnimation.scaleRotate;
      default:
        return ToastAnimation.fade;
    }
  }

  ToastAnimation? _getReverseAnimation() {
    switch (_selectedReverseAnimation) {
      case 'Fade':
        return ToastAnimation.fade;
      case 'SlideFromTop':
        return ToastAnimation.slideFromTop;
      case 'SlideFromBottom':
        return ToastAnimation.slideFromBottom;
      case 'SlideFromLeft':
        return ToastAnimation.slideFromLeft;
      case 'SlideFromRight':
        return ToastAnimation.slideFromRight;
      case 'Scale':
        return ToastAnimation.scale;
      case 'FadeScale':
        return ToastAnimation.fadeScale;
      case 'Rotate':
        return ToastAnimation.rotate;
      case 'FadeRotate':
        return ToastAnimation.fadeRotate;
      case 'ScaleRotate':
        return ToastAnimation.scaleRotate;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast 测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Toast.dismiss(),
            tooltip: '关闭所有 Toast',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基础 Toast
          _buildSectionHeader('基础 Toast'),
          _buildButtonCard([
            _buildTestButton('普通消息', () {
              Toast.show('这是一条普通消息');
            }),
            _buildTestButton('成功消息', () {
              Toast.success('操作成功！');
            }),
            _buildTestButton('错误消息', () {
              Toast.error('操作失败！');
            }),
            _buildTestButton('警告消息', () {
              Toast.warning('请注意！');
            }),
            _buildTestButton('信息消息', () {
              Toast.info('提示信息');
            }),
          ]),

          // 位置设置
          _buildSectionHeader('位置设置'),
          _buildDropdownCard(
            '显示位置',
            _selectedPosition,
            _positions,
            (value) => setState(() => _selectedPosition = value),
          ),
          _buildButtonCard([
            _buildTestButton('顶部显示', () {
              Toast.show('顶部消息', gravity: ToastGravity.TOP);
            }),
            _buildTestButton('居中显示', () {
              Toast.show('居中消息', gravity: ToastGravity.CENTER);
            }),
            _buildTestButton('底部显示', () {
              Toast.show('底部消息', gravity: ToastGravity.BOTTOM);
            }),
          ]),

          // 动画设置
          _buildSectionHeader('动画效果'),
          _buildDropdownCard(
            '进入动画',
            _selectedAnimation,
            _animations,
            (value) => setState(() => _selectedAnimation = value),
          ),
          _buildDropdownCard(
            '退出动画',
            _selectedReverseAnimation,
            _animations,
            (value) => setState(() => _selectedReverseAnimation = value),
          ),
          _buildButtonCard([
            _buildTestButton('测试动画', () {
              Toast.show(
                '动画效果测试',
                gravity: _getGravity(),
                animation: _getAnimation(),
                reverseAnimation: _getReverseAnimation(),
                animDuration: const Duration(milliseconds: 600),
              );
            }),
            _buildTestButton('缩放+淡入淡出', () {
              Toast.show(
                '缩放淡入淡出',
                gravity: _getGravity(),
                animation: ToastAnimation.scale,
                reverseAnimation: ToastAnimation.fade,
                animDuration: const Duration(milliseconds: 600),
              );
            }),
            _buildTestButton('弹性曲线', () {
              Toast.show(
                '弹性动画效果',
                gravity: _getGravity(),
                animation: ToastAnimation.scale,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeInBack,
                animDuration: const Duration(milliseconds: 800),
              );
            }),
          ]),

          // 高级选项
          _buildSectionHeader('高级选项'),
          SwitchListTile(
            title: const Text('全宽显示'),
            subtitle: const Text('Toast 占满屏幕宽度（减去边距）'),
            value: _fullWidth,
            onChanged: (value) => setState(() => _fullWidth = value),
          ),
          SwitchListTile(
            title: const Text('可交互'),
            subtitle: const Text('允许用户与 Toast 交互'),
            value: !_isIgnoring,
            onChanged: (value) => setState(() => _isIgnoring = !value),
          ),
          SwitchListTile(
            title: const Text('关闭其他 Toast'),
            subtitle: const Text('显示新 Toast 时关闭其他 Toast'),
            value: _dismissOther,
            onChanged: (value) => setState(() => _dismissOther = value),
          ),
          _buildButtonCard([
            _buildTestButton('测试高级选项', () {
              Toast.show(
                '高级选项测试',
                gravity: _getGravity(),
                animation: _getAnimation(),
                fullWidth: _fullWidth,
                isIgnoring: _isIgnoring,
                dismissOtherOnShow: _dismissOther,
              );
            }),
          ]),

          // 自定义 Widget
          _buildSectionHeader('自定义 Widget Toast'),
          _buildButtonCard([
            _buildTestButton('自定义样式卡片', () {
              Toast.showCustomWidget(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        '自定义样式',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                position: _getGravity(),
                animation: _getAnimation(),
              );
            }),
            _buildTestButton('带按钮的交互式 Toast', () {
              Toast.showCustomWidget(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  margin: const EdgeInsets.symmetric(horizontal: 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green[600],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '点击按钮查看',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Toast.dismiss();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('按钮被点击！')),
                          );
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                position: ToastGravity.CENTER,
                animation: ToastAnimation.scale,
                isIgnoring: false,
                duration: const Duration(seconds: 5),
              );
            }),
            _buildTestButton('带进度的加载指示器', () {
              Toast.showCustomWidget(
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('加载中...'),
                    ],
                  ),
                ),
                position: ToastGravity.CENTER,
                animation: ToastAnimation.fadeScale,
                duration: const Duration(seconds: 3),
              );
            }),
          ]),

          // 全局 Toast (FlutterToast)
          _buildSectionHeader('全局 Toast (app外显示)'),
          _buildInfoCard(
            '使用 FlutterToast 实现，在移动端支持 app 外显示（如后台运行时）',
          ),
          _buildButtonCard([
            _buildTestButton('全局消息', () {
              Toast.showGlobal('这是一条全局消息');
            }),
            _buildTestButton('全局成功', () {
              Toast.showGlobal(
                '全局成功消息',
                type: ToastType.success,
              );
            }),
            _buildTestButton('全局错误', () {
              Toast.showGlobal(
                '全局错误消息',
                type: ToastType.error,
                gravity: ToastGravity.CENTER,
              );
            }),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildButtonCard(List<Widget> buttons) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget _buildDropdownCard(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
