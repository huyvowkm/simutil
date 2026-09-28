<p align="center">
  <img src="art/simutil.png" alt="SimUtil" width="200" />
</p>
<h1 align="center">SimUtil</h1>

<p align="center">
  <strong>A terminal UI for launching Android Emulators / iOS Simulators</strong><br>
  <strong>Launch, connect, manage your devices and more — all from the terminal</strong>
</p>

<p align="center">
  <a href="https://www.producthunt.com/products/simutil?embed=true&amp;utm_source=badge-featured&amp;utm_medium=badge&amp;utm_campaign=badge-simutil" target="_blank" rel="noopener noreferrer"><img alt="SimUtil - Terminal UI for iOS Simulators and Android Emulators | Product Hunt" width="250" height="54" src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1111003&amp;theme=light&amp;t=1774974338508"></a>
</p>
<p align="center">
  <img src="https://img.shields.io/github/stars/huyvowkm/simutil" alt="GitHub Repo stars" />
  <a href="https://github.com/huyvowkm/simutil/actions/workflows/ci.yaml"><img src="https://github.com/huyvowkm/simutil/actions/workflows/ci.yaml/badge.svg" alt="Build" /></a>
  <a href="https://github.com/huyvowkm/simutil/releases/latest"><img src="https://img.shields.io/github/v/release/huyvowkm/simutil" alt="GitHub release" /></a>
</p>

Browse your available emulators and simulators side-by-side, launch with custom options and connect to physical devices wirelessly.

SimUtil runs on macOS, Linux, and Windows. **iOS Simulator support requires macOS** (Xcode / `simctl`); on Linux and Windows the TUI focuses on Android emulators and devices.

