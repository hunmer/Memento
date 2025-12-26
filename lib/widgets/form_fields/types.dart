import 'package:flutter/material.dart';

/// 表单字段类型枚举
enum FormFieldType {
  // 文本输入类
  text,
  textArea,
  password,
  email,
  number,

  // 选择器类
  select,
  date,
  dateRange,
  time,

  // 开关滑块类
  switchField,
  slider,

  // 其他
  color,
  tags,
  iconTitle,
  categorySelector,
  optionSelector,
  customFields,
  listAdd,

  // Picker 选择器类
  iconPicker,
  avatarPicker,
  circleIconPicker,
  calendarStripPicker,
  imagePicker,
  locationPicker,

  // 自定义复合字段
  promptEditor,
  iconAvatarRow,

  // 账单专用字段
  expenseTypeSelector,
  amountInput,

  // 待办任务专用字段
  reminders,

  // 计时器专用字段
  timerItems,
  timerIconGrid,

  // 联系人专用字段
  genderSelector,
  customEvents,
  avatarNameSection,

  // 日记相册专用字段
  chipSelector,

  // 订阅专用字段
  subscriptionCycle,

  // 提醒日期选择器
  reminderDate,
}

/// 输入框组按钮
class InputGroupButton {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;

  const InputGroupButton({
    required this.icon,
    this.tooltip,
    required this.onPressed,
  });
}
