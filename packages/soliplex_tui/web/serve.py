#!/usr/bin/env python3
"""Dev server: static files + streaming reverse proxy for /api/."""

import http.server
import http.client
import sys
import os
from urllib.parse import urlparse

BACKEND = os.environ.get("BACKEND_URL", "http://localhost:8000")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8001
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

_parsed = urlparse(BACKEND)
BACKEND_HOST = _parsed.hostname
BACKEND_PORT = _parsed.port or 80

# Headers to skip when forwarding (hop-by-hop or set by us).
SKIP_HEADERS = frozenset(
    {"host", "connection", "transfer-encoding", "keep-alive",
     "te", "trailers", "upgrade"}
)


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    # ── routing ──────────────────────────────────────────────────────
    def do_GET(self):
        if self.path.startswith("/api/"):
            self._proxy()
        else:
            super().do_GET()

    def do_POST(self):
        self._proxy()

    def do_PUT(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

    def do_PATCH(self):
        self._proxy()

    def do_OPTIONS(self):
        self._proxy()

    # ── streaming reverse proxy ──────────────────────────────────────
    def _proxy(self):
        # Read request body if present.
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else None

        try:
            conn = http.client.HTTPConnection(BACKEND_HOST, BACKEND_PORT,
                                              timeout=300)

            # Forward ALL request headers (except hop-by-hop).
            headers = {}
            for key in self.headers:
                if key.lower() not in SKIP_HEADERS:
                    headers[key] = self.headers[key]
            headers["Host"] = f"{BACKEND_HOST}:{BACKEND_PORT}"

            conn.request(self.command, self.path, body=body, headers=headers)
            resp = conn.getresponse()

            # Send status + response headers.
            self.send_response(resp.status)
            is_sse = False
            for key, val in resp.getheaders():
                low = key.lower()
                if low in SKIP_HEADERS:
                    continue
                self.send_header(key, val)
                if low == "content-type" and "text/event-stream" in val:
                    is_sse = True
            self.end_headers()

            # Stream the response body in chunks.
            if is_sse:
                # SSE: flush after every chunk so the browser sees events.
                while True:
                    chunk = resp.read(1)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
            else:
                while True:
                    chunk = resp.read(8192)
                    if not chunk:
                        break
                    self.wfile.write(chunk)

            conn.close()

        except BrokenPipeError:
            pass  # Client disconnected.
        except Exception as e:
            try:
                self.send_error(502, f"Backend error: {e}")
            except Exception:
                pass

    # Suppress per-request log noise for static files.
    def log_message(self, fmt, *args):
        if self.path.startswith("/api/"):
            super().log_message(fmt, *args)


print(f"Serving on http://localhost:{PORT}  (backend: {BACKEND})")
http.server.HTTPServer(("", PORT), ProxyHandler).serve_forever()
