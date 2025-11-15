import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/llm_models.dart';

class ModelController {
  // 单例模式
  static final ModelController _instance = ModelController._internal();
  factory ModelController() => _instance;
  ModelController._internal();

  // 内存中的模型列表
  List<LLMModelGroup> _modelGroups = [];
  
  // 本地存储的键
  static const String _storageKey = 'openai_llm_models';
  
  // 是否已初始化
  bool _initialized = false;

  // 获取所有模型组
  Future<List<LLMModelGroup>> getModels() async {
    if (!_initialized) {
      await _loadFromStorage();
    }
    return _modelGroups;
  }
  
  // 从本地存储加载模型
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? modelsJson = prefs.getString(_storageKey);

      if (modelsJson != null) {
        final List<dynamic> jsonList = jsonDecode(modelsJson);
        _modelGroups = jsonList
            .map((json) => LLMModelGroup.fromJson(json))
            .toList();

        // 智能合并：检查是否有新的默认模型组，如果有则添加
        bool hasNewGroups = false;
        for (final defaultGroup in llmModelGroups) {
          final existingGroup = _modelGroups.firstWhere(
            (g) => g.id == defaultGroup.id,
            orElse: () => LLMModelGroup(id: '', name: '', models: []),
          );

          // 如果这个组不存在，添加整个组
          if (existingGroup.id.isEmpty) {
            _modelGroups.add(defaultGroup);
            hasNewGroups = true;
          } else {
            // 如果组存在，检查是否有新的模型需要添加
            for (final defaultModel in defaultGroup.models) {
              final modelExists = existingGroup.models.any((m) => m.id == defaultModel.id);
              if (!modelExists) {
                existingGroup.models.add(defaultModel);
                hasNewGroups = true;
              }
            }
          }
        }

        // 如果有新增的组或模型，保存到本地存储
        if (hasNewGroups) {
          await _saveToStorage();
        }
      } else {
        // 首次使用，加载默认模型
        _modelGroups = List.from(llmModelGroups);
        await _saveToStorage();
      }

      _initialized = true;
    } catch (e) {
      // 加载失败，使用默认模型
      _modelGroups = List.from(llmModelGroups);
      _initialized = true;
      // 不抛出异常，使用默认模型
      print('加载模型失败: $e');
    }
  }
  
  // 保存模型到本地存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _modelGroups.map((group) => group.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('保存模型失败: $e');
      throw Exception('保存模型失败: $e');
    }
  }

  // 添加新模型
  Future<void> addModel(LLMModel model) async {
    if (!_initialized) {
      await _loadFromStorage();
    }
    
    final groupIndex = _modelGroups.indexWhere((g) => g.id == model.group);
    if (groupIndex != -1) {
      if (_modelGroups[groupIndex].models.any((m) => m.id == model.id)) {
        throw Exception('模型ID已存在');
      }
      _modelGroups[groupIndex].models.add(model);
      await _saveToStorage();
    } else {
      throw Exception('模型组不存在');
    }
  }

  // 更新模型
  Future<void> updateModel(LLMModel model) async {
    if (!_initialized) {
      await _loadFromStorage();
    }
    
    final groupIndex = _modelGroups.indexWhere((g) => g.id == model.group);
    if (groupIndex != -1) {
      final modelIndex = _modelGroups[groupIndex].models.indexWhere((m) => m.id == model.id);
      if (modelIndex != -1) {
        _modelGroups[groupIndex].models[modelIndex] = model;
        await _saveToStorage();
      } else {
        throw Exception('模型不存在');
      }
    } else {
      throw Exception('模型组不存在');
    }
  }

  // 删除模型
  Future<void> deleteModel(String modelId) async {
    if (!_initialized) {
      await _loadFromStorage();
    }
    
    for (var group in _modelGroups) {
      final modelIndex = group.models.indexWhere((m) => m.id == modelId);
      if (modelIndex != -1) {
        group.models.removeAt(modelIndex);
        await _saveToStorage();
        return;
      }
    }
    throw Exception('模型不存在');
  }

  // 根据ID获取模型
  Future<LLMModel?> getModelById(String modelId) async {
    if (!_initialized) {
      await _loadFromStorage();
    }
    
    for (var group in _modelGroups) {
      try {
        final model = group.models.firstWhere(
          (m) => m.id == modelId,
        );
        return model;
      } catch (e) {
        // 在当前组中没找到，继续查找下一组
        continue;
      }
    }
    return null;
  }
  
  // 重置为默认模型
  Future<void> resetToDefault() async {
    _modelGroups = List.from(llmModelGroups);
    await _saveToStorage();
  }
}