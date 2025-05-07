import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../../../core/storage/storage_manager.dart';
import 'package:uuid/uuid.dart';

class CategoryController extends ChangeNotifier {
  final StorageManager _storage;
  final String _storageDir;
  List<Category> _categories = [];

  CategoryController(this._storage, this._storageDir) {
    _loadCategories();
  }

  // Getters
  List<Category> get categories => _categories;

  // 加载分类
  Future<void> _loadCategories() async {
    try {
      final data = await _storage.read('$_storageDir/categories.json');
      if (data.isNotEmpty) {
        final List<dynamic> categoryList = data['categories'] as List<dynamic>;
        _categories = categoryList.map((item) => Category.fromJson(item)).toList();
        notifyListeners();
      } else {
        // 初始化默认分类
        await _initDefaultCategories();
      }
    } catch (e) {
      print('Error loading categories: $e');
      // 初始化默认分类
      await _initDefaultCategories();
    }
  }

  // 初始化默认分类
  Future<void> _initDefaultCategories() async {
    _categories = [
      Category(
        id: const Uuid().v4(),
        name: 'Work',
        color: '#4285F4',
        icon: 'work',
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Personal',
        color: '#0F9D58',
        icon: 'personal',
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Shopping',
        color: '#F4B400',
        icon: 'shopping',
      ),
    ];
    await _saveCategories();
    notifyListeners();
  }

  // 保存分类
  Future<void> _saveCategories() async {
    try {
      final data = {
        'categories': _categories.map((category) => category.toJson()).toList()
      };
      await _storage.write('$_storageDir/categories.json', data);
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // 添加分类
  Future<void> addCategory(Category category) async {
    _categories.add(category);
    notifyListeners();
    await _saveCategories();
  }

  // 创建新分类
  Future<Category> createCategory({
    required String name,
    required String color,
    required String icon,
  }) async {
    final category = Category(
      id: const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
    );
    
    await addCategory(category);
    return category;
  }

  // 更新分类
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
      await _saveCategories();
    }
  }

  // 删除分类
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((category) => category.id == categoryId);
    notifyListeners();
    await _saveCategories();
  }

  // 获取分类
  Category? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}