# AGENTS.md

## Purpose

Hot-start guide for returning to this repository quickly.

This project has two runtime pieces:

- `quickdictate-asr/`: local FastAPI transcription service using `faster-whisper`
- `Sources/QuickDictateMac/`: native macOS SwiftUI app with global hotkey recording and auto-paste

## Fast Start

### Start the backend

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
source .venv/bin/activate
uvicorn app:app --host 127.0.0.1 --port 8765
```

### Start the macOS app

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
swift run
```

### Primary shortcut

- `Control + B`: start/stop recording

## Key Files

- `/Users/mk/code-sandbox/dictation-macos-app/README.md`
  Main project overview and quickstart.
- `/Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr/app.py`
  FastAPI API, model selection, transcript refinement.
- `/Users/mk/code-sandbox/dictation-macos-app/Sources/QuickDictateMac/DictationController.swift`
  Main app state and recording/transcription flow.
- `/Users/mk/code-sandbox/dictation-macos-app/Sources/QuickDictateMac/TextInsertionService.swift`
  Paste-back into the previously focused app.
- `/Users/mk/code-sandbox/dictation-macos-app/Sources/QuickDictateMac/RecordingOverlayController.swift`
  Floating on-screen recording/transcribing overlay.
- `/Users/mk/code-sandbox/dictation-macos-app/Sources/QuickDictateMac/GlobalHotKey.swift`
  Carbon global hotkey registration.

## Runtime Notes

- The backend defaults to local CPU inference.
- Available Whisper models in the app/backend: `base`, `small`, `medium`.
- `Improve Transcript` / `Refine transcript` does not call a second AI model.
  It uses the selected Whisper model first, then runs a small local text cleanup pass in `cleanup_transcript()` inside `quickdictate-asr/app.py`.
- Auto-paste requires Accessibility permission for `QuickDictateMac`.
- Microphone capture requires Microphone permission for `QuickDictateMac`.

## Verification

### Backend smoke test

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
source quickdictate-asr/.venv/bin/activate
HF_HOME=/Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr/.cache/huggingface python quickdictate-asr/smoke_test.py
```

### macOS app build

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
CLANG_MODULE_CACHE_PATH=/Users/mk/code-sandbox/dictation-macos-app/.build/ModuleCache \
SWIFTPM_MODULECACHE_OVERRIDE=/Users/mk/code-sandbox/dictation-macos-app/.build/ModuleCache \
swift build
```

## Current UX Behavior

- Red circular floating overlay while recording
- Yellow circular floating overlay while transcribing
- Overlay disappears after paste/copy completes
- Transcript is auto-pasted into the previously focused app when possible
- Fallback is clipboard copy

## Common Follow-Up Tasks

- Tune overlay placement/size in `RecordingOverlayController.swift`
- Add more aggressive post-processing to `cleanup_transcript()` in `quickdictate-asr/app.py`
- Add a true second-pass correction model if lightweight cleanup is not enough
