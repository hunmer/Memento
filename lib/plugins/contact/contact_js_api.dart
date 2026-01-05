part of 'contact_plugin.dart';

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 联系人相关
      'getContacts': _jsGetContacts,
      'getContact': _jsGetContact,
      'createContact': _jsCreateContact,
      'updateContact': _jsUpdateContact,
      'deleteContact': _jsDeleteContact,

      // 记录相关
      'addInteraction': _jsAddInteraction,
      'getInteractions': _jsGetInteractions,
      'deleteInteraction': _jsDeleteInteraction,

      // 筛选与统计
      'getRecentContacts': _jsGetRecentContacts,
      'getAllTags': _jsGetAllTags,

      // 联系人查找方法
      'findContactBy': _jsFindContactBy,
      'findContactById': _jsFindContactById,
      'findContactByName': _jsFindContactByName,

      // 交互记录查找方法
      'findInteractionBy': _jsFindInteractionBy,
      'findInteractionById': _jsFindInteractionById,
    };
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有联系人
  /// 支持分页参数: offset, count
  Future<String> _jsGetContacts(Map<String, dynamic> params) async {
    try {
      final getHttpImage = params['get_http_image'] == true;
      params.remove('get_http_image');

      final result = await _useCase.getContacts(params);

      if (result.isFailure) {
        return jsonEncode({
          'success': false,
          'error': result.errorOrNull?.message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      var contacts = result.dataOrNull ?? [];

      // 处理头像路径转换
      if (getHttpImage && contacts.isNotEmpty) {
        contacts = await LocalHttpServer.convertImagesWithAutoConfig(
          items: contacts,
          pluginId: id,
          imageKey: 'avatar',
          storageManager: storage,
        );
      }

      return jsonEncode({
        'success': true,
        'data': contacts,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': '获取联系人失败: ${e.toString()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// 获取联系人详情
  Future<String> _jsGetContact(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final result = await _useCase.getContactById({'id': contactId});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final contact = result.dataOrNull;
    if (contact == null) {
      return jsonEncode({'error': 'Contact not found'});
    }

    return jsonEncode(contact);
  }

  /// 创建联系人
  Future<String> _jsCreateContact(Map<String, dynamic> params) async {
    final result = await _useCase.createContact(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull ?? {});
  }

  /// 更新联系人
  Future<String> _jsUpdateContact(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    // 将 contactId 作为 id 传递给 UseCase
    final useCaseParams = Map<String, dynamic>.from(params);
    useCaseParams['id'] = contactId;

    final result = await _useCase.updateContact(useCaseParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull ?? {});
  }

  /// 删除联系人
  Future<String> _jsDeleteContact(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: contactId'});
    }

    final result = await _useCase.deleteContact({'id': contactId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    return jsonEncode({'success': true, 'contactId': contactId});
  }

  /// 添加交互记录
  Future<String> _jsAddInteraction(Map<String, dynamic> params) async {
    final result = await _useCase.createInteractionRecord(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull ?? {});
  }

  /// 获取交互记录
  /// 支持分页参数: offset, count
  Future<String> _jsGetInteractions(Map<String, dynamic> params) async {
    final result = await _useCase.getInteractionRecords(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode({
      'success': true,
      'data': result.dataOrNull ?? [],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 删除交互记录
  Future<String> _jsDeleteInteraction(Map<String, dynamic> params) async {
    final String? interactionId = params['interactionId'];
    if (interactionId == null || interactionId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: interactionId'});
    }

    final result = await _useCase.deleteInteractionRecord({
      'id': interactionId,
    });

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    return jsonEncode({'success': true, 'interactionId': interactionId});
  }

  /// 获取最近联系的联系人数量
  Future<String> _jsGetRecentContacts(Map<String, dynamic> params) async {
    final result = await _useCase.getRecentlyContactedCount(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull ?? 0);
  }

  /// 获取所有标签
  Future<String> _jsGetAllTags(Map<String, dynamic> params) async {
    final result = await _useCase.getAllTags(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull ?? []);
  }

  // ==================== 联系人查找方法 ====================

  /// 通用联系人查找
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindContactBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;
      final int? offset = params['offset'];
      final int? count = params['count'];

      // 使用 searchContacts 进行搜索
      final searchParams = <String, dynamic>{'offset': offset, 'count': count};

      // 根据字段类型设置搜索参数
      if (field == 'name' && value is String) {
        searchParams['nameKeyword'] = value;
      }

      final result = await _useCase.searchContacts(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      final contacts = result.dataOrNull as List<dynamic>? ?? [];

      if (findAll) {
        return jsonEncode(contacts);
      } else {
        return contacts.isEmpty ? jsonEncode(null) : jsonEncode(contacts.first);
      }
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  /// 根据 ID 查找联系人
  Future<String> _jsFindContactById(Map<String, dynamic> params) async {
    try {
      final String? id = params['id'];
      if (id == null || id.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      final result = await _useCase.getContactById({'id': id});

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  /// 根据姓名查找联系人
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindContactByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool findAll = params['findAll'] ?? false;
      final int? offset = params['offset'];
      final int? count = params['count'];

      // 使用 searchContacts 进行搜索
      final searchParams = <String, dynamic>{
        'nameKeyword': name,
        'offset': offset,
        'count': count,
      };

      final result = await _useCase.searchContacts(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      final contacts = result.dataOrNull as List<dynamic>? ?? [];

      if (findAll) {
        return jsonEncode(contacts);
      } else {
        return contacts.isEmpty ? jsonEncode(null) : jsonEncode(contacts.first);
      }
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  // ==================== 交互记录查找方法 ====================

  /// 通用交互记录查找
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindInteractionBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;
      final int? offset = params['offset'];
      final int? count = params['count'];

      // 如果是按 contactId 查找，使用 searchInteractionRecords
      if (field == 'contactId' && value is String) {
        final searchParams = <String, dynamic>{
          'contactId': value,
          'offset': offset,
          'count': count,
        };

        final result = await _useCase.searchInteractionRecords(searchParams);

        if (result.isFailure) {
          return jsonEncode({'error': result.errorOrNull?.message});
        }

        final interactions = result.dataOrNull as List<dynamic>? ?? [];

        if (findAll) {
          return jsonEncode(interactions);
        } else {
          return interactions.isEmpty
              ? jsonEncode(null)
              : jsonEncode(interactions.first);
        }
      }

      // 其他字段查找需要先获取所有记录再筛选
      final interactions = await _controller.getAllInteractions();
      final List<InteractionRecord> matchedInteractions = [];

      for (final interaction in interactions) {
        final interactionJson = interaction.toJson();
        if (interactionJson.containsKey(field) &&
            interactionJson[field] == value) {
          matchedInteractions.add(interaction);
          if (!findAll) break;
        }
      }

      if (findAll) {
        final interactionsJson =
            matchedInteractions.map((i) => i.toJson()).toList();

        // 检查是否需要分页
        if (offset != null || count != null) {
          final paginated = _paginate(
            interactionsJson,
            offset: offset ?? 0,
            count: count ?? 100,
          );
          return jsonEncode(paginated);
        }

        return jsonEncode(interactionsJson);
      } else {
        return matchedInteractions.isEmpty
            ? jsonEncode(null)
            : jsonEncode(matchedInteractions.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': '查找交互记录失败: $e'});
    }
  }

  /// 根据 ID 查找交互记录
  Future<String> _jsFindInteractionById(Map<String, dynamic> params) async {
    try {
      final String? id = params['id'];
      if (id == null || id.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      final result = await _useCase.getInteractionRecordById({'id': id});

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '查找交互记录失败: $e'});
    }
  }
