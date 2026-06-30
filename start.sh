#!/bin/bash
# ============================================================
#  STI College Cubao — ID Management System
#  One-command startup script
# ============================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"
PID_FILE="$ROOT/.pids"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

stop_all() {
  echo -e "\n${YELLOW}Shutting down...${NC}"
  if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
      kill "$pid" 2>/dev/null
    done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi
  exit 0
}

trap stop_all SIGINT SIGTERM

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STI College Cubao — ID Management       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Check Python ────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}✗ python3 not found. Please install Python 3.9+${NC}"
  exit 1
fi

# ── Check Flask ─────────────────────────────────────────────
echo -e "${YELLOW}► Checking Python dependencies...${NC}"
python3 -c "import flask, flask_sock, flask_cors" 2>/dev/null
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}  Installing: flask flask-sock flask-cors${NC}"
  pip install flask flask-sock flask-cors --break-system-packages -q \
    || pip install flask flask-sock flask-cors -q
fi
echo -e "${GREEN}  ✓ Python dependencies OK${NC}"

# ── Check Node ──────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo -e "${RED}✗ Node.js not found. Please install Node 18+${NC}"
  exit 1
fi

# ── Install frontend deps if needed ─────────────────────────
if [ ! -d "$FRONTEND/node_modules" ]; then
  echo -e "${YELLOW}► Installing frontend dependencies...${NC}"
  cd "$FRONTEND" && npm install --silent
  echo -e "${GREEN}  ✓ npm install done${NC}"
fi

echo ""

# ── Start Backend ────────────────────────────────────────────
echo -e "${YELLOW}► Starting Flask backend on http://localhost:5000 ...${NC}"
cd "$BACKEND"
python3 server.py > "$ROOT/backend.log" 2>&1 &
BACKEND_PID=$!
echo "$BACKEND_PID" > "$PID_FILE"
sleep 2

if ! kill -0 $BACKEND_PID 2>/dev/null; then
  echo -e "${RED}✗ Backend failed to start. Check backend.log${NC}"
  cat "$ROOT/backend.log"
  exit 1
fi
echo -e "${GREEN}  ✓ Backend running (PID $BACKEND_PID)${NC}"

# ── Start Frontend ───────────────────────────────────────────
echo -e "${YELLOW}► Starting Vite frontend on http://localhost:5173 ...${NC}"
cd "$FRONTEND"
npm run dev -- --host 2>&1 &
FRONTEND_PID=$!
echo "$FRONTEND_PID" >> "$PID_FILE"
sleep 3

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓  SYSTEM RUNNING                       ║${NC}"
echo -e "${GREEN}║                                          ║${NC}"
echo -e "${GREEN}║  App  →  http://localhost:5173           ║${NC}"
echo -e "${GREEN}║  API  →  http://localhost:5000/api       ║${NC}"
echo -e "${GREEN}║  WS   →  ws://localhost:5173/ws          ║${NC}"
echo -e "${GREEN}║                                          ║${NC}"
echo -e "${GREEN}║  Press Ctrl+C to stop                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Keep running ─────────────────────────────────────────────
wait $FRONTEND_PID