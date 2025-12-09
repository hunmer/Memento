import 'package:flutter/material.dart';

/// 标签管理器对话框配置选项
class TagManagerConfig {
  final String title;
  final String addGroupHint;
  final String addTagHint;
  final String editGroupHint;
  final String allTagsLabel;
  final String newGroupLabel;
  final Color? selectedTagColor;
  final Color? checkmarkColor;

  const TagManagerConfig({
    this.title = '标签管理',
    this.addGroupHint = '请输入分组名称',
    this.addTagHint = '请输入标签名称',
    this.editGroupHint = '请输入新的分组名称',
    this.allTagsLabel = '所有标签',
    this.newGroupLabel = '新建分组',
    this.selectedTagColor,
    this.checkmarkColor,
  });
}