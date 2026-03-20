#!/bin/sh
# Simple static file server for testing ECE WASM runtime.
# Serves from the project root so both wasm/ and bootstrap/ are accessible.
cd "$(dirname "$0")/.."
echo "Serving ECE at http://localhost:8080"
echo "  WASM runtime: http://localhost:8080/wasm/"
echo "  Bootstrap:    http://localhost:8080/bootstrap/"
python3 -m http.server 8080
