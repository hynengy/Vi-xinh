import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
PHASE1_DIR = ROOT_DIR / "phase-1-web-demo"

if str(PHASE1_DIR) not in sys.path:
    sys.path.insert(0, str(PHASE1_DIR))

from backend.app import app

# WSGI handler for Vercel Serverless
app.debug = False
