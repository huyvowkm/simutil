import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_control_result.dart';
import 'package:simutil/models/device_control_state.dart';
import 'package:simutil/models/device_text_size.dart';

abstract interface class DeviceControlService {
  bool supports(Device device);

  bool get supportsTimeZone;

  Future<DeviceControlState> getState(Device device);

  Future<DeviceControlResult> setAppearance(
    Device device,
    DeviceAppearance appearance,
  );

  Future<DeviceControlResult> setTextSize(Device device, DeviceTextSize size);

  Future<DeviceControlResult> setTimeZone(Device device, String timeZone);
}
