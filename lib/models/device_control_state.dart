import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_text_size.dart';

class DeviceControlState {
  const DeviceControlState({this.appearance, this.textSize, this.locale});

  final DeviceAppearance? appearance;
  final DeviceTextSize? textSize;
  final String? locale;
}
