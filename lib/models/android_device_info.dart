class AndroidDeviceInfo {
  const AndroidDeviceInfo({
    this.androidVersion,
    this.apiLevel,
    this.ramUsedBytes,
    this.ramTotalBytes,
    this.storageUsedBytes,
    this.storageTotalBytes,
  });

  final String? androidVersion;
  final int? apiLevel;
  final int? ramUsedBytes;
  final int? ramTotalBytes;
  final int? storageUsedBytes;
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
