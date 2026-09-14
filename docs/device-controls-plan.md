# simutil Device Controls — Fork Implementation Plan

## Goal

Extend the `dungngminh/simutil` fork with a **Device Controls** feature for running Android emulators and iOS simulators.

Initial controls:

- Appearance: Light / Dark
- Font / text size
- Time zone
- Read current values where practical
- Clear error handling when a control is unsupported
- Keyboard-driven Nocterm UI consistent with existing simutil dialogs

Recommended v1 scope:

- Android emulator: supported
- Android physical device: supported where normal ADB commands allow it
- iOS Simulator: supported
- iOS physical device: do not expose these controls in v1

The first version should focus on reliable emulator/simulator development workflows rather than trying to manipulate every real-device setting.

---

## 1. Fork setup

Fork:

`https://github.com/dungngminh/simutil`

Then clone your fork:

```bash
git clone git@github.com:<YOUR_GITHUB_USERNAME>/simutil.git
cd simutil
```

Keep the original repository as `upstream`:

```bash
git remote add upstream https://github.com/dungngminh/simutil.git
git remote -v
```

Expected:

```text
origin    git@github.com:<YOU>/simutil.git
upstream  https://github.com/dungngminh/simutil.git
```

Create a feature branch:

```bash
git checkout -b feat/device-controls
```

Before starting future work:

```bash
git fetch upstream
git rebase upstream/main
```

---

## 2. Existing architecture to preserve

The existing repository already has a useful separation:

```text
lib/
├── components/
├── models/
├── plugins/
├── services/
│   ├── android_device_service.dart
│   ├── ios_device_service.dart
│   ├── command_exec.dart
│   ├── device_service.dart
│   └── service_locator.dart
└── simutil_app.dart
```

`AndroidDeviceService` and `IOSDeviceService` currently handle discovery, launch, shutdown, and platform-specific device operations.

`CommandExec` is already injected into those services, so new device-control services can use the same testable command execution abstraction.

Do **not** put all new control methods directly into `DeviceService`.

Device discovery/lifecycle and device configuration are different responsibilities.

Recommended structure:

```text
DeviceService
    ├── AndroidDeviceService
    └── IOSDeviceService

DeviceControlService
    ├── AndroidDeviceControlService
    └── IOSDeviceControlService
```

---

# 3. New files

## 3.1 `lib/models/device_appearance.dart`

Create:

```dart
enum DeviceAppearance {
  light,
  dark,
}
```

Keep it platform-neutral.

---

## 3.2 `lib/models/device_text_size.dart`

Create a semantic text-size model rather than leaking Android scale values or iOS `content_size` strings into the UI.

Example:

```dart
enum DeviceTextSize {
  small,
  normal,
  large,
  extraLarge,
  accessibilityLarge,
  accessibilityExtraLarge,
}
```

Platform services convert these values into platform-specific commands.

Suggested initial mappings:

| Value | Android `font_scale` | iOS `content_size` |
|---|---:|---|
| small | 0.85 | small |
| normal | 1.0 | medium |
| large | 1.15 | large |
| extraLarge | 1.30 | extra-large |
| accessibilityLarge | 1.50 | accessibility-large |
| accessibilityExtraLarge | 2.00 | accessibility-extra-extra-extra-large |

Treat the exact iOS accepted values as toolchain-dependent and keep the mapping in the iOS service so it is easy to update.

---

## 3.3 `lib/models/device_control_state.dart`

Optional but recommended.

```dart
class DeviceControlState {
  const DeviceControlState({
    this.appearance,
    this.textSize,
    this.timeZone,
  });

  final DeviceAppearance? appearance;
  final DeviceTextSize? textSize;
  final String? timeZone;
}
```

`null` means:

- unknown
- unsupported
- failed to query

Do not confuse `null` with a default value.

---

## 3.4 `lib/services/device_control_service.dart`

Create the platform-neutral contract.

Suggested API:

```dart
abstract class DeviceControlService {
  Future<bool> supportsDevice(Device device);

  Future<DeviceControlState> getState(Device device);

  Future<bool> setAppearance(
    Device device,
    DeviceAppearance appearance,
  );

  Future<bool> setTextSize(
    Device device,
    DeviceTextSize size,
  );

  Future<bool> setTimeZone(
    Device device,
    String timeZone,
  );
}
```

