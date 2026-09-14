import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_state.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/models/device_type.dart';
import 'package:simutil/services/ios_device_control_service.dart';
import 'package:test/test.dart';

import 'fake_command_exec.dart';

void main() {
  final simulator = Device.ios(
    id: 'ios-udid-123',
    name: 'iPhone 17',
    state: DeviceState.booted,
    type: DeviceType.simulator,
  );
  final physicalDevice = Device.ios(
    id: 'ios-device-123',
    name: 'iPhone',
    state: DeviceState.booted,
    type: DeviceType.physical,
  );

  IOSDeviceControlService service(FakeCommandExec exec) =>
      IOSDeviceControlService(exec, isMacOS: () => true);

  test('sets Simulator appearance with its UDID', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setAppearance(simulator, DeviceAppearance.dark);

    expect(result.success, isTrue);
    expect(exec.calls.single.command, 'xcrun');
    expect(exec.calls.single.arguments, [
      'simctl',
      'ui',
      'ios-udid-123',
      'appearance',
      'dark',
    ]);
  });

  test('maps accessibility text size to simctl content_size', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setTextSize(simulator, DeviceTextSize.accessibilityExtraLarge);

    expect(result.success, isTrue);
    expect(exec.calls.single.arguments, [
      'simctl',
      'ui',
      'ios-udid-123',
      'content_size',
      'accessibility-extra-extra-extra-large',
    ]);
  });

  test('does not execute simctl for a physical iOS device', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setAppearance(physicalDevice, DeviceAppearance.light);

    expect(result.success, isFalse);
    expect(exec.calls, isEmpty);
  });

  test('returns simctl stderr on failure', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.fail('unsupported'));

    final result = await service(
      exec,
    ).setTextSize(simulator, DeviceTextSize.large);

    expect(result.success, isFalse);
    expect(result.message, 'unsupported');
  });
}
