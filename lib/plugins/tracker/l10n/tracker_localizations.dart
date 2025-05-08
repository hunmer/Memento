
import 'package:flutter/material.dart';

class TrackerLocalizations {
  static const LocalizationsDelegate<TrackerLocalizations> delegate =
      _TrackerLocalizationsDelegate();

  static TrackerLocalizations of(BuildContext context) {
    return Localizations.of<TrackerLocalizations>(context, TrackerLocalizations)!;
  }

  String get goalsTitle => '目标';
  String get recordsTitle => '记录';
  String get createGoal => '创建目标';
  String get editGoal => '编辑目标';
  String get goalName => '目标名称';
  String get goalNameHint => '输入目标名称';
  String get unitType => '单位';
  String get unitTypeHint => '如 ml, 页, 分钟';
  String get targetValue => '目标总量';
  String get dateSettings => '日期设置';
  String get reminder => '提醒';
  String get dailyReset => '每日重置';
  String get save => '保存';
  String get cancel => '取消';
  String get addRecord => '添加记录';
  String get recordValue => '记录值';
  String get note => '备注';
  String get noteHint => '可选备注';
  String get daily => '每日';
  String get weekly => '每周';
  String get monthly => '每月';
  String get dateRange => '日期范围';
  String get selectDays => '选择日期';
  String get selectDate => '选择日期';
  String get startDate => '开始日期';
  String get endDate => '结束日期';
  String get progress => '进度';
  String get history => '历史记录';
  String get todayRecords => '今日记录';
  String get totalGoals => '目标总数';
}

class _TrackerLocalizationsDelegate
    extends LocalizationsDelegate<TrackerLocalizations> {
  const _TrackerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TrackerLocalizations> load(Locale locale) async {
    return TrackerLocalizations();
  }

  @override
  bool shouldReload(_TrackerLocalizationsDelegate old) => false;
}
