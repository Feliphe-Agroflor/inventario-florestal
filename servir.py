import http.server
import socketserver
import os
import webbrowser
import threading

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PORT = 8081
DIRECTORY = os.path.join(BASE_DIR, "build", "web")

print("=== Inventário Florestal ===")

if not os.path.exists(os.path.join(DIRECTORY, "flutter_bootstrap.js")):
    print("Build não encontrado. Execute primeiro: flutter build web --no-tree-shake-icons")
    import sys
    sys.exit(1)

print(f"Servindo build existente...")
os.chdir(DIRECTORY)

handler = http.server.SimpleHTTPRequestHandler

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), handler) as httpd:
    print(f"Servidor rodando em http://localhost:{PORT}")
    print("Abra o navegador e acesse a URL acima")
    print("Pressione Ctrl+C para parar")
    threading.Timer(1.5, lambda: webbrowser.open(f"http://localhost:{PORT}")).start()
    httpd.serve_forever()
