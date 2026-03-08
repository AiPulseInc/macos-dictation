# Architecture

## Components

### macOS app

Path: `/Users/mk/code-sandbox/dictation-macos-app/Sources/QuickDictateMac`

Responsibilities:

- register the global shortcut
- record local microphone audio
- show app state and recording overlay
- start the bundled backend automatically in standalone `.app` mode
- send multipart audio requests to the local ASR service
- paste the returned transcript back into the previously focused app

Main files:

- `DictationController.swift`: orchestration and state
- `BackendServiceManager.swift`: bundled backend lifecycle for the standalone app
- `AudioRecorder.swift`: `AVAudioRecorder` wrapper
- `GlobalHotKey.swift`: Carbon hotkey handling
- `TranscriptionClient.swift`: multipart request client
- `TextInsertionService.swift`: Accessibility-assisted paste-back
- `RecordingOverlayController.swift`: floating recording/transcribing overlay

### Local ASR service

Path: `/Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr`

Responsibilities:

- accept uploaded audio
- run local `faster-whisper` transcription
- support per-request language and model selection
- apply optional lightweight text cleanup

Main file:

- `app.py`

### Standalone app bundle

Path: `/Users/mk/code-sandbox/dictation-macos-app/dist/QuickDictateMac.app`

Contains:

- native macOS executable
- bundled `quickdictate-asr`
- bundled Python virtualenv for the backend
- generated `AppIcon.icns`

## Request Flow

1. User presses `Control + B`
2. macOS app starts recording and remembers the previously active app
3. User presses `Control + B` again
4. If needed, the standalone app starts the bundled backend and waits for `/health`
5. macOS app uploads audio to `POST /transcribe`
6. ASR service runs the selected Whisper model locally
7. Optional cleanup runs on the decoded text
8. macOS app pastes the transcript back into the previously focused app
9. If paste fails, transcript is copied to the clipboard instead

## Improve Transcript Behavior

`Improve Transcript` in the UI maps to `refine_text=true` in the backend request.

What happens:

1. The selected Whisper model (`base`, `small`, or `medium`) performs the actual speech-to-text decoding.
2. After decoding, `cleanup_transcript()` in `quickdictate-asr/app.py` runs a small local cleanup pass.

Current cleanup scope:

- collapse repeated whitespace
- clean spacing around punctuation
- add a terminal punctuation mark when missing
- capitalize the first letter
- normalize English standalone `i` to `I`

What does **not** happen right now:

- no second LLM or API model is called
- no semantic rewrite based on wider document context
- no grammar engine beyond the small local cleanup function

So the quality gain from `Improve Transcript` is modest. The main accuracy lever is still the selected Whisper model, especially moving from `base` to `small` or `medium`.
