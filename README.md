# Dictation macOS App

This workspace now has two parts:

- `quickdictate-asr/`: the local FastAPI + `faster-whisper` transcription service
- `QuickDictateMac`: a native macOS app with a global keyboard shortcut for recording

## 1. Start the local ASR service

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --host 127.0.0.1 --port 8765
```

The first transcription request downloads the selected Whisper model.

## 2. Run the macOS app

In a second terminal:

```bash
cd /Users/mk/code-sandbox/dictation-macos-app
swift run
```

## 3. Use dictation

- Press `Control + B` to start recording
- Press `Control + B` again to stop and transcribe
- The transcript is pasted into the previously active app automatically
- If auto-paste cannot run, the transcript falls back to the clipboard
- The app window shows a clear live recording state, the selected Whisper model, and transcript cleanup controls

## Notes

- The macOS app expects the ASR service at `http://127.0.0.1:8765/transcribe`
- If microphone access is blocked, allow it in System Settings and relaunch the app
- If auto-paste is blocked, allow Accessibility access for `QuickDictateMac` in System Settings and relaunch the app
- You can switch between `base`, `small`, and `medium` Whisper models inside the app UI
- `Refine transcript` is a lightweight local cleanup pass for punctuation and obvious formatting issues, not a full context-aware rewrite
