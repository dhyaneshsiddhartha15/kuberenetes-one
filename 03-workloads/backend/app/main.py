#!/usr/bin/env python3
"""
Backend API - FastAPI application
Provides /health and /api/hello endpoints
"""

from fastapi import FastAPI
from datetime import datetime
from prometheus_fastapi_instrumentator import Instrumentator
import os

app = FastAPI(
    title="Dhyanesh's Backend API",
    description="A simple FastAPI backend for Kubernetes learning",
    version="1.0.0"
)

# Get environment variables with defaults
APP_ENV = os.getenv("APP_ENV", "production")
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")

# Prometheus metrics
Instrumentator().instrument(app).expose(app)


@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "service": "backend",
        "version": "1.0.0",
        "status": "running",
        "environment": APP_ENV
    }


@app.get("/health")
async def health():
    """Health check endpoint for Kubernetes probes"""
    return {
        "status": "ok",
        "service": "backend",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/api/hello")
async def hello():
    """Hello endpoint - called by frontend"""
    return {
        "message": "Hello from Dhyanesh's backend!",
        "timestamp": datetime.utcnow().isoformat(),
        "environment": APP_ENV,
        "pod_info": {
            "note": "This response is coming from a Kubernetes pod!"
        }
    }


@app.get("/api/info")
async def info():
    """Application information endpoint"""
    return {
        "service": "backend",
        "environment": APP_ENV,
        "log_level": LOG_LEVEL,
        "python_version": "3.11",
        "framework": "FastAPI",
        "documentation": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level=LOG_LEVEL.lower()
    )