Alternatively, use `CommandResult` or a dedicated result class if you want to show detailed stderr messages in the TUI.

A better long-term result model would be:

```dart
class DeviceControlResult {
  const DeviceControlResult.success()
      : success = true,
        message = null;

  const DeviceControlResult.failure(this.message)
      : success = false;

  final bool success;
  final String? message;
}
```

That is preferable to `bool` if the UI should show useful errors.

---

# 4. Android implementation

## 4.1 New file

Create:

`lib/services/android_device_control_service.dart`

Constructor:

```dart
class AndroidDeviceControlService implements DeviceControlService {
  AndroidDeviceControlService(
    this._exec,
    this._deviceService,
  );

  final CommandExec _exec;
  final AndroidDeviceService _deviceService;
}
```

Re-use `AndroidDeviceService.adbPath`.

Do not duplicate Android SDK path detection.

---

## 4.2 Target a specific device

Every command must include:

```text
adb -s <device-id>
```

Never rely on the implicit default device, because simutil can show several Android devices/emulators simultaneously.

Helper:

```dart
Future<CommandResult> _adb(
  Device device,
  List<String> args,
) {
  return _exec.run(
    _deviceService.adbPath,
    arguments: [
      '-s',
      device.id,
      ...args,
    ],
  );
}
```

---

## 4.3 Android appearance

Set dark:

```bash
adb -s <serial> shell cmd uimode night yes
```

Set light:

```bash
adb -s <serial> shell cmd uimode night no
```

Read:

```bash
adb -s <serial> shell cmd uimode night
```

Implementation:

```dart
Future<bool> setAppearance(
  Device device,
  DeviceAppearance appearance,
) async {
  final value = switch (appearance) {
    DeviceAppearance.light => 'no',
    DeviceAppearance.dark => 'yes',
  };

  final result = await _adb(
    device,
    ['shell', 'cmd', 'uimode', 'night', value],
  );

  return result.success;
}
```

---

## 4.4 Android font size

Set:

```bash
adb -s <serial> shell settings put system font_scale 1.30
```

Read:

```bash
adb -s <serial> shell settings get system font_scale
```

Keep scale mapping inside `AndroidDeviceControlService`.

Example:

```dart
double _fontScale(DeviceTextSize size) {
  return switch (size) {
    DeviceTextSize.small => 0.85,
    DeviceTextSize.normal => 1.0,
    DeviceTextSize.large => 1.15,
    DeviceTextSize.extraLarge => 1.30,
    DeviceTextSize.accessibilityLarge => 1.50,
    DeviceTextSize.accessibilityExtraLarge => 2.0,
  };
}
```

Do not make arbitrary float entry part of v1 UI.

Presets make behavior predictable and testable.

---

## 4.5 Android time zone

Set a named IANA time zone for the selected Android device:

```bash
adb -s <serial> shell cmd alarm set-time-zone Asia/Ho_Chi_Minh
```

Read the current value:

```bash
adb -s <serial> shell getprop persist.sys.timezone
```

The first UI offers a short curated list: `UTC`, `America/Los_Angeles`,
`Europe/London`, `Asia/Ho_Chi_Minh`, and `Asia/Tokyo`. Every command must still
target the selected serial.

---

# 5. iOS implementation

## 5.1 New file

Create:

`lib/services/ios_device_control_service.dart`

Suggested constructor:

```dart
class IOSDeviceControlService implements DeviceControlService {
  const IOSDeviceControlService(this._exec);

  final CommandExec _exec;
}
```

Only accept:

```dart
device.os == DeviceOs.ios &&
device.type == DeviceType.simulator
```

Do not attempt these commands on physical iOS devices.

---

## 5.2 Common simctl helper

```dart
Future<CommandResult> _simctl(
  Device device,
  List<String> args,
) {
  return _exec.run(
    'xcrun',
    arguments: [
      'simctl',
      ...args,
    ],
  );
}
```

---

## 5.3 iOS appearance

Dark:

```bash
xcrun simctl ui <UDID> appearance dark
```

