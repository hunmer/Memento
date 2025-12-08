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

  @override
  String get loading => 'Loading...';

  @override
  String get setAsDefaultTTSService => 'Set as Default TTS Service';

  @override
  String get audioBase64Encoded => 'Audio Base64 Encoded';

  @override
  String get audioIsBase64Encoded => 'Is audio data Base64 encoded';

  @override
  String get enableThisService => 'Enable this service';

  @override
  String get disableThisService => 'Disable this service';

  @override
  String get basicConfig => 'Basic Config';

  @override
  String get readingParameters => 'Reading Parameters';

  @override
  String get httpConfig => 'HTTP Config';

  @override
  String get directAudioReturn => 'Direct Audio Return';

  @override
  String get jsonWrapped => 'JSON Wrapped';

  @override
  String get loadVoiceListFailed => 'Failed to load voice list';

  @override
  String get pleaseEnterApiUrl => 'Please enter API URL';

  @override
  String get urlMustStartWithHttp => 'URL must start with http:// or https://';

  @override
  String get configValidationFailed => 'Config validation failed, please check required fields';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get pleaseEnterAudioFieldPath => 'Please enter audio field path';

  @override
  String get noServicesAvailable => 'No services available';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get loadServicesFailed => 'Failed to load services';

  @override
  String get serviceDeleted => 'Service deleted';

  @override
  String get deleteFailed => 'Failed to delete';

  @override
  String get updateFailed => 'Failed to update';

  @override
  String get setAsDefaultService => 'Set as default service';

  @override
  String get setDefaultFailed => 'Failed to set default';

  @override
  String get serviceAdded => 'Service added';

  @override
  String get addFailed => 'Failed to add';

  @override
  String get serviceUpdated => 'Service updated';

  @override
  String get voiceTestText => 'Hello, this is a voice test';

  @override
  String get testFailedPrefix => 'Test failed';

  @override
  String get refresh => 'Refresh';

  @override
  String get loadingVoiceList => 'Loading voice list...';

  @override
  String availableVoiceCount(int count) => '$count available voices';

  @override
  String get reloadVoiceList => 'Reload voice list';

  @override
  String get fillAccordingToApi => 'Fill according to API requirements';

  @override
  String get responseType => 'Response Type';

  @override
  String get audioFieldPath => 'Audio Field Path';

  @override
  String get audioFormat => 'Audio Format';
}
