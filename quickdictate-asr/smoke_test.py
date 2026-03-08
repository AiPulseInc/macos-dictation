from pathlib import Path

from fastapi.testclient import TestClient

from app import app


EN_SAMPLE = Path(
    "/System/Library/CoreServices/Language Chooser.app/Contents/Resources/VOInstructions-en.m4a"
)
PL_SAMPLE = Path(
    "/System/Library/CoreServices/Language Chooser.app/Contents/Resources/VOInstructions-pl.m4a"
)


def post_sample(client: TestClient, sample: Path, language: str) -> dict:
    with sample.open("rb") as handle:
        response = client.post(
            "/transcribe",
            files={"audio": (sample.name, handle, "audio/mp4")},
            data={"language": language},
        )
    response.raise_for_status()
    return response.json()


def main() -> None:
    client = TestClient(app)

    health = client.get("/health")
    health.raise_for_status()
    print("health:", health.json())

    en_payload = post_sample(client, EN_SAMPLE, "en")
    print("en:", en_payload)

    pl_payload = post_sample(client, PL_SAMPLE, "pl")
    print("pl:", pl_payload)

    auto_payload = post_sample(client, EN_SAMPLE, "auto")
    print("auto:", auto_payload)

    invalid = client.post(
        "/transcribe",
        files={"audio": ("x.wav", b"123", "audio/wav")},
        data={"language": "de"},
    )
    print("invalid-language:", invalid.status_code, invalid.json())


if __name__ == "__main__":
    main()
