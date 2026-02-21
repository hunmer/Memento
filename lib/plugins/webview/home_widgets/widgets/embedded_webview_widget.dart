/// 嵌入式 WebView 小组件件
library;

import 'package:flutter/material.dart';
import 'package:Memento/plugins/webview/widgets/embedded_webview.dart';

/// 嵌入式 WebView 小组件
class EmbeddedWebViewWidget extends StatefulWidget {
  final String url;
  final String title;
  final int width;
  final int height;

  const EmbeddedWebViewWidget({
    super.key,
    required this.url,
    required this.title,
    required this.width,
    required this.height,
  });

  @override
  State<EmbeddedWebViewWidget> createState() => _EmbeddedWebViewWidgetState();
}

class _EmbeddedWebViewWidgetState extends State<EmbeddedWebViewWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 添加超时机制：10 秒后自动隐藏加载指示器
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 使用可复用的 EmbeddedWebView 组件
            EmbeddedWebView(
              url: widget.url,
              onLoadingChanged: (isLoading) {
                if (mounted && _isLoading != isLoading) {
                  setState(() {
                    _isLoading = isLoading;
                  });
                }
              },
            ),
            // 加载进度指示器
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text('加载中...', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
