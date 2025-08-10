from fastapi import FastAPI
from pydantic import BaseModel


app = FastAPI()


class TextRequest(BaseModel):
    text: str


@app.post("/analyze")
def analyze(request: TextRequest):
    text = request.text
    return {
        "original_text": text,
        "word_count": len(text.split()),
        "character_count": len(text),
    }
