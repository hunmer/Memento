import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../controls/bill_controller.dart';

/// Bill插件的Prompt替换服务
class BillPromptReplacements {
  final BillController _billController = BillController();
  
  /// 初始化并注册所有prompt替换方法
  void initialize() {
    debugPrint('初始化Bill插件的Prompt替换服务');
    // 确保BillController已初始化
    _billController.initialize().catchError((e) {
      debugPrint('初始化BillController失败: $e');
    });
  }

  /// 获取账单数据并格式化为文本
  Future<String> getBills(Map<String, dynamic> params) async {
    try {
      // 解析参数
      final String? startDateStr = params['startDate'] as String?;
      final String? endDateStr = params['endDate'] as String?;
      
      DateTime? startDate;
      DateTime? endDate;
      
      // 解析日期字符串
      if (startDateStr != null) {
        try {
          // 尝试多种格式解析日期
          startDate = _parseDate(startDateStr);
        } catch (e) {
          debugPrint('解析开始日期失败: $e');
        }
      }
      
      if (endDateStr != null) {
        try {
          endDate = _parseDate(endDateStr);
        } catch (e) {
          debugPrint('解析结束日期失败: $e');
        }
      }
      
      // 查询账单数据
      final bills = await _billController.getBills(
        startDate: startDate,
        endDate: endDate,
      );
      
      // 格式化账单数据为文本
      return _formatBillsToText(bills);
    } catch (e) {
      debugPrint('获取账单数据失败: $e');
      return '获取账单数据时出错: $e';
    }
  }
  
  /// 尝试多种格式解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
      }
    } catch (_) {}
    
    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
      }
    } catch (_) {}
    
    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    
    // 如果所有尝试都失败，抛出异常
    throw FormatException('无法解析日期: $dateStr');
  }
  
  /// 格式化账单数据为JSON文本
  String _formatBillsToText(List<Bill> bills) {
    if (bills.isEmpty) {
      return '{"status": "empty", "msg": "在指定时间段内没有找到账单记录。"}';
    }
    
    // 计算总收入和总支出
    double totalIncome = 0;
    double totalExpense = 0;
    
    // 按类别统计
    final Map<String, double> categoryStats = {};
    
    for (final bill in bills) {
      if (bill.amount > 0) {
        totalIncome += bill.amount;
      } else {
        totalExpense += bill.amount.abs();
      }
      
      // 只统计非零金额的类别
      if (bill.amount != 0) {
        categoryStats[bill.category] = (categoryStats[bill.category] ?? 0) + bill.amount;
      }
    }
    
    // 生成JSON报告
    final Map<String, dynamic> report = {};
    
    // 只有当有收支数据时才添加sum字段
    if (totalIncome > 0 || totalExpense > 0) {
      final Map<String, double> summary = {};
      
      if (totalIncome > 0) {
        summary['tInc'] = totalIncome; // totalIncome缩写
      }
      if (totalExpense > 0) {
        summary['tExp'] = totalExpense; // totalExpense缩写
      }
      
      final double netBalance = totalIncome - totalExpense;
      if (netBalance != 0) {
        summary['net'] = netBalance; // netBalance缩写
      }
      
      report['sum'] = summary;
    }
    
    // 只有当有类别统计数据时才添加catStat字段
    if (categoryStats.isNotEmpty) {
      // 移除金额为0的类别
      categoryStats.removeWhere((_, amount) => amount == 0);
      if (categoryStats.isNotEmpty) {
        report['catStat'] = categoryStats;
      }
    }
    
    // 添加非空的详细账单记录
    if (bills.isNotEmpty) {
      final List<Map<String, dynamic>> records = [];
      for (final bill in bills) {
        final Map<String, dynamic> record = {
          'date': bill.date.toString().substring(0, 10),
          'title': bill.title,
          'cat': bill.category, // category缩写
          'amt': bill.amount // amount缩写
        };
        
        // 只有当备注非空时才添加note字段
        if (bill.note.isNotEmpty) {
          record['note'] = bill.note;
        }
        
        records.add(record);
      }
      report['records'] = records;
    }
    
    return _formatJsonString(report);
  }
  
  /// 格式化JSON字符串，移除多余空格和换行符，保留金额的两位小数
  String _formatJsonString(Map<String, dynamic> jsonMap) {
    String jsonString = jsonMap.toString();
    
    // 确保金额显示两位小数
    final RegExp numPattern = RegExp(r'(tInc|tExp|net|amt): ([0-9.-]+)');
    jsonString = jsonString.replaceAllMapped(numPattern, (match) {
      final key = match.group(1);
      final value = double.parse(match.group(2)!);
      return '$key: ${value.toStringAsFixed(2)}';
    });
    
    return jsonString;
  }
  
  /// 释放资源
  void dispose() {
    debugPrint('释放Bill插件的Prompt替换服务资源');
  }
}