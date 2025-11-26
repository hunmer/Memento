import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/store/widgets/store_bottom_bar.dart';
import 'package:flutter/material.dart';

/// Store 插件主视图
/// 使用 StoreBottomBar 统一加载三个独立的 Tab 页面
class StoreMainView extends StatelessWidget {
  const StoreMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBottomBar(plugin: StorePlugin.instance);
  }
}
