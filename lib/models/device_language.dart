enum DeviceLanguage {
  english('English (US)', 'en-US'),
  vietnamese('Vietnamese', 'vi-VN'),
  japanese('Japanese', 'ja-JP'),
  chineseSimplified('Chinese (Simplified)', 'zh-CN'),
  korean('Korean', 'ko-KR'),
  french('French', 'fr-FR'),
  spanish('Spanish', 'es-ES');

  const DeviceLanguage(this.label, this.locale);

  final String label;
  final String locale;

  static DeviceLanguage? fromLocale(String locale) => DeviceLanguage.values
      .where((language) => language.locale == locale)
      .firstOrNull;
}
