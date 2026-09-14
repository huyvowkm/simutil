import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:simutil/components/show_overlay_dialog.dart';
import 'package:simutil/components/simutil_icons.dart';
import 'package:simutil/components/simutil_theme.dart';
import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/services/device_control_service.dart';

class DeviceControlsDialog extends StatefulComponent {
  const DeviceControlsDialog({
    super.key,
    required this.device,
    required this.service,
    required this.onClose,
  });

  final Device device;
  final DeviceControlService service;
  final VoidCallback onClose;

  @override
  State<DeviceControlsDialog> createState() => _DeviceControlsDialogState();
}

class _DeviceControlsDialogState extends State<DeviceControlsDialog> {
  static const _timeZones = [
    'UTC',
    'America/Los_Angeles',
    'Europe/London',
    'Asia/Ho_Chi_Minh',
    'Asia/Tokyo',
  ];

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isApplying = false;
  DeviceAppearance? _appearance;
  DeviceTextSize? _textSize;
  String? _timeZone;
  String? _message;

  int get _rowCount => component.service.supportsTimeZone ? 3 : 2;

  @override
  void initState() {
    super.initState();
    unawaited(_loadState());
  }

  Future<void> _loadState() async {
    final state = await component.service.getState(component.device);
    if (!mounted) return;
    setState(() {
      _appearance = state.appearance;
      _textSize = state.textSize;
      _timeZone = state.timeZone;
      _isLoading = false;
    });
  }

  @override
  Component build(BuildContext context) {
    final st = context.simutilTheme;
    return Center(
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: st.dialogPanel('Device Controls: ${component.device.name}'),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Focusable(
            focused: true,
            onKeyEvent: _handleKeyEvent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _row(st, 0, 'Appearance', _appearance?.label ?? 'Unknown'),
                _row(st, 1, 'Text Size', _textSize?.label ?? 'Unknown'),
                if (component.service.supportsTimeZone)
                  _row(st, 2, 'Time Zone', _timeZone ?? 'Unknown'),
                if (_message != null) ...[
                  SizedBox(height: 1),
                  Text(' $_message', style: st.dimmed),
                ],
                SizedBox(height: 1),
                Divider(),
                Text(
                  _isLoading
                      ? ' Loading current settings…'
                      : _isApplying
                      ? ' Applying…'
                      : ' Navigate: <↑/↓> | Choose: <←/→> | Apply: <enter> | Close: <esc>',
                  style: st.dimmed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Component _row(SimutilTheme st, int index, String label, String value) {
    final selected = index == _selectedIndex;
    return Row(
      children: [
        Text(selected ? ' ${SimutilIcons.pointer} ' : '   ', style: st.label),
        SizedBox(width: 14, child: Text(label, style: st.label)),
        Text(': $value', style: selected ? st.selected : st.body),
      ],
    );
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.escape) {
      component.onClose();
      return true;
    }
    if (_isLoading || _isApplying) return true;

    switch (event.logicalKey) {
      case LogicalKey.arrowUp:
        setState(() => _selectedIndex = (_selectedIndex - 1) % _rowCount);
        return true;
      case LogicalKey.arrowDown:
        setState(() => _selectedIndex = (_selectedIndex + 1) % _rowCount);
        return true;
      case LogicalKey.arrowLeft:
        _cycleValue(-1);
        return true;
      case LogicalKey.arrowRight:
        _cycleValue(1);
        return true;
      case LogicalKey.enter:
        unawaited(_applySelectedValue());
        return true;
      default:
        return false;
    }
  }

  void _cycleValue(int offset) {
    setState(() {
      switch (_selectedIndex) {
        case 0:
          _appearance = _cycle(DeviceAppearance.values, _appearance, offset);
        case 1:
          _textSize = _cycle(DeviceTextSize.values, _textSize, offset);
        case 2:
          _timeZone = _cycle(_timeZones, _timeZone, offset);
      }
    });
  }

  T _cycle<T>(List<T> values, T? current, int offset) {
    final currentIndex = current == null ? 0 : values.indexOf(current);
    return values[(currentIndex + offset + values.length) % values.length];
  }

  Future<void> _applySelectedValue() async {
    setState(() {
      _isApplying = true;
      _message = null;
    });
    final result = switch (_selectedIndex) {
      0 => await component.service.setAppearance(
        component.device,
        _appearance ?? DeviceAppearance.light,
      ),
      1 => await component.service.setTextSize(
        component.device,
        _textSize ?? DeviceTextSize.normal,
      ),
      _ => await component.service.setTimeZone(
        component.device,
        _timeZone ?? _timeZones.first,
      ),
    };
    if (!mounted) return;
    setState(() {
      _isApplying = false;
      _message = result.message;
    });
  }
}

Future<void> showDeviceControlsDialog({
  required BuildContext context,
  required Device device,
  required DeviceControlService service,
}) async {
  await showOverlayDialog<bool>(
    context: context,
    builder: (context, completer, entry) => DeviceControlsDialog(
      device: device,
      service: service,
      onClose: () {
        completer.complete(true);
        entry?.remove();
      },
    ),
  );
}
