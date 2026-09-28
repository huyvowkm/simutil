# Simutil v0.8.3 Controls

- Status: complete
- Plan: approved in chat; no separate plan file
- Ledger: [lead_on_progress.md](lead_on_progress.md)
- Current step: complete
- Completed: moved the multi-agent setup plan to `/Users/huyvo/.codex`; added Android navigation modes and Android-emulator language selection; updated release metadata and README.
- Changed files: `CHANGELOG.md`, `README.md`, `pubspec.yaml`, `lib/components/device_controls_dialog.dart`, `lib/models/device_control_state.dart`, `lib/models/device_language.dart`, `lib/models/device_navigation_mode.dart`, `lib/services/android_device_control_service.dart`, `lib/services/device_control_service.dart`, `lib/services/ios_device_control_service.dart`, generated `lib/utils/version.dart`.
- Checks: `dart format` passed; `dart run build_runner build` passed; `dart analyze --fatal-infos` passed; `git diff --check` passed. Tests were not run.
- Decisions: system language changes target Android emulators only; the Android framework restarts; language options are English (US), Vietnamese, Japanese, Chinese (Simplified), Korean, French, and Spanish.
- Next action: none.
