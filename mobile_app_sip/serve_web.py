#!/usr/bin/env python3
"""
Simple HTTP server to serve Flutter web build output on port 8080.
Run from mobile_app_sip directory: python serve_web.py
"""
import http.server
import socketserver
import os

PORT = 8080
BUILD_DIR = os.path.join(os.path.dirname(__file__), 'build', 'web')

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    def end_headers(self):
        # Required headers for Flutter web
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def do_GET(self):
        # Serve index.html for all unknown routes (SPA routing)
        path = os.path.join(BUILD_DIR, self.path.lstrip('/'))
        if not os.path.exists(path) or os.path.isdir(path):
            self.path = '/index.html'
        super().do_GET()

if __name__ == '__main__':
    os.chdir(BUILD_DIR)
    with socketserver.TCPServer(('0.0.0.0', PORT), Handler) as httpd:
        print(f"Serving Flutter web app at http://0.0.0.0:{PORT}")
        print(f"Serving from: {BUILD_DIR}")
        httpd.serve_forever()
