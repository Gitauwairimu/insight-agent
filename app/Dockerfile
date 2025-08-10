# FROM python:3.9-slim
# WORKDIR /app

# # Install dependencies first for better caching
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# # Copy application code
# COPY . .

# # Run as non-root user
# RUN useradd -m myuser && chown -R myuser /app
# USER myuser

# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]



# Use official Python slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install dependencies for building some Python packages if needed, then remove them
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies without cache
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Create and switch to a non-root user
RUN useradd -m myuser && chown -R myuser /app
USER myuser

# Run the app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]