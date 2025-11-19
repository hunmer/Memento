/// TTS语音参数模型
class TTSVoice {
  /// 语音ID
  final String id;

  /// 显示名称
  final String name;

  /// 语言代码 (如 zh-CN, en-US)
  final String language;

  /// 性别 (male/female/neutral)
  final String? gender;

  TTSVoice({
    required this.id,
    required this.name,
    required this.language,
    this.gender,
  });

  /// 从JSON创建
  factory TTSVoice.fromJson(Map<String, dynamic> json) {
    return TTSVoice(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      gender: json['gender'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      if (gender != null) 'gender': gender,
    };
  }

  @override
  String toString() => 'TTSVoice(id: $id, name: $name, language: $language)';
}
