import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/memorial_day.dart';

/// 纪念日插件的示例数据
class DaySampleData {
  /// 获取示例纪念日数据
  static List<MemorialDay> getSampleMemorialDays() {
    final now = DateTime.now();

    return [
      // 未来事件 - 即将到来
      MemorialDay(
        title: '新年倒计时',
        targetDate: DateTime(now.year + 1, 1, 1),
        notes: ['准备跨年活动', '购买烟花', '邀请朋友'],
        backgroundColor: Colors.red[300]!,
        sortIndex: 0,
      ),
      MemorialDay(
        title: '生日派对',
        targetDate: DateTime(now.year, now.month + 2, 15),
        notes: ['准备蛋糕', '邀请好友', '布置场地'],
        backgroundColor: Colors.pink[300]!,
        sortIndex: 1,
      ),
      MemorialDay(
        title: '项目截止日',
        targetDate: DateTime(now.year, now.month, now.day + 14),
        notes: ['完成代码审查', '准备演示文档', '部署测试环境'],
        backgroundColor: Colors.orange[300]!,
        sortIndex: 2,
      ),
      MemorialDay(
        title: '年度体检',
        targetDate: DateTime(now.year, now.month + 1, 10),
        notes: ['提前预约', '空腹检查'],
        backgroundColor: Colors.teal[300]!,
        sortIndex: 3,
      ),

      // 过去事件 - 纪念日
      MemorialDay(
        title: '毕业纪念日',
        targetDate: DateTime(now.year - 3, 6, 30),
        notes: ['大学毕业三周年', '珍贵的回忆'],
        backgroundColor: Colors.purple[300]!,
        sortIndex: 4,
      ),
      MemorialDay(
        title: '结婚纪念日',
        targetDate: DateTime(now.year - 2, 8, 18),
        notes: ['准备惊喜', '订餐厅', '买花'],
        backgroundColor: Colors.red[400]!,
        sortIndex: 5,
      ),
      MemorialDay(
        title: '入职纪念日',
        targetDate: DateTime(now.year - 1, 3, 1),
        notes: ['工作一周年', '总结成长'],
        backgroundColor: Colors.blue[300]!,
        sortIndex: 6,
      ),
      MemorialDay(
        title: '第一次旅行',
        targetDate: DateTime(now.year - 4, 7, 20),
        notes: ['去了云南', '美好的回忆'],
        backgroundColor: Colors.green[300]!,
        sortIndex: 7,
      ),

      // 今日/近期事件
      MemorialDay(
        title: '健身计划开始',
        targetDate: DateTime(now.year, now.month, now.day + 3),
        notes: ['买运动装备', '制定训练计划'],
        backgroundColor: Colors.amber[300]!,
        sortIndex: 8,
      ),
      MemorialDay(
        title: '学习Flutter',
        targetDate: DateTime(now.year, now.month, now.day - 30),
        notes: ['开始学习之旅', '已坚持一个月'],
        backgroundColor: Colors.cyan[300]!,
        sortIndex: 9,
      ),
    ];
  }
}
