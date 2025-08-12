# Use a small sized image
FROM python:3.9-slim

# Define working directory
WORKDIR /app

# Copy and Install dependencies first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as non-root user
RUN useradd -m myuser && chown -R myuser /app
USER myuser

# Run command on localhost on port 8000 using uvicorn server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]