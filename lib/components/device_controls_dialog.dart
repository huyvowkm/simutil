import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:simutil/components/simutil_icons.dart';
import 'package:simutil/components/simutil_theme.dart';
import 'package:simutil/models/device.dart';
import 'package:simutil/models/device_appearance.dart';
import 'package:simutil/models/device_control_result.dart';
import 'package:simutil/models/device_language.dart';
import 'package:simutil/models/device_navigation_mode.dart';
import 'package:simutil/models/device_network_mode.dart';
import 'package:simutil/models/device_text_size.dart';
import 'package:simutil/services/device_control_service.dart';

class DeviceControlsPanel extends StatefulComponent {
  const DeviceControlsPanel({
    super.key,
    required this.device,
    required this.service,
    required this.focused,
  });

  final Device device;
  final DeviceControlService service;
  final bool focused;

  @override
  State<DeviceControlsPanel> createState() => _DeviceControlsPanelState();
}

class _DeviceControlsPanelState extends State<DeviceControlsPanel> {
  static const _timeZones = [
    'UTC',
    'America/Los_Angeles',
    'Europe/London',
    'Asia/Ho_Chi_Minh',
    'Asia/Tokyo',
  ];
  static const _networkModes = DeviceNetworkMode.values;
  static const _navigationModes = DeviceNavigationMode.values;
  static const _languages = DeviceLanguage.values;

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isApplying = false;
  DeviceAppearance? _appearance;
  DeviceTextSize? _textSize;
  String? _timeZone;
  DeviceNetworkMode? _networkMode;
  DeviceNavigationMode? _navigationMode;
  DeviceLanguage? _language;
  String? _languageCode;
  String? _message;

  int get _rowCount =>
      2 +
      (component.service.supportsTimeZone ? 1 : 0) +
      (component.service.supportsNetwork ? 1 : 0) +
      (component.service.supportsNavigationMode ? 1 : 0) +
      (component.service.supportsLanguage(component.device) ? 1 : 0);

  int get _networkIndex => 2 + (component.service.supportsTimeZone ? 1 : 0);

  int get _navigationModeIndex =>
      _networkIndex + (component.service.supportsNetwork ? 1 : 0);

  int get _languageIndex =>
      _navigationModeIndex + (component.service.supportsNavigationMode ? 1 : 0);

  @override
  void initState() {
    super.initState();
    unawaited(_loadState());
  }

  @override
  void didUpdateComponent(DeviceControlsPanel oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.device.id == component.device.id) return;
    setState(() {
      _isLoading = true;
      _appearance = null;
      _textSize = null;
      _timeZone = null;
      _networkMode = null;
      _navigationMode = null;
      _language = null;
      _languageCode = null;
      _message = null;
    });
    unawaited(_loadState());
  }

  Future<void> _loadState() async {
    final state = await component.service.getState(component.device);
    if (!mounted) return;
    setState(() {
      _appearance = state.appearance;
      _textSize = state.textSize;
      _timeZone = state.timeZone;
      _networkMode = state.networkMode;
      _navigationMode = state.navigationMode;
      _languageCode = state.language;
      _language = DeviceLanguage.fromLocale(state.language ?? '');
      _isLoading = false;
    });
  }

  @override
  Component build(BuildContext context) {
    final st = context.simutilTheme;
    var rowIndex = 0;
    final content = Padding(
      padding: EdgeInsets.all(1),
      child: Focusable(
        focused: component.focused,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(st, rowIndex++, 'Appearance', _appearance?.label ?? 'Unknown'),
            _row(st, rowIndex++, 'Text Size', _textSize?.label ?? 'Unknown'),
            if (component.service.supportsTimeZone)
              _row(st, rowIndex++, 'Time Zone', _timeZone ?? 'Unknown'),
            if (component.service.supportsNetwork)
              _row(st, rowIndex++, 'Network', _networkMode?.label ?? 'Unknown'),
            if (component.service.supportsNavigationMode)
              _row(
                st,
                rowIndex++,
                'Navigation',
                _navigationMode?.label ?? 'Unknown',
              ),
            if (component.service.supportsLanguage(component.device))
              _row(
                st,
                rowIndex++,
                'Language',
                _language?.label ?? _languageCode ?? 'Unknown',
              ),
            if (component.service.supportsLanguage(component.device) &&
                _selectedIndex == _languageIndex)
              Text(' Changing language restarts Android.', style: st.dimmed),
            if (_message != null) ...[
              SizedBox(height: 1),
              Text(' $_message', style: st.dimmed),
            ],
            if (_isLoading || _isApplying) ...[
              SizedBox(height: 1),
              Text(
                _isLoading ? ' Loading current settings…' : ' Applying…',
                style: st.dimmed,
              ),
            ],
          ],
        ),
      ),
    );
    return Container(
      decoration: component.focused
          ? st.focusedPanel('Controls')
          : st.unfocusedPanel('Controls'),
      child: content,
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
    if (event.logicalKey == LogicalKey.escape) return false;
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
      if (_selectedIndex == 0) {
        _appearance = _cycle(DeviceAppearance.values, _appearance, offset);
      } else if (_selectedIndex == 1) {
        _textSize = _cycle(DeviceTextSize.values, _textSize, offset);
      } else if (component.service.supportsTimeZone && _selectedIndex == 2) {
        _timeZone = _cycle(_timeZones, _timeZone, offset);
      } else if (component.service.supportsNetwork &&
          _selectedIndex == _networkIndex) {
        _networkMode = _cycle(_networkModes, _networkMode, offset);
      } else if (component.service.supportsNavigationMode &&
          _selectedIndex == _navigationModeIndex) {
        _navigationMode = _cycle(_navigationModes, _navigationMode, offset);
      } else if (component.service.supportsLanguage(component.device) &&
          _selectedIndex == _languageIndex) {
        _language = _cycle(_languages, _language, offset);
        _languageCode = _language?.locale;
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
    final service = component.service;
    final device = component.device;
    late final DeviceControlResult result;
    if (_selectedIndex == 0) {
      result = await service.setAppearance(
        device,
        _appearance ?? DeviceAppearance.light,
      );
    } else if (_selectedIndex == 1) {
      result = await service.setTextSize(
        device,
        _textSize ?? DeviceTextSize.normal,
      );
    } else if (service.supportsTimeZone && _selectedIndex == 2) {
      result = await service.setTimeZone(device, _timeZone ?? _timeZones.first);
    } else if (service.supportsNetwork && _selectedIndex == _networkIndex) {
      result = await service.setNetworkMode(
        device,
        _networkMode ?? DeviceNetworkMode.both,
      );
    } else if (service.supportsNavigationMode &&
        _selectedIndex == _navigationModeIndex) {
      result = await service.setNavigationMode(
        device,
        _navigationMode ?? DeviceNavigationMode.gesture,
      );
    } else if (service.supportsLanguage(device) &&
        _selectedIndex == _languageIndex) {
      result = await service.setLanguage(
        device,
        _language?.locale ?? _languages.first.locale,
      );
    } else {
      result = const DeviceControlResult.failure('Unknown device control.');
    }
    if (!mounted) return;
    setState(() {
      _isApplying = false;
      _message = result.message;
    });
  }
}
