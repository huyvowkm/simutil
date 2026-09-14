import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_state.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/models/device_type.dart';
import 'package:simutil/services/android_device_control_service.dart';
import 'package:simutil/services/android_device_service.dart';
import 'package:test/test.dart';

import 'fake_command_exec.dart';

void main() {
  final emulator = Device.android(
    id: 'emulator-5556',
    name: 'Pixel 9',
    state: DeviceState.booted,
    type: DeviceType.simulator,
  );
  final shutdownEmulator = Device.android(
    id: 'emulator-5556',
    name: 'Pixel 9',
    state: DeviceState.shutdown,
    type: DeviceType.simulator,
  );

  AndroidDeviceControlService service(FakeCommandExec exec) {
    final deviceService = AndroidDeviceService(
      exec,
      environment: {'HOME': '/home/test'},
      fileExists: (_) => false,
    );
    return AndroidDeviceControlService(exec, deviceService);
  }

  test('targets the selected emulator when enabling dark appearance', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setAppearance(emulator, DeviceAppearance.dark);

    expect(result.success, isTrue);
    expect(exec.calls.single.command, 'adb');
    expect(exec.calls.single.arguments, [
      '-s',
      'emulator-5556',
      'shell',
      'cmd',
      'uimode',
      'night',
      'yes',
    ]);
  });

  test('uses the mapped Android scale for text size', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setTextSize(emulator, DeviceTextSize.extraLarge);

    expect(result.success, isTrue);
    expect(exec.calls.single.arguments, [
      '-s',
      'emulator-5556',
      'shell',
      'settings',
      'put',
      'system',
      'font_scale',
      '1.3',
    ]);
  });

  test('sets locale for the selected emulator', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(exec).setLocale(emulator, 'vi-VN');

    expect(result.success, isTrue);
    expect(exec.calls.single.arguments, [
      '-s',
      'emulator-5556',
      'shell',
      'setprop',
      'persist.sys.locale',
      'vi-VN',
    ]);
  });

  test('returns stderr when an Android command fails', () async {
    final exec = FakeCommandExec(
      (_, _) => FakeCommandExec.fail('device offline'),
    );

    final result = await service(
      exec,
    ).setAppearance(emulator, DeviceAppearance.light);

    expect(result.success, isFalse);
    expect(result.message, 'device offline');
  });

  test('does not invoke adb for a shutdown emulator', () async {
    final exec = FakeCommandExec((_, _) => FakeCommandExec.ok());

    final result = await service(
      exec,
    ).setAppearance(shutdownEmulator, DeviceAppearance.dark);

    expect(result.success, isFalse);
    expect(exec.calls, isEmpty);
  });
}