Light:

```bash
xcrun simctl ui <UDID> appearance light
```

Read:

```bash
xcrun simctl ui <UDID> appearance
```

Implementation:

```dart
Future<bool> setAppearance(
  Device device,
  DeviceAppearance appearance,
) async {
  final result = await _simctl(
    device,
    [
      'ui',
      device.id,
      'appearance',
      appearance.name,
    ],
  );

  return result.success;
}
```

---

## 5.4 iOS text size

Use:

```bash
xcrun simctl ui <UDID> content_size <SIZE>
```

Examples:

```bash
xcrun simctl ui <UDID> content_size large
```

```bash
xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large
```

Read current value:

```bash
xcrun simctl ui <UDID> content_size
```

Important:

Do not spread raw content-size strings through the application.

Keep them in a mapping:

```dart
String _contentSize(DeviceTextSize size) {
  return switch (size) {
    ...
  };
}
```

Before finalizing the list for your installed Xcode version, manually run:

```bash
xcrun simctl ui help
```

The accepted vocabulary can vary with Xcode/CoreSimulator versions.

---

# 6. iOS time zone

Do not use private Simulator preference files for a system time-zone setting.
`simctl` has no equivalent stable command in this feature, so iOS Simulator
does not expose this row in v1.

---

# 7. Service registration

Modify:

`lib/services/service_locator.dart`

Add:

```dart
late final AndroidDeviceControlService androidDeviceControlService =
    AndroidDeviceControlService(
      commandExec,
      adbService,
    );

late final IOSDeviceControlService iosDeviceControlService =
    IOSDeviceControlService(commandExec);
```

Suggested imports:

```dart
import 'package:simutil/services/android_device_control_service.dart';
import 'package:simutil/services/ios_device_control_service.dart';
```

Do not instantiate command executors inside the new services.

Use the existing shared `commandExec`.

---

# 8. TUI

## 8.1 New file

Create:

`lib/components/device_controls_dialog.dart`

The dialog should receive:

```dart
Device device
DeviceControlService service
```

or callbacks if you want the component to remain UI-only.

Recommended UX:

```text
┌ Device Controls ────────────────────────────┐
│ iPhone 17 Pro                              │
│                                            │
│ Appearance   > Dark                        │
│ Text Size      Normal                      │
│ Time Zone      —                           │
│                                            │
│ ↑/↓ Select   Enter Change   Esc Close      │
└────────────────────────────────────────────┘
```

Android:

```text
┌ Device Controls ────────────────────────────┐
│ Pixel 9 API 36                             │
│                                            │
│ Appearance   > Dark                        │
│ Font Size      1.30 / Extra Large          │
│ Time Zone      Asia/Ho_Chi_Minh             │
│                                            │
│ ↑/↓ Select   Enter Change   Esc Close      │
└────────────────────────────────────────────┘
```

---

## 8.2 Keep the first UI simple

Do not build inline editing for every value immediately.

Use nested selection dialogs:

```text
Device Controls
    ↓ Enter on Appearance

Appearance
├── Light
└── Dark
```

```text
Device Controls
    ↓ Enter on Text Size

Text Size
├── Small
├── Normal
├── Large
├── Extra Large
├── Accessibility Large
└── Accessibility XL
```

This matches a keyboard-first TUI better and reduces state complexity.

---

## 8.3 Running-device restriction

Theme/font configuration should only be available when the target device is running.

Before opening the dialog:

```dart
if (!device.isRunning) {
  showErrorDialog(
    ...
    message: 'Launch the simulator/emulator first.',
  );
  return;
}
```

Do not silently boot a device when opening controls.

Device controls should not unexpectedly alter lifecycle state.

---

# 9. Integrate into `lib/simutil_app.dart`

Modify:

`lib/simutil_app.dart`

Add a global shortcut:

```text
c = Controls
```

Recommended location in `_handleGlobalKey`:

```dart
case LogicalKey.keyC:
  _showDeviceControls();
  return true;
```

Implement:

