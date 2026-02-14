/// 日記プラグイン日本語翻訳
class DiaryTranslationsJp {
  static const Map<String, String> translations = {
    // プラグイン基本情報
    'diary_name': '日記',
    'diary_diaryPluginDescription': '日記管理プラグイン',

    // Widget related
    'diary_widgetName': '日記',
    'diary_widgetDescription': '日記へのクイックアクセス',
    'diary_todayQuickName': '今日日記',
    'diary_todayQuickDescription': '今日日記エディタへのクイックアクセス',
    'diary_overviewName': '日記概要',
    'diary_overviewDescription': '本日の文字数と月次進捗を表示',
    'diary_weeklyName': '今週の日記',
    'diary_weeklyDescription': '今週の日記タイトルと気分を表示',
    'diary_weeklyTitle': '今週',

    // 統計情報
    'diary_todayWordCount': '本日の文字数',
    'diary_monthWordCount': '今月の文字数',
    'diary_monthProgress': '月次進捗',

    // 日記エディタ
    'diary_titleHint': '今日日記のタイトルを入力...',
    'diary_contentHint': '今日あったことを書く...',
    'diary_selectMood': '今日の気分を選択',
    'diary_clearSelection': '選択をクリア',
    'diary_moodSelectorTooltip': '気分を選択',

    // Activity form translations
    'diary_addActivity': '活動を追加',
    'diary_editActivity': '活動を編集',
    'diary_activityName': '活動名',
    'diary_unnamedActivity': '無名の活動',
    'diary_activityDescription': '活動説明',
    'diary_tagsHint': '例: 仕事、学習、運動',
    'diary_tagsHelperText':
        '新しいタグを直接入力できます。未グループに自動的に保存されます',
    'diary_editInterval': '間隔を編集',
    'diary_confirmButton': '確認',
    'diary_cancelButton': 'キャンセル',
    'diary_endTimeError': '終了時間は開始時間より後である必要があります',
    'diary_minDurationError': '活動時間は最低1分以上である必要があります',
    'diary_dayEndError': '活動終了時間は当日23:59を超えることはできません',

    // Timeline app bar translations
    'diary_activityTimeline': '活動タイムライン',
    'diary_minutesSelected': '@minutes分選択済み',
    'diary_switchToTimelineView': 'タイムライン表示に切り替え',
    'diary_switchToGridView': 'グリッド表示に切り替え',
    'diary_tagManagement': 'タグ管理',
    'diary_sortBy': '並び替え',
    'diary_sortByStartTimeAsc': '開始時間で並び替え（昇順）',
    'diary_sortByDuration': '活動時間で並び替え',
    'diary_sortByStartTimeDesc': '開始時間で並び替え（降順）',

    // 気分と日記管理
    'diary_mood': '気分',
    'diary_cannotSelectFutureDate': '未来の日付は選択できません',
    'diary_myDiary': 'マイ日記',
    'diary_recentlyUsed': '最近使用',
    'diary_deleteDiary': '日記を削除',
    'diary_confirmDeleteDiary': '削除の確認',
    'diary_deleteDiaryMessage':
        'この日記を削除してもよろしいですか？この操作は取り消せません。',
    'diary_noDiaryForDate': 'この日付の日記はありません',

    // ボタンテキスト
    'diary_edit': '編集',
    'diary_create': '新規作成',

    // 追加の翻訳（実装クラスで宣言されていないもの）
    'diary_cancel': 'キャンセル',
    'diary_save': '保存',
    'diary_close': '閉じる',
    'diary_startTime': '開始時間',
    'diary_endTime': '終了時間',
    'diary_interval': '間隔',
    'diary_minutes': '分',
    'diary_tags': 'タグ',
    'diary_searchPlaceholder': '日記コンテンツを検索...',
  };
}
