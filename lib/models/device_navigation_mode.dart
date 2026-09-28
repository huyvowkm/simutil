enum DeviceNavigationMode {
  gesture('Gesture', '2'),
  twoButton('2-button', '1'),
  threeButton('3-button', '0');

  const DeviceNavigationMode(this.label, this.settingValue);

  final String label;
  final String settingValue;

  static DeviceNavigationMode? fromSettingValue(String value) =>
      DeviceNavigationMode.values
          .where((mode) => mode.settingValue == value)
          .firstOrNull;
}