```dart
Future<void> _showDeviceControls() async {
  final device = _currentSelectedDevice;

  if (device == null) {
    await showErrorDialog(...);
    return;
  }

  if (!device.isRunning) {
    await showErrorDialog(
      ...,
      message: 'Launch the simulator/emulator first.',
    );
    return;
  }

  final service = switch (device.os) {
    DeviceOs.android => _di.androidDeviceControlService,
    DeviceOs.ios => _di.iosDeviceControlService,
  };

  await showDeviceControlsDialog(
    context: context,
    device: device,
    service: service,
  );

  setState(() {
    _statusMessage = _buildIdleStatusMessage();
  });
}
```

Update status hints.

For running Android emulator:

```text
Controls: c
```

For running iOS simulator:

```text
Controls: c
```

Do not show `Controls: c` when the selected device does not support controls.

---

# 10. Potential helper components

If `device_controls_dialog.dart` becomes too large, split it later:

```text
lib/components/device_controls/
├── device_controls_dialog.dart
├── appearance_dialog.dart
├── text_size_dialog.dart
└── time_zone_dialog.dart
```

Do not split prematurely if each nested selector is only a few lines.

---

# 11. Tests

The repository already has:

```text
test/
├── models/
├── services/
├── tool/
└── utils/
```

Add service-level unit tests first.

The important rule:

**Unit tests must never execute real `adb` or `xcrun`.**

Mock/fake `CommandExec`.

---

## 11.1 Fake command executor

If one does not already exist, add:

`test/helpers/fake_command_exec.dart`

Example:

```dart
class RecordedCommand {
  const RecordedCommand(this.command, this.arguments);

  final String command;
  final List<String> arguments;
}

class FakeCommandExec implements CommandExec {
  final commands = <RecordedCommand>[];

  CommandResult result = const CommandResult(
    stdout: '',
    stderr: '',
    exitCode: 0,
  );

  @override
  Future<CommandResult> run(
    String command, {
    List<String> arguments = const [],
    String? workingDirectory,
    Duration? timeout,
  }) async {
    commands.add(
      RecordedCommand(command, List.of(arguments)),
    );
    return result;
  }
}
```

Use an existing fake if the repository already provides one.

---

## 11.2 Android unit tests

Create:

`test/services/android_device_control_service_test.dart`

Test at minimum:

### Appearance dark

Expected command:

```text
adb -s emulator-5554 shell cmd uimode night yes
```

### Appearance light

Expected:

```text
adb -s emulator-5554 shell cmd uimode night no
```

### Font normal

Expected:

```text
adb -s emulator-5554 shell settings put system font_scale 1.0
```

### Font extra large

Expected correct mapped value.

### Query font scale

Mock:

```text
stdout = "1.30\n"
```

Verify it maps to the correct semantic size.

### Query theme

Mock representative `cmd uimode night` output.

### Command failure

Return:

```dart
CommandResult(
  stdout: '',
  stderr: 'device offline',
  exitCode: 1,
)
```

Verify service returns a failure instead of throwing unexpectedly.

### Correct target device

Use two device IDs across tests and verify `-s <id>` is always included.

This protects against one of the most dangerous bugs in a multi-device tool: modifying the wrong emulator.

---

## 11.3 iOS unit tests

Create:

`test/services/ios_device_control_service_test.dart`

Test:

### Dark

Expected:

```text
xcrun simctl ui <UDID> appearance dark
```

### Light

Expected:

```text
xcrun simctl ui <UDID> appearance light
```

### Content size

Expected:

```text
xcrun simctl ui <UDID> content_size large
```

### Accessibility size

Verify the exact mapped string.

### Physical iOS device

Verify:

```text
supportsDevice == false
```

and no `xcrun simctl ui` command is executed.

### Failure

Mock non-zero exit code and verify useful failure result.

---

# 12. Dialog tests

TUI/component tests are useful, but do them after service tests.

Target behaviors:

- dialog opens for supported running device
- selected row moves with arrow keys
- Enter opens selector
- selector applies chosen value
- Escape closes nested selector
- Escape closes Device Controls
- error message displayed when command fails
- unsupported control is omitted or disabled
- status value updates after successful change

If Nocterm component testing is cumbersome, keep the UI thin and move state/action logic into testable classes.

The CLI command-generation tests are more important than snapshot-style TUI tests.

---

# 13. Manual integration test matrix

