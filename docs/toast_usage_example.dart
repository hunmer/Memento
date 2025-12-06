import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';

/// Toast 服务使用示例
class ToastUsageExample extends StatelessWidget {
  const ToastUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast 使用示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 基础用法
            const Text(
              '基础用法',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Toast.show('这是一条普通消息'),
              child: const Text('显示普通消息'),
            ),

            // 不同类型的消息
            const SizedBox(height: 32),
            const Text(
              '不同类型的消息',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Toast.success('操作成功！'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('成功'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Toast.error('操作失败！'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('错误'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Toast.warning('请注意！'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('警告'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Toast.info('提示信息'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('信息'),
                  ),
                ),
              ],
            ),

            // 自定义显示时长
            const SizedBox(height: 32),
            const Text(
              '自定义显示时长',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Toast.show(
                '这条消息显示5秒',
                duration: const Duration(seconds: 5),
              ),
              child: const Text('显示5秒'),
            ),

            // 高级用法
            const SizedBox(height: 32),
            const Text(
              '高级用法',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Toast.show(
                '自定义样式的消息',
                type: ToastType.normal,
                backgroundColor: Colors.purple,
                textColor: Colors.white,
                fontSize: 20,
              ),
              child: const Text('自定义样式'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // 移动端可以使用 gravity 参数
                Toast.show(
                  '顶部显示的消息',
                  gravity: ToastGravity.TOP,
                );
              },
              child: const Text('顶部显示（仅移动端）'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // 取消当前显示的 Toast
                Toast.cancel();
                Toast.show('已取消之前的 Toast');
              },
              child: const Text('取消当前 Toast'),
            ),

            // 实际使用场景示例
            const SizedBox(height: 32),
            const Text(
              '实际使用场景示例',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // 模拟保存操作
                Toast.show('正在保存...');
                await Future.delayed(const Duration(seconds: 1));
                Toast.success('保存成功！');
              },
              child: const Text('模拟保存操作'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // 模拟网络请求
                Toast.show('正在加载数据...');
                await Future.delayed(const Duration(seconds: 2));
                Toast.error('网络连接失败，请重试');
              },
              child: const Text('模拟网络请求失败'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // 表单验证
                Toast.warning('请填写所有必填字段');
              },
              child: const Text('表单验证提示'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 在插件中使用 Toast 的示例
class PluginToastExample {
  /// 在插件的异步操作中使用
  Future<void> saveData() async {
    try {
      Toast.show('正在保存数据...');

      // 模拟保存操作
      await Future.delayed(const Duration(milliseconds: 500));

      Toast.success('数据保存成功！');
    } catch (e) {
      Toast.error('保存失败：${e.toString()}');
    }
  }

  /// 在表单验证中使用
  bool validateForm(Map<String, String> formData) {
    if (formData['name']?.isEmpty ?? true) {
      Toast.warning('请输入姓名');
      return false;
    }

    if (formData['email']?.isEmpty ?? true) {
      Toast.warning('请输入邮箱');
      return false;
    }

    Toast.success('表单验证通过');
    return true;
  }

  /// 在用户操作反馈中使用
  void handleUserAction(String action) {
    switch (action) {
      case 'delete':
        Toast.info('已移动到回收站');
        break;
      case 'copy':
        Toast.success('已复制到剪贴板');
        break;
      case 'refresh':
        Toast.show('正在刷新数据...');
        break;
      default:
        Toast.info('操作完成');
    }
  }
}

/// 平台差异说明
///
/// 移动端 (Android/iOS):
/// - 使用 FlutterToast 实现
/// - 支持 gravity 参数控制显示位置
/// - 支持自定义背景色、文字色、字体大小
/// - 可以使用 cancel() 方法立即取消
///
/// Web 和桌面端:
/// - 使用 SnackBar 实现
/// - 带有相应的图标显示
/// - 自动适应主题颜色
/// - 可以通过 ScaffoldMessenger 隐藏