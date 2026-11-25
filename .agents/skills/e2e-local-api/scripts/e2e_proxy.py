"""Proxy local de teste (e2e-local): repassa para a API e injeta falhas.

Uso: python3 -I e2e_proxy.py <upstream_base> <port_file> <log_file> [porta_fixa]
Modos (GET /__e2e/mode/<m>): pass | 403html | refresh400 | 502
Loga só método, caminho (sem query), status e modo; nunca headers/corpos.
"""
import http.server
import socketserver
import sys
import threading
import urllib.error
import urllib.request

UPSTREAM, PORT_FILE, LOG_FILE = sys.argv[1], sys.argv[2], sys.argv[3]
state = {"mode": "pass"}
lock = threading.Lock()
HOP = {"connection", "keep-alive", "transfer-encoding", "content-length",
       "access-control-allow-origin", "access-control-allow-credentials",
       "access-control-allow-headers", "access-control-allow-methods",
       "access-control-expose-headers", "vary", "content-encoding"}

WAF_HTML = (b"<!DOCTYPE html><html><head><title>Attention Required!</title></head>"
            b"<body><h1>Sorry, you have been blocked</h1></body></html>")


def log(line):
    with lock, open(LOG_FILE, "a") as f:
        f.write(line + "\n")


class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def _cors(self):
        origin = self.headers.get("Origin")
        if origin:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Allow-Headers",
                             self.headers.get("Access-Control-Request-Headers", "*"))
            self.send_header("Access-Control-Allow-Methods",
                             "GET,POST,PUT,PATCH,DELETE,OPTIONS")
            self.send_header("Access-Control-Expose-Headers", "*")

    def _reply(self, status, body, ctype):
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _handle(self):
        path = self.path.split("?", 1)[0]
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        if path.startswith("/__e2e/mode/"):
            state["mode"] = path.rsplit("/", 1)[1]
            log(f"MODE -> {state['mode']}")
            return self._reply(200, state["mode"].encode(), "text/plain")
        mode = state["mode"]
        is_auth = path.startswith("/api/auth/")
        if mode == "403html" and not is_auth and path.startswith("/v1/"):
            log(f"{self.command} {path} -> 403 (stub WAF html) [{mode}]")
            return self._reply(403, WAF_HTML, "text/html; charset=UTF-8")
        if mode == "502" and not is_auth and path.startswith("/v1/"):
            log(f"{self.command} {path} -> 502 (stub gateway) [{mode}]")
            return self._reply(502, b"<html><body>502 Bad Gateway</body></html>", "text/html")
        if mode == "refresh400":
            if path == "/api/auth/refresh":
                log(f"{self.command} {path} -> 400 (stub gateway) [{mode}]")
                return self._reply(400, b"Gateway: Invalid Host Header", "text/plain")
            if not is_auth and path.startswith("/v1/"):
                log(f"{self.command} {path} -> 401 (stub expired) [{mode}]")
                return self._reply(
                    401, b'{"status":401,"error":{"code":"auth.token.expired","message":"stub"}}',
                    "application/json")
        req = urllib.request.Request(UPSTREAM + self.path, data=body, method=self.command)
        for k, v in self.headers.items():
            if k.lower() not in ("host", "origin", "referer", "content-length", "accept-encoding"):
                req.add_header(k, v)
        try:
            resp = urllib.request.urlopen(req, timeout=30)
            status, data, headers = resp.status, resp.read(), resp.headers
        except urllib.error.HTTPError as e:
            status, data, headers = e.code, e.read(), e.headers
        except Exception as e:  # upstream fora do ar
            log(f"{self.command} {path} -> 502 (upstream down: {type(e).__name__})")
            return self._reply(502, b"<html><body>502 Bad Gateway</body></html>", "text/html")
        log(f"{self.command} {path} -> {status}")
        self.send_response(status)
        self._cors()
        for k, v in headers.items():
            if k.lower() not in HOP:
                self.send_header(k, v)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _handle


class S(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


srv = S(("127.0.0.1", int(sys.argv[4]) if len(sys.argv) > 4 else 0), H)
with open(PORT_FILE, "w") as f:
    f.write(str(srv.server_address[1]))
srv.serve_forever()