Simutil is written with [Nocterm](https://nocterm.dev/), a terminal UI framework for Dart with similar syntax to Flutter.

<p align="center">
  <img src="art/showcase-simutil.gif" height="100%" width="100%" alt="Simutil Showcase" />
</p>

<p align="center">
  <img src="art/showcase.png" alt="Simutil Showcase Image" />
</p>

## Features

- **One-Key Launch** — Start any device with `Enter`, no need to open Android Studio or Xcode
- **Android Launch Options** — Provide launch option for Android Emulators: Normal, Cold Boot, No Audio, or Cold Boot + No Audio,...
- **Shutdown device** — Shutdown simulators/emulators.
- **Logcat** — View logcat output of Android emulators / devices, support filtering.
- **ADB Tools Built-in** — Connect to physical Android devices wirelessly:
  - Connect via IP address
  - Pair with 6-digit code (Android 11+)
  - QR code pairing (Android 11+)
- **Custom Plugins** — Add your own external tools (scrcpy, Maestro, etc.) via a YAML file, no code changes needed. Press `p` to pick a plugin and a command to run on the selected device.
- **Edit Config** — Press `e` to open `~/.simutil/settings.yaml` in your default editor (macOS, Linux, Windows).
- **Xcode Tools** — Press `x` (macOS) to clear Xcode Derived Data after a size preview and confirmation.

## Device Controls

SimUtil includes a control center for mobile emulators and simulators. The screen
always shows **Details** in the top third and **Controls** in the bottom two
thirds for the selected device. Press `Tab` to move focus to Controls; there is
no shortcut to open a dialog. Controls work only with a running emulator,
simulator, or Android device. They do not boot devices and are not available for
physical iOS devices.

### Configure the device for testing

| Feature | Android emulator | Android physical device | iOS Simulator | Physical iOS device |
| --- | --- | --- | --- | --- |
| Light / dark appearance | Supported | Supported when ADB allows it | Supported | Not supported |
| Font / text size | Supported | Supported when ADB allows it | Supported (Dynamic Type) | Not supported |
| System time zone | Supported | Supported when ADB allows it | Not supported yet | Not supported |
| Network (Wi-Fi / mobile data) | Supported | Supported when ADB allows it | Not supported yet | Not supported |
| Navigation mode (gesture / 2-button / 3-button) | Supported | Supported when Android allows it | Not applicable | Not supported |
| System language | Supported; requires `adb root` and restarts Android | Not supported yet | Not supported yet | Not supported |
| Read current value | When the command supports it | When the command supports it | When `simctl` supports it | Not supported |
| Clear command error reporting | Supported | Supported | Supported | Not supported |

The interface is designed to be fully keyboard-driven:

```text
┌ Controls: Pixel 9 ─────────────────────────┐
│ Appearance                          Dark    │
│ Text Size                       Extra Large │
│ Time Zone             Asia/Ho_Chi_Minh     │
│ Network                              Both  │
│ Navigation                       Gesture  │
│ Language                    Vietnamese     │
└────────────────────────────────────────────┘
```

Text size presets are Small, Normal, Large, Extra Large, Accessibility Large,
and Accessibility Extra Large. The displayed values are platform-neutral;
Android maps them to `font_scale`, while iOS maps them to `simctl content_size`.
Navigation modes are Gesture, 2-button, and 3-button. Android emulators can
change the system language to English (US), Vietnamese, Japanese, Simplified
Chinese, Korean, French, or Spanish.

### Behavior and technical limits

- Every Android command includes `adb -s <serial>` so it affects only the
  selected device, even when multiple emulators are running.
- Every iOS command targets the specific Simulator UDID through `xcrun simctl`.
- Existing services continue to manage device discovery, launch, and shutdown.
  Device Controls has its own service layer and does not add control logic to
  `DeviceService`.
- Commands run through `CommandExec` and `IsolateRunner`, keeping the Nocterm UI
  responsive. Services are unit-tested with a fake command executor.
- Android time zones use a common set of IANA time zones and affect only the
  selected device. Changing the iOS system time zone is outside v1.
- Android navigation modes enable the corresponding SystemUI overlay. The mode
  cannot be changed on Android versions or OEM builds without that overlay.
- Changing the system language uses a BCP-47 locale on Android emulators and
  restarts the Android framework. SimUtil switches ADB to root before changing
  the locale. Android images that do not allow `adb root`, physical Android
  devices, and iOS simulators do not support this feature.
- If an Xcode/runtime or Android version does not support a command, the app
  should show a concise error instead of crashing.

### Roadmap after v1

- Orientation, display density/resolution, animation scale, and stay-awake.
- Permissions, location, screenshots, deep links, status-bar overrides, and push
  notification testing.
- App Controls: select a package/bundle ID, terminate/relaunch the app, clear
  app data, and set an app-specific language/locale.
- Presets such as `Dark Mode`, `Large Text`, `Japanese`, or
  `Dark + Accessibility`.
- Destructive actions such as erase/wipe will be handled in a separate PR, show
  the target clearly, and always require confirmation.

### Implementation approach

1. Models represent appearance, text size, control state, and results.
2. `DeviceControlService`, its Android/iOS implementations, and `CommandExec`
   run commands outside the UI isolate.
3. Services are registered in `ServiceLocator`; widgets do not create services.
4. `SimutilApp` includes an inline `DeviceControlsPanel`, focused with `Tab`.
5. Unit tests cover command generation, failure handling, and targeting when
   multiple devices are running.

Technical details and the implementation checklist are in the
[Device Controls implementation plan](docs/device-controls-plan.md).

## Custom Plugins

SimUtil can run external shell-command tools (scrcpy, Maestro, custom scripts, …)
defined in the `plugins:` section of `~/.simutil/settings.yaml` — no code changes
needed. A default file (with `theme`, `last_selected_device_id`, and `scrcpy`) is
created automatically on first launch.

Each plugin groups one or more **commands**. In the app, press `p` on a selected
device to choose a plugin, then a command. Press `e` to edit the config file.
A command can also define a single-key `shortcut` to run it directly. Commands are
filtered to the selected device, and `args` support template variables like
`{device.id}` and `{device.name}`.

```yaml
# ~/.simutil/settings.yaml
theme: dark
last_selected_device_id: ~

plugins:
  - id: scrcpy
    label: scrcpy
    description: Screen mirroring and control for Android
    availability:
      command: scrcpy
      args: [--version]
    commands:
      - id: mirror
        label: Screen Mirror
        command: scrcpy
        args: [-s, "{device.id}"]
        platforms: [android]   # android | ios; empty = any
        requires_running: true # only show when the device is running
        mode: detached         # detached (default) | inherit
        shortcut: s            # optional single key to run directly
```

See the full reference — all fields, template variables, run modes, availability
probes, shortcuts, examples, and troubleshooting — in
**[docs/plugins.md](docs/plugins.md)**.

## Installation

The installation source determines which `simutil` you run. The Homebrew and
pub.dev packages are upstream releases; use the Git installation below to run
this fork (`huyvowkm/simutil`) and its device-control features.

### Upstream owner releases

#### Binary install

```bash
curl -fsSL https://raw.githubusercontent.com/dungngminh/simutil/main/install.sh | bash
```

#### Binary install (Windows PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/dungngminh/simutil/main/install.ps1 | iex"
```

#### Homebrew (macOS/Linux)

```bash
brew tap dungngminh/simutil
brew install simutil
```

#### pub.dev

```bash
dart pub global activate simutil
```

### This fork from GitHub

This option requires the Dart SDK and does not require cloning the repository:

```bash
dart pub global activate --source git \
  https://github.com/huyvowkm/simutil.git \
  --git-ref main
```

For an SSH Git remote, use:

```bash
dart pub global activate --source git \
  git@github.com:huyvowkm/simutil.git \
  --git-ref main
```

Verify the selected executable and version:

```bash
command -v simutil
simutil version
```

### Switch from Homebrew to this fork

If Homebrew's `simutil` is earlier in your `PATH`, it can hide the Dart global
executable. Unlink it (reversible; it does not uninstall the formula), activate
this fork, and refresh your shell command cache:

```bash
brew unlink simutil
dart pub global activate --source git \
  git@github.com:huyvowkm/simutil.git \
  --git-ref main
rehash
simutil version
```

To return to the Homebrew package later:

```bash
brew link simutil
```

On the author's machine, the same refresh command is available as:

```bash
run reset-stl
```

### From a local source checkout

```bash
git clone https://github.com/huyvowkm/simutil.git
cd simutil
dart pub get
dart pub global activate --source path .
```

Then run:

```bash
simutil
```

### Update the Git installation

Git-based global packages are snapshots. Run the activation command again after
new commits are pushed to `main`, or use `run reset-stl` when it is configured.

## Maintaining this fork

Make feature work on a branch, verify it, fast-forward it into `main`, then
push the result:

```bash
git checkout main
git pull --ff-only origin main
git merge --ff-only feat/your-feature
git push origin main
```

After pushing, refresh the globally installed fork:

```bash
dart pub global activate --source git \
  git@github.com:huyvowkm/simutil.git \
  --git-ref main
```

## Supported platforms

SimUtil itself runs on macOS, Linux, and Windows. Feature support depends on the host OS:

| Host OS | Android emulators & devices | iOS simulators & devices |
| ------- | --------------------------- | ------------------------ |
| macOS   | Yes                         | Yes (requires Xcode)     |
| Linux   | Yes                         | No                       |
| Windows | Yes                         | No                       |

iOS support depends on Apple’s tools (`xcrun simctl` for simulators, `xcrun devicectl` for physical devices), which are only available on macOS. On Xcode 27+, launching a simulator opens DeviceHub.app; earlier Xcode versions still open Simulator.app. On Linux and Windows, the iOS panels indicate they are not supported; Android launch, ADB tools, Logcat, and plugins still work.

## Contributing

```bash
git clone https://github.com/huyvowkm/simutil.git
cd simutil
dart pub get
dart run bin/simutil.dart   # Run locally

dart --enable-vm-service bin/simutil.dart # Run with hot reload
```

1. Fork this repository
2. Create a branch and make your changes
3. Open a Pull Request

## License

MIT — see [LICENSE](LICENSE)
