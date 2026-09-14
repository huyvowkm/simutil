class DeviceControlResult {
  const DeviceControlResult.success(this.message) : success = true;

  const DeviceControlResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}
