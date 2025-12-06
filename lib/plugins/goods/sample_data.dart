import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/warehouse.dart';
import 'models/goods_item.dart';
import 'models/usage_record.dart';
import 'models/custom_field.dart';

/// 物品管理插件的示例数据
class GoodsSampleData {
  static const uuid = Uuid();

  /// 获取示例仓库列表
  static List<Warehouse> getSampleWarehouses() {
    final now = DateTime.now();

    return [
      Warehouse(
        id: uuid.v4(),
        title: '客厅',
        icon: Icons.weekend,
        iconColor: Colors.blue,
        items: [
          GoodsItem(
            id: uuid.v4(),
            title: '笔记本电脑',
            icon: Icons.laptop,
            iconColor: Colors.grey,
            tags: ['电子产品', '工作'],
            purchaseDate: DateTime(2024, 1, 15),
            purchasePrice: 8999.0,
            notes: '工作用笔记本电脑，性能良好',
            usageRecords: [
              UsageRecord(
                date: now.subtract(const Duration(days: 2)),
                note: '编写代码',
              ),
              UsageRecord(
                date: now.subtract(const Duration(days: 5)),
                note: '视频会议',
              ),
            ],
            customFields: [
              CustomField(key: '品牌', value: 'Dell'),
              CustomField(key: '型号', value: 'XPS 13'),
              CustomField(key: '处理器', value: 'Intel i7'),
            ],
          ),
          GoodsItem(
            id: uuid.v4(),
            title: '电视',
            icon: Icons.tv,
            iconColor: Colors.black,
            tags: ['电子产品', '娱乐'],
            purchaseDate: DateTime(2023, 12, 1),
            purchasePrice: 3999.0,
            notes: '55寸智能电视',
            usageRecords: [
              UsageRecord(
                date: now.subtract(const Duration(days: 1)),
                note: '观看电影',
              ),
              UsageRecord(
                date: now.subtract(const Duration(days: 3)),
                note: '玩游戏',
              ),
            ],
            customFields: [
              CustomField(key: '品牌', value: 'Sony'),
              CustomField(key: '尺寸', value: '55英寸'),
              CustomField(key: '分辨率', value: '4K'),
            ],
          ),
          GoodsItem(
            id: uuid.v4(),
            title: '沙发',
            icon: Icons.chair,
            iconColor: Colors.brown,
            tags: ['家具'],
            purchaseDate: DateTime(2023, 10, 15),
            purchasePrice: 5999.0,
            notes: '舒适的布艺沙发，可坐3人',
            usageRecords: [
              UsageRecord(
                date: DateTime.now(),
                note: '日常休息',
              ),
            ],
            customFields: [
              CustomField(key: '材质', value: '布艺'),
              CustomField(key: '颜色', value: '深灰色'),
              CustomField(key: '尺寸', value: '2.2米'),
            ],
          ),
        ],
      ),
      Warehouse(
        id: uuid.v4(),
        title: '厨房',
        icon: Icons.kitchen,
        iconColor: Colors.orange,
        items: [
          GoodsItem(
            id: uuid.v4(),
            title: '咖啡机',
            icon: Icons.coffee,
            iconColor: Colors.brown,
            tags: ['电器', '饮品'],
            purchaseDate: DateTime(2024, 2, 20),
            purchasePrice: 599.0,
            notes: '全自动咖啡机，支持多种口味',
            usageRecords: [
              UsageRecord(
                date: DateTime.now(),
                note: '制作早晨咖啡',
              ),
              UsageRecord(
                date: now.subtract(const Duration(days: 1)),
                note: '制作下午茶',
              ),
            ],
            customFields: [
              CustomField(key: '品牌', value: 'DeLonghi'),
              CustomField(key: '类型', value: '全自动'),
              CustomField(key: '容量', value: '1.8L'),
            ],
            subItems: [
              GoodsItem(
                id: uuid.v4(),
                title: '咖啡豆',
                icon: Icons.grain,
                tags: ['耗材'],
                purchaseDate: DateTime(2024, 2, 25),
                purchasePrice: 89.0,
                notes: '意式浓缩咖啡豆',
                customFields: [
                  CustomField(key: '产地', value: '意大利'),
                  CustomField(key: '重量', value: '500g'),
                ],
              ),
            ],
          ),
          GoodsItem(
            id: uuid.v4(),
            title: '微波炉',
            icon: Icons.microwave,
            iconColor: Colors.grey,
            tags: ['电器'],
            purchaseDate: DateTime(2024, 1, 10),
            purchasePrice: 799.0,
            notes: '30升微波炉',
            usageRecords: [
              UsageRecord(
                date: now.subtract(const Duration(days: 1)),
                note: '加热午餐',
              ),
            ],
            customFields: [
              CustomField(key: '品牌', value: 'Panasonic'),
              CustomField(key: '容量', value: '30L'),
            ],
          ),
        ],
      ),
      Warehouse(
        id: uuid.v4(),
        title: '书房',
        icon: Icons.book,
        iconColor: Colors.green,
        items: [
          GoodsItem(
            id: uuid.v4(),
            title: '办公桌',
            icon: Icons.desk,
            iconColor: Colors.amber,
            tags: ['家具'],
            purchaseDate: DateTime(2023, 11, 20),
            purchasePrice: 1599.0,
            notes: '1.5米办公桌，带抽屉',
            usageRecords: [
              UsageRecord(
                date: DateTime.now(),
                note: '日常办公',
              ),
            ],
            customFields: [
              CustomField(key: '材质', value: '实木'),
              CustomField(key: '颜色', value: '橡木色'),
              CustomField(key: '尺寸', value: '150x75cm'),
            ],
          ),
          GoodsItem(
            id: uuid.v4(),
            title: '打印机',
            icon: Icons.print,
            iconColor: Colors.blueGrey,
            tags: ['电子产品', '办公'],
            purchaseDate: DateTime(2024, 3, 1),
            purchasePrice: 1299.0,
            notes: '多功能一体打印机',
            usageRecords: [
              UsageRecord(
                date: now.subtract(const Duration(days: 3)),
                note: '打印文档',
              ),
            ],
            customFields: [
              CustomField(key: '品牌', value: 'HP'),
              CustomField(key: '类型', value: '激光一体机'),
            ],
            subItems: [
              GoodsItem(
                id: uuid.v4(),
                title: '墨粉盒',
                icon: Icons.inventory,
                tags: ['耗材'],
                purchaseDate: DateTime(2024, 3, 5),
                purchasePrice: 299.0,
                notes: '黑色墨粉盒',
                customFields: [
                  CustomField(key: '型号', value: 'HP 88A'),
                  CustomField(key: '打印页数', value: '1500页'),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }
}