Use at least:

### Android

- one recent emulator
- one older emulator if available
- two running emulators simultaneously

### iOS

- current iOS Simulator runtime
- one older installed iOS Simulator runtime if available

Important multi-device test:

```text
Android Emulator A
Android Emulator B
```

Select B in simutil.

Change theme.

Verify only B changes.

Repeat for iOS with two booted simulators.

---

# 14. Manual Android verification

Before running simutil, verify commands manually:

```bash
adb devices
```

Theme:

```bash
adb -s emulator-5554 shell cmd uimode night yes
adb -s emulator-5554 shell cmd uimode night no
```

Font:

```bash
adb -s emulator-5554 shell settings get system font_scale
adb -s emulator-5554 shell settings put system font_scale 1.30
adb -s emulator-5554 shell settings put system font_scale 1.0
```

Time zone:

```bash
adb -s emulator-5554 shell getprop persist.sys.timezone
```

Then set an IANA time zone and verify the selected emulator changes.

---

# 15. Manual iOS verification

List:

```bash
xcrun simctl list devices
```

Theme:

```bash
xcrun simctl ui <UDID> appearance
xcrun simctl ui <UDID> appearance dark
xcrun simctl ui <UDID> appearance light
```

Dynamic Type:

```bash
xcrun simctl ui <UDID> content_size
xcrun simctl ui <UDID> content_size large
xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large
```

Inspect supported values on your installed Xcode:

```bash
xcrun simctl ui help
```

Do this before locking the enum-to-string mapping.

---

# 16. Automated repository checks

Run before every commit:

```bash
dart format .
```

```bash
dart analyze
```

```bash
dart test
```

If the repo uses code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Only run build generation when your changes touch generated models/config.

---

# 17. Recommended implementation order

## Phase 1 — architecture

Add:

```text
lib/models/device_appearance.dart
lib/models/device_text_size.dart
lib/models/device_control_state.dart
lib/services/device_control_service.dart
```

No UI yet.

Commit:

```bash
git add .
git commit -m "feat: add device control abstractions"
```

---

## Phase 2 — Android service

Add:

```text
lib/services/android_device_control_service.dart
test/services/android_device_control_service_test.dart
```

Register service in:

```text
lib/services/service_locator.dart
```

Commit:

```bash
git add .
git commit -m "feat(android): add emulator device controls"
```

---

## Phase 3 — iOS service

Add:

```text
lib/services/ios_device_control_service.dart
test/services/ios_device_control_service_test.dart
```

Update:

```text
lib/services/service_locator.dart
```

Commit:

```bash
git add .
git commit -m "feat(ios): add simulator appearance and text controls"
```

---

## Phase 4 — Nocterm UI

Add:

```text
lib/components/device_controls_dialog.dart
```

Modify:

```text
lib/simutil_app.dart
```

Add:

```text
c = Controls
```

Commit:

```bash
git add .
git commit -m "feat(tui): add device controls dialog"
```

---

## Phase 5 — documentation

Add this document as:

```text
docs/device-controls.md
```

Update `README.md` with a small section:

```markdown
### Device Controls

For a running emulator/simulator, press `c` to open Device Controls.

Supported controls include:

- Light / Dark appearance
- Font / Dynamic Type size
- Android emulator time zone

See [Device Controls](docs/device-controls.md).
```

Commit:

```bash
git add README.md docs/device-controls.md
git commit -m "docs: document device controls"
```

---

# 18. Files changed in v1

## New

```text
lib/models/device_appearance.dart
lib/models/device_text_size.dart
lib/models/device_control_state.dart

lib/services/device_control_service.dart
lib/services/android_device_control_service.dart
lib/services/ios_device_control_service.dart

lib/components/device_controls_dialog.dart

test/services/android_device_control_service_test.dart
test/services/ios_device_control_service_test.dart

docs/device-controls.md
```

Potential:

```text
test/helpers/fake_command_exec.dart
```

Only add this if the repo does not already have a reusable command-executor fake.

## Modified

```text
lib/services/service_locator.dart
lib/simutil_app.dart
README.md
```

Avoid changing:

```text
lib/services/device_service.dart
```

