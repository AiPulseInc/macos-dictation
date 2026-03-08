# QuickDictate ASR

Local transcription service for Milestone 1.

## Setup

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The first transcription request downloads the selected Whisper model.

## Run

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
source .venv/bin/activate
uvicorn app:app --reload --host 127.0.0.1 --port 8765
```

Optional model tuning:

```bash
export WHISPER_MODEL=small
export WHISPER_DEVICE=cpu
export WHISPER_COMPUTE_TYPE=int8
```

## Endpoints

- `GET /health`
- `POST /transcribe`

`POST /transcribe` expects:

- multipart field `audio`
- multipart field `language` with `auto`, `pl`, or `en`
- multipart field `model` with `base`, `small`, or `medium`
- multipart field `refine_text` with `true` or `false`

Example:

```bash
curl -X POST "http://127.0.0.1:8765/transcribe" \
  -F "audio=@sample.wav" \
  -F "language=auto" \
  -F "model=small" \
  -F "refine_text=true"
```

## Smoke Test

On macOS, you can run an in-process check against built-in system speech samples:

```bash
cd /Users/mk/code-sandbox/dictation-macos-app/quickdictate-asr
source .venv/bin/activate
HF_HOME=.cache/huggingface python smoke_test.py
```
