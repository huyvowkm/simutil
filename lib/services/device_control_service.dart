import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_control_result.dart';
import 'package:simutil/models/device_control_state.dart';
import 'package:simutil/models/device_navigation_mode.dart';
import 'package:simutil/models/device_network_mode.dart';
import 'package:simutil/models/device_text_size.dart';

abstract interface class DeviceControlService {
  bool supports(Device device);

  bool get supportsTimeZone;

  bool get supportsNetwork;

  bool get supportsNavigationMode;

  bool supportsLanguage(Device device);

  Future<DeviceControlState> getState(Device device);

  Future<DeviceControlResult> setAppearance(
    Device device,
    DeviceAppearance appearance,
  );

  Future<DeviceControlResult> setTextSize(Device device, DeviceTextSize size);

  Future<DeviceControlResult> setTimeZone(Device device, String timeZone);

  Future<DeviceControlResult> setNetworkMode(
    Device device,
    DeviceNetworkMode mode,
  );

  Future<DeviceControlResult> setNavigationMode(
    Device device,
    DeviceNavigationMode mode,
  );

  Future<DeviceControlResult> setLanguage(Device device, String locale);
}