unless you later find a control operation that genuinely belongs to every device lifecycle implementation.

---

# 19. Recommended v1 behavior

```text
Selected device             Controls
────────────────────────────────────────────────
Android physical device     Theme/font where ADB supports it
Android emulator            Theme/font/time zone
iOS physical device         Disabled
iOS Simulator shutdown      Disabled; tell user to launch it
iOS Simulator booted        Theme/Dynamic Type
```

---

# 20. Error handling

Do not let raw shell errors crash the TUI.

Every control operation should handle:

- executable missing
- device offline
- device shutdown
- unsupported Android version
- unsupported Xcode/simctl option
- command timeout
- non-zero exit code

Display concise UI errors:

```text
Unable to change appearance.
device offline
```

or:

```text
This Simulator runtime does not support this text-size command.
```

Log the full command/error for debugging if the existing logging approach supports it.

---

# 21. Future features after v1

Once the architecture is stable, add controls one at a time:

- Android display density
- Android display resolution
- animation scale
- orientation
- stay awake
- permissions
- location
- iOS Increase Contrast
- iOS status bar override
- permissions
- open deep link
- app terminate/relaunch
- app-specific language/locale
- screenshot
- push notification
- preset profiles

Possible preset model:

```text
Default
Dark Mode
Large Text
Accessibility
Japanese
Dark + Accessibility
```

A preset should call the same `DeviceControlService`; do not implement another shell-command layer.

---

# 22. Optional phase 2 architecture

When there are many controls, evolve:

```text
DeviceControlService
```

into capabilities:

```dart
enum DeviceControlCapability {
  appearance,
  textSize,
  timeZone,
  contrast,
  density,
  orientation,
}
```

Then:

```dart
Set<DeviceControlCapability> capabilities(Device device);
```

The dialog can build itself dynamically from platform capabilities.

This is preferable to accumulating many `if (android)` / `if (ios)` conditions in the UI.

Do not introduce this complexity for the first three controls unless you need it immediately.

---

# 23. Pull request workflow

Push your feature branch:

```bash
git push -u origin feat/device-controls
```

Then open a PR against your fork's `main`.

Suggested title:

```text
feat: add emulator and simulator device controls
```

Suggested PR description:

```markdown
## Summary

Adds Device Controls for running Android emulators/devices and iOS Simulators.

## Features

- Change Light/Dark appearance
- Change Android font scale
- Change iOS Dynamic Type size
- Android time-zone support
- Device-specific command targeting
- Keyboard-driven Device Controls dialog

## Architecture

Introduces platform-specific device-control services while keeping device discovery/lifecycle services unchanged.

## Tests

- Android command generation
- iOS simctl command generation
- device targeting
- unsupported-device handling
- command failure handling

## Verification

- `dart format .`
- `dart analyze`
- `dart test`
- manually verified with Android Emulator
- manually verified with iOS Simulator
```

---

# 24. Keeping your fork synchronized

Before beginning another feature:

```bash
git checkout main
git fetch upstream
git rebase upstream/main
git push origin main
```

Then:

```bash
git checkout -b feat/<next-feature>
```

If you want your fork to stay close enough to contribute changes upstream later, avoid unnecessary refactors in the same PR as Device Controls.

Keep the first PR focused.

---

# 25. Definition of done

v1 is done when all of these pass:

- [ ] User can select a running Android emulator and press `c`
- [ ] User can switch Android Light/Dark mode
- [ ] User can change Android font size
- [ ] User can change the selected Android device time zone
- [ ] Commands always target the selected Android serial
- [ ] User can select a running iOS Simulator and press `c`
- [ ] User can switch iOS Light/Dark appearance
- [ ] User can change iOS Dynamic Type size
- [ ] Commands always target the selected Simulator UDID
- [ ] iOS physical devices do not expose unsupported Simulator controls
- [ ] Shutdown simulators/emulators do not silently boot
- [ ] Shell failures are shown without crashing the TUI
- [ ] Unit tests cover generated commands
- [ ] `dart analyze` passes
- [ ] `dart test` passes
- [ ] `dart format .` produces no additional changes
- [ ] README includes the Device Controls shortcut
- [ ] `docs/device-controls.md` is committed
