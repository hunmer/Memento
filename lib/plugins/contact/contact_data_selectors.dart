part of 'contact_plugin.dart';

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'contact.person',
        pluginId: ContactPlugin.instance.id,
        name: '选择联系人',
        icon: ContactPlugin.instance.icon,
        color: ContactPlugin.instance.color,
        searchable: true,
        selectionMode: SelectionMode.single,
        steps: [
          SelectorStep(
            id: 'person',
            title: '选择联系人',
            viewType: SelectorViewType.list,
            isFinalStep: true,
            dataLoader: (_) async {
              final contacts = await ContactPlugin.instance._controller.getAllContacts();
              return contacts.map((contact) {
                return SelectableItem(
                  id: contact.id,
                  title: contact.name,
                  subtitle: contact.phone,
                  icon: Icons.person,
                  avatarPath: contact.avatar,
                  metadata: {
                    'organization': contact.organization,
                    'email': contact.email,
                    'tags': contact.tags.join(', '),
                  },
                  rawData: contact.toJson(), // 保存为 Map 而不是 Contact 对象
                );
              }).toList();
            },
            searchFilter: (items, query) {
              if (query.isEmpty) return items;
              final lowerQuery = query.toLowerCase();
              return items.where((item) {
                // 搜索姓名
                if (item.title.toLowerCase().contains(lowerQuery)) return true;

                // 搜索电话
                if (item.subtitle?.contains(query) ?? false) return true;

                // 搜索组织/公司
                final org = item.metadata?['organization'] as String?;
                if (org != null && org.toLowerCase().contains(lowerQuery)) {
                  return true;
                }

                // 搜索邮箱
                final email = item.metadata?['email'] as String?;
                if (email != null && email.toLowerCase().contains(lowerQuery)) {
                  return true;
                }

                // 搜索标签
                final tags = item.metadata?['tags'] as String?;
                if (tags != null && tags.toLowerCase().contains(lowerQuery)) {
                  return true;
                }

                return false;
              }).toList();
            },
          ),
        ],
      ),
    );
  }
