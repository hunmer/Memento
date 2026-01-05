part of 'scripts_center_plugin.dart';

/// 数据选择器注册
///
/// 注册脚本中心的数据选择器，供其他插件调用
void registerDataSelectors() {
  final pluginDataSelectorService = PluginDataSelectorService.instance;

  // 注册脚本选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'scripts_center.script',
      pluginId: ScriptsCenterPlugin.instance.id,
      name: 'scripts_center_selectScript'.tr,
      icon: ScriptsCenterPlugin.instance.icon,
      color: ScriptsCenterPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'select_script',
          title: 'scripts_center_selectScript'.tr,
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            // 获取所有启用的脚本
            final scripts = await ScriptsCenterPlugin.instance.scriptManager.loadAllScripts();
            final enabledScripts = scripts.where((s) => s.enabled).toList();

            return enabledScripts.map((script) {
              // 解析图标
              IconData scriptIcon;
              try {
                scriptIcon = IconData(
                  int.parse(script.icon, radix: 16),
                  fontFamily: 'MaterialIcons',
                );
              } catch (e) {
                scriptIcon = Icons.code;
              }

              return SelectableItem(
                id: script.id,
                title: script.name,
                subtitle:
                    script.description.isNotEmpty
                        ? script.description
                        : 'v${script.version}',
                icon: scriptIcon,
                rawData: {
                  'id': script.id,
                  'name': script.name,
                  'description': script.description,
                  'icon': script.icon,
                  'version': script.version,
                  'type': script.type,
                  'hasInputs': script.hasInputs,
                },
              );
            }).toList();
          },
        ),
      ],
    ),
  );

  print('✅ 脚本选择器注册成功');
}
