import 'nfc_localizations.dart';

/// NFC插件的英文本地化实现
class NfcLocalizationsEn extends NfcLocalizations {
  NfcLocalizationsEn() : super('en');

  @override
  String get pleaseBringPhoneNearNFC => 'Please bring phone near NFC tag';

  @override
  String get writeNFCData => 'Write NFC Data';

  @override
  String get cancel => 'Cancel';

  @override
  String get startWriting => 'Start Writing';

  @override
  String get nfcData => 'NFC Data';

  @override
  String get close => 'Close';

  @override
  String get copyData => 'Copy Data';

  @override
  String get nfcController => 'NFC Controller';

  @override
  String get enableNFC => 'Enable NFC';

  // Timer Dialog 相关
  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String get continueTimer => 'Continue Timer';

  @override
  String get confirmCancel => 'Confirm Cancel';

  @override
  String get completeTimer => 'Complete Timer';

  @override
  String get continueAdjust => 'Continue Adjust';

  @override
  String get confirmComplete => 'Confirm Complete';

  @override
  String get quickNotes => 'Quick Notes';

  @override
  String get addQuickNote => 'Add a quick note...';

  @override
  String get pause => 'Pause';

  @override
  String get start => 'Start';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get complete => 'Complete';

  @override
  String get pauseTimerConfirm => 'Are you sure you want to cancel the timer?\n'
      'Time elapsed: {time}\n\n'
      '⚠️ This timer session will not be saved';

  @override
  String get completeTimerConfirm => 'Are you sure you want to complete and save this session?\n'
      'Time elapsed: {time}\n'
      '{note}\n'
      '✅ This session will be saved to history';

  @override
  String get timerNotePrefix => 'Note: ';

  @override
  String get timerWarning => '';

  @override
  String get timerSuccess => '';
}