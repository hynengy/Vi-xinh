import sys
from pathlib import Path

CURRENT_DIR = Path(__file__).resolve().parent.parent

if str(CURRENT_DIR) not in sys.path:
    sys.path.insert(0, str(CURRENT_DIR))

from backend.app import app

# WSGI handler for Vercel Serverless
handler = app
app.debug = False
