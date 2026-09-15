enum DeviceNetworkMode {
  wifi('Wi-Fi'),
  mobileData('Mobile Data'),
  both('Both'),
  none('None');

  const DeviceNetworkMode(this.label);

  final String label;
}
