enum DeviceTextSize {
  small('Small'),
  normal('Normal'),
  large('Large'),
  extraLarge('Extra Large'),
  accessibilityLarge('Accessibility Large'),
  accessibilityExtraLarge('Accessibility XL');

  const DeviceTextSize(this.label);

  final String label;
}
