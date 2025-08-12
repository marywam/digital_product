# ---------- Stage 1: Build Stage ----------
    FROM python:3.11-slim AS builder

    ENV PYTHONDONTWRITEBYTECODE=1
    ENV PYTHONUNBUFFERED=1
    
    # Install build dependencies for compiling Python packages
    RUN apt-get update && \
        apt-get install -y --no-install-recommends build-essential gcc && \
        rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    COPY requirements.txt /app/
    RUN pip install --user --no-cache-dir -r requirements.txt
    
    COPY . /app
    
    
    # ---------- Stage 2: Production Stage ----------
    FROM python:3.11-slim
    
    ENV PYTHONDONTWRITEBYTECODE=1
    ENV PYTHONUNBUFFERED=1
    
    WORKDIR /app
    
    # Copy only installed Python packages from builder stage
    COPY --from=builder /root/.local /root/.local
    COPY --from=builder /app /app
    
    # Ensure pip-installed binaries are in PATH
    ENV PATH=/root/.local/bin:$PATH
    
    # Expose port 8000
    EXPOSE 8000
    
    # Run the app
    CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000"]
    