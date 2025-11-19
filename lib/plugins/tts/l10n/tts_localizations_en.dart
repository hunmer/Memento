import 'tts_localizations.dart';

/// TTS plugin English localization
class TTSLocalizationsEn extends TTSLocalizations {
  TTSLocalizationsEn(super.locale);
  @override
  String get name => 'Text-to-Speech';

  @override
  String get servicesList => 'Services';

  @override
  String get addService => 'Add Service';

  @override
  String get editService => 'Edit Service';

  @override
  String get deleteService => 'Delete Service';

  @override
  String get serviceName => 'Service Name';

  @override
  String get serviceType => 'Service Type';

  @override
  String get systemTts => 'System TTS';

  @override
  String get httpService => 'HTTP Service';

  @override
  String get defaultService => 'Default Service';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get pitch => 'Pitch';

  @override
  String get speed => 'Speed';

  @override
  String get volume => 'Volume';

  @override
  String get voice => 'Voice';

  @override
  String get apiUrl => 'API URL';

  @override
  String get headers => 'Headers';

  @override
  String get requestBody => 'Request Body';

  @override
  String get test => 'Test';

  @override
  String get testSuccess => 'Test Successful';

  @override
  String get testFailed => 'Test Failed';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Are you sure you want to delete this service?';

  @override
  String get queue => 'Queue';

  @override
  String get currentReading => 'Currently Reading';

  @override
  String get waiting => 'Waiting';

  @override
  String get clearQueue => 'Clear Queue';
}
