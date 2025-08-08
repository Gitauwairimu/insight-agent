FROM python:3.9-slim
WORKDIR /app

# Install dependencies first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as non-root user
RUN useradd -m myuser && chown -R myuser /app
USER myuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]