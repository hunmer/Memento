part of 'tts_plugin.dart';

// ============ 数据选择器注册 ============

/// 数据选择器注册和实现
///
/// TTS 插件的数据选择器用于在其他插件中选择 TTS 服务
/// 当前未实现数据选择器，此文件预留用于未来扩展
///
/// 可能的选择器类型：
/// - TTS 服务选择器 (tts_service_selector)
///   用途：在其他插件中选择 TTS 服务进行朗读
///   返回格式：{ id, name, type }
///
/// 示例用法（未来实现）：
/// ```dart
/// @override
/// Future<void> registerDataSelectors() async {
///   // TTS 服务选择器
///   await registerDataSelector(
///     id: 'tts_service_selector',
///     displayName: '选择TTS服务',
///     description: '选择一个TTS服务用于朗读',
///     iconName: 'record_voice_over',
///     getData: (Map<String, dynamic> params) async {
///       final services = await managerService.getAllServices();
///       return services
///           .where((s) => s.isEnabled)
///           .map((s) => {
///                'id': s.id,
///                'name': s.name,
///                'type': s.type.name,
///              })
///           .toList();
///     },
///     onSelect: (Map<String, dynamic> data) {
///       final serviceId = data['id'] as String;
///       return serviceId;
///     },
///   );
/// }
///
/// 使用场景示例：
/// // 在日记插件中添加朗读功能
/// final serviceId = await selectData(
///   selectorId: 'tts_service_selector',
///   title: '选择朗读服务',
/// );
/// if (serviceId != null) {
///   await ttsPlugin.speak(diaryContent, serviceId: serviceId);
/// }
/// ```
