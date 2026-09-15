import 'dart:io';

import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_control_result.dart';
import 'package:simutil/models/device_control_state.dart';
import 'package:simutil/models/device_network_mode.dart';
import 'package:simutil/models/device_os.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/models/device_type.dart';
import 'package:simutil/services/command_exec.dart';
import 'package:simutil/services/device_control_service.dart';

class IOSDeviceControlService implements DeviceControlService {
  IOSDeviceControlService(this._exec, {bool Function()? isMacOS})
    : _isMacOS = isMacOS ?? (() => Platform.isMacOS);

  final CommandExec _exec;
  final bool Function() _isMacOS;

  static const _contentSizes = {
    DeviceTextSize.small: 'small',
    DeviceTextSize.normal: 'medium',
    DeviceTextSize.large: 'large',
    DeviceTextSize.extraLarge: 'extra-large',
    DeviceTextSize.accessibilityLarge: 'accessibility-large',
    DeviceTextSize.accessibilityExtraLarge:
        'accessibility-extra-extra-extra-large',
  };

  @override
  bool supports(Device device) =>
      _isMacOS() &&
      device.os == DeviceOs.ios &&
      device.type == DeviceType.simulator &&
      device.isRunning;

  @override
  bool get supportsTimeZone => false;

  @override
  bool get supportsNetwork => false;

  @override
  Future<DeviceControlState> getState(Device device) async {
    if (!supports(device)) return const DeviceControlState();
    return DeviceControlState(
      appearance: await _readAppearance(device),
      textSize: await _readTextSize(device),
    );
  }

  @override
  Future<DeviceControlResult> setAppearance(
    Device device,
    DeviceAppearance appearance,
  ) => _run(device, [
    'ui',
    device.id,
    'appearance',
    appearance.name,
  ], successMessage: 'Appearance set to ${appearance.label}');

  @override
  Future<DeviceControlResult> setTextSize(Device device, DeviceTextSize size) =>
      _run(device, [
        'ui',
        device.id,
        'content_size',
        _contentSizes[size]!,
      ], successMessage: 'Text size set to ${size.label}');

  @override
  Future<DeviceControlResult> setTimeZone(
    Device device,
    String timeZone,
  ) async => const DeviceControlResult.failure(
    'System time zone is not available for iOS simulators yet.',
  );

  @override
  Future<DeviceControlResult> setNetworkMode(
    Device device,
    DeviceNetworkMode mode,
  ) async => const DeviceControlResult.failure(
    'Network controls are not available for iOS simulators.',
  );

  Future<DeviceAppearance?> _readAppearance(Device device) async {
    final result = await _trySimctl(device, ['ui', device.id, 'appearance']);
    if (result == null || !result.success) return null;
    return DeviceAppearance.values
        .where(
          (appearance) => result.stdout.toLowerCase().contains(appearance.name),
        )
        .firstOrNull;
  }

  Future<DeviceTextSize?> _readTextSize(Device device) async {
    final result = await _trySimctl(device, ['ui', device.id, 'content_size']);
    if (result == null || !result.success) return null;
    return _contentSizes.entries
        .where((entry) => result.stdout.contains(entry.value))
        .map((entry) => entry.key)
        .firstOrNull;
  }

  Future<DeviceControlResult> _run(
    Device device,
    List<String> arguments, {
    required String successMessage,
  }) async {
    if (!supports(device)) {
      return const DeviceControlResult.failure(
        'Controls require a running iOS Simulator on macOS.',
      );
    }
    final result = await _trySimctl(device, arguments);
    if (result?.success ?? false) {
      return DeviceControlResult.success(successMessage);
    }
    return DeviceControlResult.failure(_failureMessage(result));
  }

  Future<CommandResult?> _trySimctl(
    Device device,
    List<String> arguments,
  ) async {
    try {
      return await _exec.run('xcrun', arguments: ['simctl', ...arguments]);
    } catch (_) {
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
        ? 'Unable to update iOS Simulator controls.'
        : message;
  }
}
