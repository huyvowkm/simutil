# Simutil v0.8.3 Controls

- Status: complete
- Plan: approved in chat; no separate plan file
- Ledger: [lead_on_progress.md](lead_on_progress.md)
- Current step: complete after pushing the emulator fixes.
- Completed: moved the multi-agent setup plan to `/Users/huyvo/.codex`; added Android navigation modes and Android-emulator language selection; corrected navigation changes to switch the active SystemUI overlay and language changes to request ADB root and wait for reconnection; updated v0.8.3 docs; refreshed the global Pub install.
- Changed files: `CHANGELOG.md`, `README.md`, `pubspec.yaml`, `.codex/tasks/simutil-controls-v0-8-3/`, `lib/components/device_controls_dialog.dart`, `lib/models/device_control_state.dart`, `lib/models/device_language.dart`, `lib/models/device_navigation_mode.dart`, `lib/services/android_device_control_service.dart`, `lib/services/device_control_service.dart`, `lib/services/ios_device_control_service.dart`, generated `lib/utils/version.dart`.
- Checks: `dart format`, `dart run build_runner build`, `dart analyze --fatal-infos`, and `git diff --check` passed. Tests were not run; emulator behavior was not verified from this sandbox because ADB could not start its local daemon.
- Decisions: system language changes target Android emulators only; Android restarts its framework; language options are English (US), Vietnamese, Japanese, Chinese (Simplified), Korean, French, and Spanish. Language changes require an emulator image that permits `adb root`; navigation changes use AOSP SystemUI overlays.
- Next action: none.
