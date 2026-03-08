# Testing

## Backend

### Start service

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
source .venv/bin/activate
uvicorn app:app --host 127.0.0.1 --port 8765
```

### Smoke test

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
source quickdictate-asr/.venv/bin/activate
HF_HOME=/Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr/.cache/huggingface python quickdictate-asr/smoke_test.py
```

### Manual API check

```bash
curl -X POST "http://127.0.0.1:8765/transcribe" \
  -F "audio=@sample.wav" \
  -F "language=auto" \
  -F "model=small" \
  -F "refine_text=true"
```

## macOS app

### Build

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
CLANG_MODULE_CACHE_PATH=/Users/mk/code-sandbox/dictation-macos-app/.build/ModuleCache \
SWIFTPM_MODULECACHE_OVERRIDE=/Users/mk/code-sandbox/dictation-macos-app/.build/ModuleCache \
swift build
```

### Run

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
swift run
```

### Build standalone app bundle

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
zsh scripts/build_app_bundle.sh
```

### Launch standalone app bundle

```bash
open /Users/mk/code-sandbox/dictation-macos-app/dist/QuickDictateMac.app
```

## Manual Acceptance Checklist

- App window opens
- Global hotkey `Control + B` starts recording
- Red floating overlay appears while recording
- The same red overlay stays visible during transcription and changes text to `Transcribing`
- Overlay disappears after paste/copy completes
- Transcript reaches the target text field
- `base`, `small`, and `medium` model selection works
- `Improve Transcript` toggle changes output formatting behavior
- Standalone `.app` launches the bundled backend without a terminal
