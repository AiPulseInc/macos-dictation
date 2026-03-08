from pathlib import Path
from tempfile import NamedTemporaryFile
import os
import shutil
from threading import Lock
from typing import Dict, Optional, Union

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from faster_whisper import WhisperModel


app = FastAPI(title="QuickDictate ASR")

# Default to a CPU-friendly local model. Override with WHISPER_MODEL if needed.
MODEL_SIZE = os.getenv("WHISPER_MODEL", "base")
MODEL_DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
MODEL_COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")

_model: Optional[WhisperModel] = None
_model_lock = Lock()


def get_model() -> WhisperModel:
    global _model

    if _model is not None:
        return _model

    with _model_lock:
        if _model is None:
            _model = WhisperModel(
                MODEL_SIZE,
                device=MODEL_DEVICE,
                compute_type=MODEL_COMPUTE_TYPE,
            )
    return _model


@app.get("/health")
def health() -> Dict[str, Union[str, bool]]:
    return {
        "status": "ok",
        "model": MODEL_SIZE,
        "device": MODEL_DEVICE,
        "compute_type": MODEL_COMPUTE_TYPE,
        "model_loaded": _model is not None,
    }


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    language: str = Form("auto"),
) -> Dict[str, Union[str, float, None]]:
    allowed_languages = {"auto", "pl", "en"}
    if language not in allowed_languages:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language '{language}'. Use one of: auto, pl, en",
        )

    suffix = Path(audio.filename or "audio.wav").suffix or ".wav"
    temp_path: Optional[str] = None

    try:
        with NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            shutil.copyfileobj(audio.file, tmp)
            temp_path = tmp.name

        fw_language = None if language == "auto" else language
        model = get_model()
        segments, info = model.transcribe(
            temp_path,
            language=fw_language,
            vad_filter=True,
        )
        text = " ".join(segment.text.strip() for segment in segments).strip()

        return {
            "text": text,
            "detected_language": info.language,
            "language_probability": info.language_probability,
            "requested_language": language,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        await audio.close()
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass
