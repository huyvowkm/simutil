enum DeviceNavigationMode {
  gesture('Gesture', 'com.android.internal.systemui.navbar.gestural'),
  twoButton('2-button', 'com.android.internal.systemui.navbar.twobutton'),
  threeButton('3-button', 'com.android.internal.systemui.navbar.threebutton');

  const DeviceNavigationMode(this.label, this.overlayPackage);

  final String label;
  final String overlayPackage;
}
