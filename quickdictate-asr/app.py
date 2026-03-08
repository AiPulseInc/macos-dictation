from pathlib import Path
from tempfile import NamedTemporaryFile
import os
import re
import shutil
from threading import Lock
from typing import Dict, List, Optional, Union

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from faster_whisper import WhisperModel


app = FastAPI(title="QuickDictate ASR")

# Default to a CPU-friendly local model. Override with WHISPER_MODEL if needed.
MODEL_SIZE = os.getenv("WHISPER_MODEL", "base")
MODEL_DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
MODEL_COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
AVAILABLE_MODELS = ("base", "small", "medium")

_models: Dict[str, WhisperModel] = {}
_model_lock = Lock()


def get_model(model_name: str) -> WhisperModel:
    if model_name in _models:
        return _models[model_name]

    with _model_lock:
        if model_name not in _models:
            _models[model_name] = WhisperModel(
                model_name,
                device=MODEL_DEVICE,
                compute_type=MODEL_COMPUTE_TYPE,
            )
    return _models[model_name]


def cleanup_transcript(text: str, language: str) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    cleaned = re.sub(r"\s+([,.;:!?])", r"\1", cleaned)
    cleaned = re.sub(r"([,.;:!?])([^\s])", r"\1 \2", cleaned)
    cleaned = re.sub(r"\bi\b", "I", cleaned) if language == "en" else cleaned

    if cleaned and cleaned[-1] not in ".!?":
        cleaned = f"{cleaned}."

    if cleaned:
        cleaned = cleaned[0].upper() + cleaned[1:]

    return cleaned


@app.get("/health")
def health() -> Dict[str, Union[str, bool, List[str]]]:
    return {
        "status": "ok",
        "default_model": MODEL_SIZE,
        "available_models": list(AVAILABLE_MODELS),
        "device": MODEL_DEVICE,
        "compute_type": MODEL_COMPUTE_TYPE,
        "loaded_models": sorted(_models.keys()),
    }


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    language: str = Form("auto"),
    model: str = Form(MODEL_SIZE),
    refine_text: bool = Form(True),
) -> Dict[str, Union[str, float, bool, None]]:
    allowed_languages = {"auto", "pl", "en"}
    if language not in allowed_languages:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language '{language}'. Use one of: auto, pl, en",
        )

    if model not in AVAILABLE_MODELS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported model '{model}'. Use one of: {', '.join(AVAILABLE_MODELS)}",
        )

    suffix = Path(audio.filename or "audio.wav").suffix or ".wav"
    temp_path: Optional[str] = None

    try:
        with NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            shutil.copyfileobj(audio.file, tmp)
            temp_path = tmp.name

        fw_language = None if language == "auto" else language
        whisper_model = get_model(model)
        segments, info = whisper_model.transcribe(
            temp_path,
            language=fw_language,
            vad_filter=True,
        )
        raw_text = " ".join(segment.text.strip() for segment in segments).strip()
        resolved_language = info.language or (language if language != "auto" else "en")
        text = cleanup_transcript(raw_text, resolved_language) if refine_text else raw_text

        return {
            "text": text,
            "raw_text": raw_text,
            "detected_language": info.language,
            "language_probability": info.language_probability,
            "requested_language": language,
            "model_used": model,
            "refined_text": refine_text,
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
