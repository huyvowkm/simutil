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

SimUtil có thêm mobile emulator/simulator control center. Màn hình phải luôn
hiển thị **Details** ở 1/3 phía trên và **Controls** ở 2/3 phía dưới cho device
đang chọn. Dùng `Tab` để chuyển focus sang Controls; không cần mở dialog bằng
shortcut. Controls chỉ hoạt động với emulator/simulator hoặc Android device
đang chạy; không tự boot device và không áp dụng cho iOS physical device.

### Thiết lập giao diện để kiểm thử

| Tính năng | Android emulator | Android physical device | iOS Simulator | iOS physical device |
| --- | --- | --- | --- | --- |
| Light / Dark appearance | Có | Có nếu ADB hỗ trợ | Có | Không hỗ trợ |
| Font / text size | Có | Có nếu ADB hỗ trợ | Có (Dynamic Type) | Không hỗ trợ |
| System time zone | Có | Có nếu ADB hỗ trợ | Chưa hỗ trợ | Không hỗ trợ |
| Network (Wi-Fi / mobile data) | Có | Có nếu ADB hỗ trợ | Chưa hỗ trợ | Không hỗ trợ |
| Đọc giá trị hiện tại | Khi command hỗ trợ | Khi command hỗ trợ | Khi `simctl` hỗ trợ | Không hỗ trợ |
| Báo lỗi command rõ ràng | Có | Có | Có | Không hỗ trợ |

Giao diện dự kiến vẫn hoàn toàn điều khiển bằng bàn phím:

```text
┌ Controls: Pixel 9 ─────────────────────────┐
│ Appearance                          Dark    │
│ Text Size                       Extra Large │
│ Time Zone             Asia/Ho_Chi_Minh     │
│ Network                              Both  │
│                                            │
│ ↑/↓ Navigate  ←/→ Choose  Enter Apply      │
└────────────────────────────────────────────┘
```

Các preset text size gồm Small, Normal, Large, Extra Large, Accessibility Large
và Accessibility Extra Large. Giá trị hiển thị là platform-neutral; Android
chuyển chúng thành `font_scale`, còn iOS chuyển thành `simctl content_size`.

### Hành vi và giới hạn kỹ thuật

- Mỗi Android command luôn có `adb -s <serial>` để chỉ thay đổi device đang
  chọn, kể cả khi nhiều emulator cùng chạy.
- iOS command luôn có đúng Simulator UDID qua `xcrun simctl`.
- Device lifecycle (discovery, launch, shutdown) vẫn do các service hiện có
  quản lý. Device Controls là lớp service riêng, không làm phình `DeviceService`.
- Mọi command chạy qua `CommandExec` và `IsolateRunner`; UI Nocterm không bị
  block và service được unit-test bằng fake command executor.
- Android time zone dùng danh sách timezone IANA phổ biến và chỉ thay đổi
  device đang chọn. iOS system time zone chưa thuộc v1.
- Nếu Xcode/runtime hoặc Android version không hỗ trợ một command, app phải
  hiển thị lỗi ngắn gọn thay vì crash.

### Roadmap sau v1

- Orientation, display density/resolution, animation scale và stay-awake.
- Permissions, location, screenshot, deep link, status-bar override và push
  notification testing.
- App Controls: chọn package/bundle ID, terminate/relaunch, clear app data và
  app-specific language/locale.
- Presets như `Dark Mode`, `Large Text`, `Japanese` hoặc `Dark + Accessibility`.
- Các action phá huỷ như erase/wipe sẽ ở PR riêng, hiển thị target rõ ràng và
  luôn yêu cầu confirmation.

### Cách triển khai

1. Models biểu diễn appearance, text size, trạng thái và kết quả control.
2. `DeviceControlService`, Android/iOS implementations và `CommandExec` hiện
   có để chạy commands ngoài UI isolate.
3. Service registration tại `ServiceLocator`; widget không tự khởi tạo service.
4. Inline `DeviceControlsPanel` tại `SimutilApp`, focus bằng `Tab`.
5. Unit tests kiểm tra command generation, failure handling và target khi có
   nhiều device cùng chạy.

Chi tiết kỹ thuật và checklist triển khai nằm trong
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

### Binary Install

```bash
curl -fsSL https://raw.githubusercontent.com/dungngminh/simutil/main/install.sh | bash
```

### Binary Install (Windows PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/dungngminh/simutil/main/install.ps1 | iex"
```

### Using Homebrew (macOS/Linux)

```bash
brew tap dungngminh/simutil
brew install simutil
```

### From pub.dev

```bash
dart pub global activate simutil
```

### From source

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

## Supported platforms

SimUtil itself runs on macOS, Linux, and Windows. Feature support depends on the host OS:

| Host OS | Android emulators & devices | iOS simulators & devices |
| ------- | --------------------------- | ------------------------ |
| macOS   | Yes                         | Yes (requires Xcode)     |
| Linux   | Yes                         | No                       |
| Windows | Yes                         | No                       |

iOS support depends on Apple’s tools (`xcrun simctl` for simulators, `xcrun devicectl` for physical devices), which are only available on macOS. On Linux and Windows, the iOS panels indicate they are not supported; Android launch, ADB tools, Logcat, and plugins still work.

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
