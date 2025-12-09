import 'package:flutter/material.dart';
import 'selector_step.dart';

/// 选择模式
enum SelectionMode {
  /// 单选模式
  single,

  /// 多选模式
  multiple,
}

/// 选择器定义
///
/// 描述一个可注册的数据选择器
class SelectorDefinition {
  /// 唯一标识（格式: pluginId.selectorName，如 "chat.channel"）
  final String id;

  /// 所属插件 ID
  final String pluginId;

  /// 选择器名称（用于显示）
  final String name;

  /// 选择器描述
  final String? description;

  /// 选择器图标
  final IconData? icon;

  /// 选择器颜色
  final Color? color;

  /// 选择步骤定义（支持多级选择）
  final List<SelectorStep> steps;

  /// 是否支持搜索
  final bool searchable;

  /// 选择模式
  final SelectionMode selectionMode;

  /// 多选时的最大选择数量（0 表示无限制）
  final int maxSelectionCount;

  const SelectorDefinition({
    required this.id,
    required this.pluginId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.steps,
    this.searchable = true,
    this.selectionMode = SelectionMode.single,
    this.maxSelectionCount = 0,
  });

  /// 获取步骤数量
  int get stepCount => steps.length;

  /// 是否为单步骤选择器
  bool get isSingleStep => steps.length == 1;

  /// 获取指定步骤
  SelectorStep? getStep(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  /// 根据 ID 获取步骤
  SelectorStep? getStepById(String stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } catch (_) {
      return null;
    }
  }

  /// 获取步骤索引
  int getStepIndex(String stepId) {
    return steps.indexWhere((step) => step.id == stepId);
  }
}
