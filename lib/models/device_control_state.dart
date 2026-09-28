import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_navigation_mode.dart';
import 'package:simutil/models/device_network_mode.dart';
import 'package:simutil/models/device_text_size.dart';

class DeviceControlState {
  const DeviceControlState({
    this.appearance,
    this.textSize,
    this.timeZone,
    this.networkMode,
    this.navigationMode,
    this.language,
  });

  final DeviceAppearance? appearance;
  final DeviceTextSize? textSize;
  final String? timeZone;
  final DeviceNetworkMode? networkMode;
  final DeviceNavigationMode? navigationMode;
  final String? language;
}
