import 'package:flutter/material.dart';

/// 纪念日插件本地化接口
abstract class DayLocalizations {
  static DayLocalizations of(BuildContext context) {
    final localizations = Localizations.of<DayLocalizations>(
      context,
      DayLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No DayLocalizations found in context');
    }
    return localizations;
  }

  String get memorialDays;
  String get addMemorialDay;
  String get editMemorialDay;
  String get deleteMemorialDay;
  String get deleteConfirmation;
  String get title;
  String get targetDate;
  String get notes;
  String get addNote;
  String get backgroundColor;
  String get backgroundImage;
  String get save;
  String get cancel;
  String get delete;
  String daysRemaining(int count);
  String daysPassed(int count);
  String get noMemorialDays;
  String get enterTitle;
  String get enterNote;
  String get titleRequired;
  String get cardView;
  String get listView;
  String get manualSort;
  String get autoSort;
  String get information;
  String get appearance;
  String get preview;
  String get upcomingSort;
  String get recentSort;
  String get sortOptions;

  String get memorialDaysCount;

  String get upcoming;

  String get localImage;
}

/// 中文实现
class DayLocalizationsZh implements DayLocalizations {
  @override
  String get memorialDays => '纪念日';

  @override
  String get addMemorialDay => '添加纪念日';

  @override
  String get editMemorialDay => '编辑纪念日';

  @override
  String get deleteMemorialDay => '删除纪念日';

  @override
  String get deleteConfirmation => '确定要删除这个纪念日吗？';

  @override
  String get title => '标题';

  @override
  String get targetDate => '目标日期';

  @override
  String get notes => '笔记';

  @override
  String get addNote => '添加笔记';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get backgroundImage => '背景图片';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String daysRemaining(int count) {
    if (count == 0) return '就是今天';
    if (count == 1) return '还剩1天';
    return '还剩$count天';
  }

  @override
  String daysPassed(int count) {
    if (count == 1) return '已过1天';
    return '已过$count天';
  }

  @override
  String get noMemorialDays => '暂无纪念日，立即添加一个！';

  @override
  String get enterTitle => '请输入标题';

  @override
  String get enterNote => '请输入笔记';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String get cardView => '卡片视图';

  @override
  String get listView => '列表视图';

  @override
  String get manualSort => '手动排序';

  @override
  String get autoSort => '自动排序';

  @override
  String get information => '信息';

  @override
  String get appearance => '外观';

  @override
  String get preview => '预览';

  @override
  String get upcomingSort => '即将发生';

  @override
  String get recentSort => '最近添加';

  @override
  String get sortOptions => '排序选项';

  @override
  String get memorialDaysCount => '纪念日数';
  @override
  String get upcoming => '即将到来';
  @override
  String get localImage => '本地图片';
}

/// 英文实现
class DayLocalizationsEn implements DayLocalizations {
  @override
  String get memorialDays => 'Memorial Days';

  @override
  String get addMemorialDay => 'Add Memorial Day';

  @override
  String get editMemorialDay => 'Edit Memorial Day';

  @override
  String get deleteMemorialDay => 'Delete Memorial Day';

  @override
  String get deleteConfirmation =>
      'Are you sure you want to delete this memorial day?';

  @override
  String get title => 'Title';

  @override
  String get targetDate => 'Target Date';

  @override
  String get notes => 'Notes';

  @override
  String get addNote => 'Add Note';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get backgroundImage => 'Background Image';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String daysRemaining(int count) {
    if (count == 0) return 'Today';
    if (count == 1) return '1 day remaining';
    return '$count days remaining';
  }

  @override
  String daysPassed(int count) {
    if (count == 1) return '1 day passed';
    return '$count days passed';
  }

  @override
  String get noMemorialDays => 'No memorial days found. Add one now!';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterNote => 'Enter note';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get cardView => 'Card View';

  @override
  String get listView => 'List View';

  @override
  String get manualSort => 'Manual Sort';

  @override
  String get autoSort => 'Auto Sort';

  @override
  String get information => 'Information';

  @override
  String get appearance => 'Appearance';

  @override
  String get preview => 'Preview';

  @override
  String get upcomingSort => 'Upcoming';

  @override
  String get recentSort => 'Recently Added';

  @override
  String get sortOptions => 'Sort Options';

  @override
  String get memorialDaysCount => 'Days';
  @override
  String get upcoming => 'Upcoming';
  @override
  String get localImage => 'Local Image';
}

/// 本地化代理
class DayLocalizationsDelegate extends LocalizationsDelegate<DayLocalizations> {
  const DayLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<DayLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return DayLocalizationsZh();
      case 'en':
      default:
        return DayLocalizationsEn();
    }
  }

  @override
  bool shouldReload(DayLocalizationsDelegate old) => false;

  static const DayLocalizationsDelegate delegate = DayLocalizationsDelegate();
}
