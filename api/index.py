import sys
import urllib.parse
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
PHASE1_DIR = ROOT_DIR / "phase-1-web-demo"

if str(PHASE1_DIR) not in sys.path:
    sys.path.insert(0, str(PHASE1_DIR))

from backend.app import app


class VercelPathFixMiddleware:
    """WSGI Middleware khôi phục PATH_INFO chuẩn xác cho Flask trên Vercel Serverless.
    
    Khi Vercel điều hướng qua rewrite, PATH_INFO có thể bị đặt thành /api/index.py.
    Middleware này bóc tách đường dẫn thực tế từ query param __path__ hoặc các header
    HTTP_X_MATCHED_PATH / REQUEST_URI / RAW_URI để Flask định tuyến chính xác đến các API POST/GET.
    """

    def __init__(self, wsgi_app):
        self.wsgi_app = wsgi_app

    def __call__(self, environ, start_response):
        qs = environ.get("QUERY_STRING", "")
        matched_path = (
            environ.get("HTTP_X_MATCHED_PATH")
            or environ.get("HTTP_X_FORWARDED_URI")
            or environ.get("REQUEST_URI")
            or environ.get("RAW_URI")
        )

        orig_path = None
        if "__path__=" in qs:
            parsed = urllib.parse.parse_qs(qs)
            if "__path__" in parsed and parsed["__path__"]:
                orig_path = parsed["__path__"][0]
                # Loại bỏ param __path__ để query string sạch sẽ
                remain = [(k, v) for k, v_list in parsed.items() if k != "__path__" for v in v_list]
                environ["QUERY_STRING"] = urllib.parse.urlencode(remain)
        elif matched_path and not matched_path.startswith("/api/index"):
            orig_path = matched_path.split("?")[0]

        if orig_path:
            environ["PATH_INFO"] = orig_path

        return self.wsgi_app(environ, start_response)


app.wsgi_app = VercelPathFixMiddleware(app.wsgi_app)
handler = app
app.debug = False
