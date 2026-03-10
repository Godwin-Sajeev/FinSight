"""
api/start_server.py
-------------------
One-command launcher for the Smart UPI Monitor API server.

Usage:
    python api/start_server.py

What it does:
    1. Checks and installs required packages (fastapi, uvicorn)
    2. Starts the FastAPI server on port 8000
    3. Flutter app connects to http://10.0.2.2:8000 (Android emulator localhost)
"""

import subprocess
import sys
import os

# Ensure project root is on path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

REQUIRED = ["fastapi", "uvicorn", "pydantic"]

def check_install():
    for pkg in REQUIRED:
        try:
            __import__(pkg)
        except ImportError:
            print(f"[Setup] Installing {pkg}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", pkg, "-q"])

def main():
    check_install()

    print()
    print("=" * 55)
    print("  Smart UPI Monitor - FastAPI Server")
    print("  Flutter connects at: http://10.0.2.2:8000")
    print("  Browser test at:     http://localhost:8000/docs")
    print("=" * 55)
    print()

    import uvicorn
    uvicorn.run(
        "api.server:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info",
    )

if __name__ == "__main__":
    main()
