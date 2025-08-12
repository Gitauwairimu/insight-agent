from fastapi import FastAPI
from pydantic import BaseModel

# FastAPI App Initialization
app = FastAPI()

#     Defines the expected request format with a single text field
class TextRequest(BaseModel):
    text: str

# The endpoint analyzes the provided text and returns statistics.
@app.post("/analyze")
def analyze(request: TextRequest):
    text = request.text
    return {
        "original_text": text,
        "word_count": len(text.split()),
        "character_count": len(text),
    }
