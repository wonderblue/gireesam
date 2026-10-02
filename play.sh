#!/usr/bin/env bash
set -e

PORT=${1:-8080}
DIR="web-export"

if [ ! -d "$DIR" ]; then
  echo "Error: $DIR directory not found!"
  exit 1
fi

echo "============================================================"
echo "  🎭 Gireesam's Great Escape — Local Web Server"
echo "============================================================"
echo ""
echo "  Game URL:  http://localhost:${PORT}/"
echo "  Directory: $(pwd)/${DIR}"
echo ""
echo "  Press Ctrl+C to stop the server."
echo "============================================================"

# Try to open the URL in default browser (macOS / Linux)
if command -v open >/dev/null 2>&1; then
  (sleep 1 && open "http://localhost:${PORT}/") &
elif command -v xdg-open >/dev/null 2>&1; then
  (sleep 1 && xdg-open "http://localhost:${PORT}/") &
fi

python3 -m http.server "${PORT}" --directory "${DIR}"
