import 'package:nocterm/nocterm.dart';
import 'package:simutil/components/simutil_theme.dart';
import 'package:simutil/models/android_device_info.dart';
import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_os.dart';
import 'package:simutil/utils/int_extension.dart';

class DeviceDetailPanel extends StatelessComponent {
  const DeviceDetailPanel({
    super.key,
    this.device,
    this.androidInfo,
    this.loadingAndroidInfo = false,
    this.focused = false,
  });

  final Device? device;
  final AndroidDeviceInfo? androidInfo;
  final bool loadingAndroidInfo;
  final bool focused;

  @override
  Component build(BuildContext context) {
    final st = context.simutilTheme;

    return Container(
      decoration: focused
          ? st.focusedPanel('Details')
          : st.unfocusedPanel('Details'),
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: device != null ? _buildInfo(st, device!) : _buildEmpty(st),
    );
  }

  Component _buildInfo(SimutilTheme st, Device device) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(st, label: 'Name', value: device.name),
          _row(st, label: 'ID', value: device.id),
          _row(st, label: 'Platform', value: device.platform),
          _row(st, label: 'Type', value: device.os.label),
          _row(st, label: 'State', value: device.state.label),
          if (device.os == DeviceOs.android) ...[
            _row(st, label: 'Android', value: _androidVersionLabel()),
            _row(st, label: 'RAM', value: _memoryLabel()),
            _row(st, label: 'Storage', value: _storageLabel()),
          ],
        ],
      ),
    );
  }

  String _androidVersionLabel() {
    if (loadingAndroidInfo) return 'Loading…';
    final info = androidInfo;
    if (info == null) return 'Unavailable';
    final version = info.androidVersion ?? 'Unknown';
    final api = info.apiLevel;
    return api == null ? version : '$version (API $api)';
  }

  String _memoryLabel() {
    final info = androidInfo;
    if (loadingAndroidInfo) return 'Loading…';
    if (info?.ramAvailableBytes == null || info?.ramTotalBytes == null) {
      return 'Unavailable';
    }
    return '${info!.ramAvailableBytes!.formatBytes} free / '
        '${info.ramTotalBytes!.formatBytes}';
  }

  String _storageLabel() {
    final info = androidInfo;
    if (loadingAndroidInfo) return 'Loading…';
    if (info?.storageAvailableBytes == null ||
        info?.storageTotalBytes == null) {
      return 'Unavailable';
    }
    return '${info!.storageAvailableBytes!.formatBytes} free / '
        '${info.storageTotalBytes!.formatBytes}';
  }

  Component _buildEmpty(SimutilTheme st) {
    return Center(
      child: Text('Select a device to view details', style: st.muted),
    );
  }

  Component _row(
    SimutilTheme st, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        SizedBox(width: 12, child: Text(label, style: st.label)),
        Text(': $value', style: st.body),
      ],
    );
  }
}
