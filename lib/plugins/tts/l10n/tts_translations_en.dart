/// TTS plugin English translations
const Map<String, String> ttsTranslationsEn = {
  // Basic info
  'tts_name': 'Text-to-Speech',
  'tts_servicesList': 'Services',
  'tts_addService': 'Add Service',
  'tts_editService': 'Edit Service',
  'tts_deleteService': 'Delete Service',
  'tts_serviceName': 'Service Name',
  'tts_serviceType': 'Service Type',
  'tts_systemTts': 'System TTS',
  'tts_httpService': 'HTTP Service',
  'tts_defaultService': 'Default Service',

  // Status
  'tts_enabled': 'Enabled',
  'tts_disabled': 'Disabled',

  // Parameters
  'tts_pitch': 'Pitch',
  'tts_speed': 'Speed',
  'tts_volume': 'Volume',
  'tts_voice': 'Voice',

  // HTTP Config
  'tts_apiUrl': 'API URL',
  'tts_headers': 'Headers',
  'tts_requestBody': 'Request Body',
  'tts_responseType': 'Response Type',
  'tts_audioFieldPath': 'Audio Field Path',
  'tts_audioFormat': 'Audio Format',
  'tts_audioBase64Encoded': 'Audio Base64 Encoded',
  'tts_audioIsBase64Encoded': 'Is audio data Base64 encoded',
  'tts_directAudioReturn': 'Direct Audio Return',
  'tts_jsonWrapped': 'JSON Wrapped',

  // Config Groups
  'tts_basicConfig': 'Basic Config',
  'tts_readingParameters': 'Reading Parameters',
  'tts_httpConfig': 'HTTP Config',

  // Actions
  'tts_test': 'Test',
  'tts_save': 'Save',
  'tts_cancel': 'Cancel',
  'tts_refresh': 'Refresh',
  'tts_setAsDefault': 'Set as default',
  'tts_setAsDefaultTTSService': 'Set as Default TTS Service',
  'tts_enableThisService': 'Enable this service',
  'tts_disableThisService': 'Disable this service',

  // Confirm dialogs
  'tts_confirmDelete': 'Are you sure you want to delete this service?',

  // Queue management
  'tts_queue': 'Queue',
  'tts_currentReading': 'Currently Reading',
  'tts_waiting': 'Waiting',
  'tts_clearQueue': 'Clear Queue',

  // Status messages
  'tts_loading': 'Loading...',
  'tts_loadingVoiceList': 'Loading voice list...',
  'tts_testSuccess': 'Test Successful',
  'tts_testFailed': 'Test Failed',
  'tts_testFailedPrefix': 'Test failed',

  // Success messages
  'tts_serviceAdded': 'Service added',
  'tts_serviceUpdated': 'Service updated',
  'tts_serviceDeleted': 'Service deleted',
  'tts_setAsDefaultService': 'Set as default service',

  // Error messages
  'tts_saveFailed': 'Save failed',
  'tts_addFailed': 'Failed to add',
  'tts_updateFailed': 'Failed to update',
  'tts_deleteFailed': 'Failed to delete',
  'tts_setDefaultFailed': 'Failed to set default',
  'tts_loadServicesFailed': 'Failed to load services',
  'tts_loadVoiceListFailed': 'Failed to load voice list',

  // Empty states
  'tts_noServicesAvailable': 'No services available',

  // Form validation
  'tts_pleaseEnterApiUrl': 'Please enter API URL',
  'tts_pleaseEnterAudioFieldPath': 'Please enter audio field path',
  'tts_urlMustStartWithHttp': 'URL must start with http:// or https://',
  'tts_configValidationFailed': 'Config validation failed, please check required fields',

  // Voice related
  'tts_voiceTestText': 'Hello, this is a voice test',
  'tts_reloadVoiceList': 'Reload voice list',
  'tts_fillAccordingToApi': 'Fill according to API requirements',

  // Parameterized translations - using @name placeholders
  'tts_availableVoiceCount': '@count available voices',

  // Widget Home Strings
  'tts_widgetName': 'Text-to-Speech',
  'tts_widgetDescription': 'Quick access to TTS',
  'tts_overviewName': 'TTS Overview',
  'tts_overviewDescription': 'Display TTS service status',
};
