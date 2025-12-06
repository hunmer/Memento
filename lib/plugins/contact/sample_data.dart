import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/contact_model.dart';
import 'models/interaction_record_model.dart';

/// 联系人插件的示例数据
class ContactSampleData {
  static const uuid = Uuid();

  /// 获取示例联系人列表
  static List<Contact> getSampleContacts() {
    return [
      Contact(
        id: uuid.v4(),
        name: '张三',
        icon: Icons.person,
        iconColor: Colors.blue,
        phone: '13800138000',
        email: 'zhangsan@example.com',
        address: '北京市朝阳区某某街道123号',
        organization: '北京科技有限公司',
        notes: '大学同学，现在在北京工作',
        tags: ['家人', '朋友'],
        customFields: {
          '公司': '北京科技有限公司',
          '职位': '技术总监',
          '生日': '1990-05-15',
        },
        createdTime: DateTime(2024, 1, 15),
        lastContactTime: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Contact(
        id: uuid.v4(),
        name: '李四',
        icon: Icons.work,
        iconColor: Colors.green,
        phone: '13900139000',
        email: 'lisi@company.com',
        address: '上海市浦东新区某某路456号',
        organization: '上海互联网公司',
        notes: '工作上的合作伙伴',
        tags: ['同事', '合作伙伴'],
        customFields: {
          '公司': '上海互联网公司',
          '职位': '产品经理',
          '生日': '1988-08-20',
        },
        createdTime: DateTime(2024, 2, 10),
        lastContactTime: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Contact(
        id: uuid.v4(),
        name: '王五',
        icon: Icons.school,
        iconColor: Colors.purple,
        phone: '13700137000',
        email: 'wangwu@university.edu',
        address: '广州市天河区某某大学',
        organization: '某某大学',
        notes: '研究生导师',
        tags: ['老师', '学术'],
        customFields: {
          '单位': '某某大学',
          '职称': '教授',
          '专业': '计算机科学',
        },
        createdTime: DateTime(2024, 3, 5),
        lastContactTime: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Contact(
        id: uuid.v4(),
        name: '赵六',
        icon: Icons.business_center,
        iconColor: Colors.orange,
        phone: '13600136000',
        email: 'zhaoliu@business.com',
        address: '深圳市南山区某某大厦789号',
        organization: '深圳创业公司',
        notes: '客户，对接项目合作',
        tags: ['客户', '商务'],
        customFields: {
          '公司': '深圳创业公司',
          '职位': 'CEO',
          '行业': '人工智能',
        },
        createdTime: DateTime(2024, 4, 1),
        lastContactTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Contact(
        id: uuid.v4(),
        name: '孙七',
        icon: Icons.local_hospital,
        iconColor: Colors.red,
        phone: '13500135000',
        address: '成都市武侯区某某医院',
        organization: '某某医院',
        notes: '家庭医生',
        tags: ['医生', '健康'],
        customFields: {
          '单位': '某某医院',
          '科室': '内科',
          '职称': '主治医师',
        },
        createdTime: DateTime(2024, 5, 10),
        lastContactTime: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  /// 获取示例交互记录
  static List<InteractionRecord> getSampleInteractions() {
    final contacts = getSampleContacts();
    return [
      InteractionRecord(
        id: uuid.v4(),
        contactId: contacts[0].id, // 张三
        date: DateTime.now().subtract(const Duration(days: 5)),
        notes: '讨论了新项目的进度，约定下周进一步沟通',
        participants: [contacts[1].id], // 李四也参与
      ),
      InteractionRecord(
        id: uuid.v4(),
        contactId: contacts[1].id, // 李四
        date: DateTime.now().subtract(const Duration(days: 2)),
        notes: '电话讨论产品需求，确认了下版本的功能点',
        participants: [contacts[0].id], // 张三也参与
      ),
      InteractionRecord(
        id: uuid.v4(),
        contactId: contacts[2].id, // 王五
        date: DateTime.now().subtract(const Duration(days: 10)),
        notes: '学术交流，讨论了最新研究方向',
        participants: [],
      ),
      InteractionRecord(
        id: uuid.v4(),
        contactId: contacts[3].id, // 赵六
        date: DateTime.now().subtract(const Duration(days: 1)),
        notes: '商务谈判，讨论了合作细节',
        participants: [],
      ),
      InteractionRecord(
        id: uuid.v4(),
        contactId: contacts[0].id, // 张三
        date: DateTime.now().subtract(const Duration(days: 20)),
        notes: '同学聚会，大家一起聚餐',
        participants: [contacts[1].id, contacts[2].id],
      ),
    ];
  }
}