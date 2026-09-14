class AndroidDeviceInfo {
  const AndroidDeviceInfo({
    this.androidVersion,
    this.apiLevel,
    this.ramAvailableBytes,
    this.ramTotalBytes,
    this.storageAvailableBytes,
    this.storageTotalBytes,
  });

  final String? androidVersion;
  final int? apiLevel;
  final int? ramAvailableBytes;
  final int? ramTotalBytes;
  final int? storageAvailableBytes;
  final int? storageTotalBytes;
}

class AndroidMemoryInfo {
  const AndroidMemoryInfo({
    required this.availableBytes,
    required this.totalBytes,
  });

  final int availableBytes;
  final int totalBytes;
}

class AndroidStorageInfo {
  const AndroidStorageInfo({
    required this.availableBytes,
    required this.totalBytes,
  });

  final int availableBytes;
  final int totalBytes;
}
