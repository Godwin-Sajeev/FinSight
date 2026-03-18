FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the code
COPY . .

# Set environment variables
ENV PYTHONPATH=/app
ENV PORT=7860

# Hugging Face user setup
RUN useradd -m -u 1000 user
RUN chown -R user:user /app
USER user

# Run server
CMD ["uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
