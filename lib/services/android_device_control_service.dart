import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_control_result.dart';
import 'package:simutil/models/device_control_state.dart';
import 'package:simutil/models/device_network_mode.dart';
import 'package:simutil/models/device_os.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/services/android_device_service.dart';
import 'package:simutil/services/command_exec.dart';
import 'package:simutil/services/device_control_service.dart';

class AndroidDeviceControlService implements DeviceControlService {
  AndroidDeviceControlService(this._exec, this._deviceService);

  final CommandExec _exec;
  final AndroidDeviceService _deviceService;

  static const _fontScales = {
    DeviceTextSize.small: 0.85,
    DeviceTextSize.normal: 1.0,
    DeviceTextSize.large: 1.15,
    DeviceTextSize.extraLarge: 1.30,
    DeviceTextSize.accessibilityLarge: 1.50,
    DeviceTextSize.accessibilityExtraLarge: 2.0,
  };

  @override
  bool supports(Device device) =>
      device.os == DeviceOs.android && device.isRunning;

  @override
  bool get supportsTimeZone => true;

  @override
  bool get supportsNetwork => true;

  @override
  Future<DeviceControlState> getState(Device device) async {
    if (!supports(device)) return const DeviceControlState();

    final results = await Future.wait([
      _readAppearance(device),
      _readTextSize(device),
      _readTimeZone(device),
      _readNetworkMode(device),
    ]);
    return DeviceControlState(
      appearance: results[0] as DeviceAppearance?,
      textSize: results[1] as DeviceTextSize?,
      timeZone: results[2] as String?,
      networkMode: results[3] as DeviceNetworkMode?,
    );
  }

  @override
  Future<DeviceControlResult> setAppearance(
    Device device,
    DeviceAppearance appearance,
  ) => _run(device, [
    'shell',
    'cmd',
    'uimode',
    'night',
    appearance == DeviceAppearance.dark ? 'yes' : 'no',
  ], successMessage: 'Appearance set to ${appearance.label}');

  @override
  Future<DeviceControlResult> setTextSize(Device device, DeviceTextSize size) =>
      _run(device, [
        'shell',
        'settings',
        'put',
        'system',
        'font_scale',
        _fontScales[size]!.toString(),
      ], successMessage: 'Text size set to ${size.label}');

  @override
  Future<DeviceControlResult> setTimeZone(Device device, String timeZone) =>
      _run(device, [
        'shell',
        'cmd',
        'alarm',
        'set-timezone',
        timeZone,
      ], successMessage: 'Time zone set to $timeZone.');

  @override
  Future<DeviceControlResult> setNetworkMode(
    Device device,
    DeviceNetworkMode mode,
  ) async {
    final wifiEnabled = switch (mode) {
      DeviceNetworkMode.wifi || DeviceNetworkMode.both => true,
      DeviceNetworkMode.mobileData || DeviceNetworkMode.none => false,
    };
    final mobileDataEnabled = switch (mode) {
      DeviceNetworkMode.mobileData || DeviceNetworkMode.both => true,
      DeviceNetworkMode.wifi || DeviceNetworkMode.none => false,
    };
    return _runAll(device, [
      ['shell', 'svc', 'wifi', wifiEnabled ? 'enable' : 'disable'],
      [
        'shell',
        'cmd',
        'phone',
        'data',
        mobileDataEnabled ? 'enable' : 'disable',
      ],
    ], successMessage: 'Network set to ${mode.label}');
  }

  Future<DeviceAppearance?> _readAppearance(Device device) async {
    final result = await _tryAdb(device, ['shell', 'cmd', 'uimode', 'night']);
    if (result == null || !result.success) return null;
    final output = result.stdout.toLowerCase();
    if (output.contains('yes')) return DeviceAppearance.dark;
    if (output.contains('no')) return DeviceAppearance.light;
    return null;
  }

  Future<DeviceTextSize?> _readTextSize(Device device) async {
    final result = await _tryAdb(device, [
      'shell',
      'settings',
      'get',
      'system',
      'font_scale',
    ]);
    final scale = result == null ? null : double.tryParse(result.stdout.trim());
    if (scale == null) return null;
    return _fontScales.entries
        .where((entry) => (entry.value - scale).abs() < 0.01)
        .map((entry) => entry.key)
        .firstOrNull;
  }

  Future<String?> _readTimeZone(Device device) async {
    final result = await _tryAdb(device, [
      'shell',
      'getprop',
      'persist.sys.timezone',
    ]);
    final timeZone = result?.stdout.trim();
    return timeZone == null || timeZone.isEmpty ? null : timeZone;
  }

  Future<DeviceNetworkMode?> _readNetworkMode(Device device) async {
    final results = await Future.wait([
      _tryAdb(device, ['shell', 'settings', 'get', 'global', 'wifi_on']),
      _tryAdb(device, ['shell', 'settings', 'get', 'global', 'mobile_data']),
    ]);
    final wifiEnabled = results[0]?.stdout.trim() == '1';
    final mobileDataEnabled = results[1]?.stdout.trim() == '1';
    return switch ((wifiEnabled, mobileDataEnabled)) {
      (true, true) => DeviceNetworkMode.both,
      (true, false) => DeviceNetworkMode.wifi,
      (false, true) => DeviceNetworkMode.mobileData,
      (false, false) => DeviceNetworkMode.none,
    };
  }

  Future<DeviceControlResult> _run(
    Device device,
    List<String> arguments, {
    required String successMessage,
  }) async {
    if (!supports(device)) {
      return const DeviceControlResult.failure(
        'Controls require a running Android device.',
      );
    }
    final result = await _tryAdb(device, arguments);
    if (result?.success ?? false) {
      return DeviceControlResult.success(successMessage);
    }
    return DeviceControlResult.failure(_failureMessage(result));
  }

  Future<DeviceControlResult> _runAll(
    Device device,
    List<List<String>> commands, {
    required String successMessage,
  }) async {
    if (!supports(device)) {
      return const DeviceControlResult.failure(
        'Controls require a running Android device.',
      );
    }
    for (final command in commands) {
      final result = await _tryAdb(device, command);
      if (!(result?.success ?? false)) {
        return DeviceControlResult.failure(_failureMessage(result));
      }
    }
    return DeviceControlResult.success(successMessage);
  }

  Future<CommandResult?> _tryAdb(Device device, List<String> arguments) async {
    try {
      return await _exec.run(
        _deviceService.adbPath,
        arguments: ['-s', device.id, ...arguments],
      );
    } catch (error) {
      return null;
    }
  }

  String _failureMessage(CommandResult? result) {
    final message = result == null
        ? ''
        : result.stderr.trim().isNotEmpty
        ? result.stderr.trim()
        : result.stdout.trim();
    return message.isEmpty
        ? 'Unable to update Android device controls.'
        : message;
  }
}
