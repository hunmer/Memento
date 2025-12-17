import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';

/// Toast 测试页面
class ToastTestPage extends StatelessWidget {
  const ToastTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast 测试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 基础功能测试
            _buildSection('基础功能', [
              _buildButton('普通消息', () => Toast.show('这是一条普通消息')),
              _buildButton('成功消息', () => Toast.success('操作成功！')),
              _buildButton('错误消息', () => Toast.error('操作失败！')),
              _buildButton('警告消息', () => Toast.warning('请注意！')),
              _buildButton('信息消息', () => Toast.info('提示信息')),
            ]),

            // 自定义选项测试
            _buildSection('自定义选项', [
              _buildButton('5秒显示', () => Toast.show(
                '这条消息显示5秒',
                duration: const Duration(seconds: 5),
              )),
              _buildButton('自定义颜色', () => Toast.show(
                '自定义样式',
                backgroundColor: Colors.purple,
                textColor: Colors.white,
                fontSize: 20,
              )),
              _buildButton('顶部显示', () => Toast.show(
                '顶部显示',
                gravity: ToastGravity.TOP,
              )),
              _buildButton('居中显示', () => Toast.show(
                '居中显示',
                gravity: ToastGravity.CENTER,
              )),
            ]),

            // 取消功能测试
            _buildSection('取消功能', [
              _buildButton('显示长消息', () async {
                Toast.show('这是一条10秒的消息', duration: const Duration(seconds: 10));
                await Future.delayed(const Duration(seconds: 2));
                Toast.cancel();
              }),
            ]),

            // 实际场景测试
            _buildSection('实际场景', [
              _buildButton('模拟保存', () async {
                Toast.show('正在保存...');
                await Future.delayed(const Duration(seconds: 1));
                Toast.success('保存成功！');
              }),
              _buildButton('模拟加载', () async {
                Toast.show('正在加载数据...');
                await Future.delayed(const Duration(seconds: 2));
                Toast.error('加载失败，请重试');
              }),
              _buildButton('表单验证', () {
                Toast.warning('请填写所有必填字段');
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        )),
        const Divider(),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}