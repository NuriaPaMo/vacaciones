#!/bin/bash
# Bolt Framework — Penpot self-hosted bootstrap (Podman by default)
# Idempotent, opt-in. Not invoked automatically — init.sh only offers to run it at
# the end with explicit user confirmation. Otherwise run manually (or via the
# `bolt-penpot` agent in `setup` mode) when decisions.frontend.design-tool = penpot-local.
#
# Penpot is a MULTI-CONTAINER stack (frontend, backend, exporter, postgres, redis)
# brought up via the official compose file. This is NOT a single `podman run` image.
#
# See: docs/integrations/penpot-integration-plan.md

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────────
RUNTIME="podman"      # Podman is the Bolt default; override with --runtime docker
PORT=9001             # Official Penpot web UI default
ACTION="up"           # up | stop | down | status
REFRESH_COMPOSE=false

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
info()  { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }

usage() {
    echo "Usage: install-penpot.sh [OPTIONS]"
    echo "Options:"
    echo "  --runtime <podman|docker>  Container runtime (default: podman)"
    echo "  --port <int>               Host port for the web UI (default: 9001)"
    echo "  --stop                     Stop the Penpot stack (keeps data)"
    echo "  --down                     Stop and remove containers (keeps named volumes)"
    echo "  --status                   Show stack status"
    echo "  --refresh-compose          Re-download the official compose file"
    echo "  --help                     Show this help message"
}

# ── Parse args ───────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --runtime) RUNTIME="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --stop) ACTION="stop"; shift ;;
        --down) ACTION="down"; shift ;;
        --status) ACTION="status"; shift ;;
        --refresh-compose) REFRESH_COMPOSE=true; shift ;;
        --help) usage; exit 0 ;;
        *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ "$RUNTIME" != "podman" && "$RUNTIME" != "docker" ]]; then
    err "Invalid runtime: $RUNTIME (expected podman or docker)"; exit 1
fi

# ── Paths ────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PENPOT_DIR="$REPO_ROOT/.boltf/penpot"
COMPOSE_FILE="$PENPOT_DIR/docker-compose.yaml"
COMPOSE_URL="https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml"
PROJECT_NAME="penpot"

# ── Resolve compose command ────────────────────────────────────────────────────
# Prefers integrated subcommand (`<runtime> compose`), falls back to standalone
# (`<runtime>-compose`). Sets COMPOSE_EXE and COMPOSE_PRE.
resolve_compose() {
    if ! command -v "$RUNTIME" >/dev/null 2>&1; then
        err "$RUNTIME is not installed or not on PATH."
        if [[ "$RUNTIME" == "podman" ]]; then
            echo -e "${GRAY}   Install Podman: https://podman.io/docs/installation${NC}"
        else
            echo -e "${GRAY}   Install Docker: https://docs.docker.com/get-docker/${NC}"
        fi
        exit 1
    fi

    if "$RUNTIME" compose version >/dev/null 2>&1; then
        COMPOSE_EXE="$RUNTIME"
        COMPOSE_PRE=("compose")
        return
    fi

    if command -v "${RUNTIME}-compose" >/dev/null 2>&1; then
        COMPOSE_EXE="${RUNTIME}-compose"
        COMPOSE_PRE=()
        return
    fi

    err "Neither '$RUNTIME compose' nor '${RUNTIME}-compose' is available."
    if [[ "$RUNTIME" == "podman" ]]; then
        echo -e "${GRAY}   Install podman-compose: pip install podman-compose${NC}"
    fi
    exit 1
}

# ── Compose file management ────────────────────────────────────────────────────
fetch_compose() {
    mkdir -p "$PENPOT_DIR"
    if [[ -f "$COMPOSE_FILE" && "$REFRESH_COMPOSE" == "false" ]]; then
        info "Using existing compose file: $COMPOSE_FILE"
        return
    fi
    info "Downloading official Penpot compose file..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$COMPOSE_URL" -o "$COMPOSE_FILE"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$COMPOSE_URL" -O "$COMPOSE_FILE"
    else
        err "Neither curl nor wget is available to download the compose file."; exit 1
    fi
    ok "Compose file saved to $COMPOSE_FILE"
}

# ── Main ───────────────────────────────────────────────────────────────────────
resolve_compose
COMPOSE_ARGS=("${COMPOSE_PRE[@]}" -p "$PROJECT_NAME" -f "$COMPOSE_FILE")

case "$ACTION" in
    status)
        [[ -f "$COMPOSE_FILE" ]] || { warn "No compose file yet — Penpot has not been installed."; exit 0; }
        "$COMPOSE_EXE" "${COMPOSE_ARGS[@]}" ps
        exit $?
        ;;
    stop)
        [[ -f "$COMPOSE_FILE" ]] || { warn "Nothing to stop — no compose file."; exit 0; }
        info "Stopping Penpot stack (data preserved)..."
        "$COMPOSE_EXE" "${COMPOSE_ARGS[@]}" stop
        ok "Penpot stopped."
        exit $?
        ;;
    down)
        [[ -f "$COMPOSE_FILE" ]] || { warn "Nothing to remove — no compose file."; exit 0; }
        info "Removing Penpot containers (named volumes kept)..."
        "$COMPOSE_EXE" "${COMPOSE_ARGS[@]}" down
        ok "Penpot containers removed. Data volumes preserved."
        exit $?
        ;;
esac

# Default action: up
info "Bootstrapping Penpot via $COMPOSE_EXE (runtime: $RUNTIME)..."
fetch_compose

if ! "$COMPOSE_EXE" "${COMPOSE_ARGS[@]}" up -d; then
    err "Failed to start Penpot stack. Inspect logs: $COMPOSE_EXE -p $PROJECT_NAME logs"
    exit 1
fi

# ── Health check ────────────────────────────────────────────────────────────────
if [[ "$PORT" != "9001" ]]; then
    warn "--port is not currently supported because the official compose file is not patched by this script. Using 9001."
    PORT=9001
fi
UI_URL="http://localhost:$PORT"
info "Waiting for Penpot UI at $UI_URL (up to 120s)..."
READY=false
for _ in $(seq 1 24); do
    if command -v curl >/dev/null 2>&1; then
        if curl -fsS -o /dev/null --max-time 5 "$UI_URL" 2>/dev/null; then READY=true; break; fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --spider --timeout=5 "$UI_URL" 2>/dev/null; then READY=true; break; fi
    else
        warn "Skipping UI health check (neither curl nor wget available)."
        break
    fi
    sleep 5
done

if [[ "$READY" == "true" ]]; then
    ok "Penpot is up at $UI_URL"
else
    warn "Penpot did not respond within 120s. It may still be initializing."
    echo -e "${GRAY}   Check status: install-penpot.sh --status${NC}"
    echo -e "${GRAY}   Check logs:   $COMPOSE_EXE -p $PROJECT_NAME logs${NC}"
fi

# ── Next steps ────────────────────────────────────────────────────────────────
echo ""
echo -e "\033[0;35m── Next steps ──────────────────────────────────────────────${NC}"
echo "  1. Open $UI_URL and create your account (first registration)."
echo "  2. Generate an MCP key: Account → Integrations → MCP Server."
echo "  3. Wire the MCP into both clients (.mcp.json + .vscode/mcp.json)."
echo -e "${GRAY}     RECOMMENDED — keep the token in your environment, never in git:${NC}"
echo -e "${GRAY}       export PENPOT_MCP_URL='$UI_URL/mcp/stream?userToken=<MCP_KEY>'${NC}"
echo -e "${GRAY}       .boltf/scripts/bash/sync-mcp-config.sh   # writes \${PENPOT_MCP_URL} (no secret in .mcp.json)${NC}"
echo -e "${GRAY}     (--penpot-mcp-url bakes the literal token into .mcp.json — only for untracked local use.)${NC}"
echo "  4. Invoke the bolt-penpot agent (read/validate/handoff modes)."
echo ""
echo -e "${GRAY}  NOTE: Podman rootless networking and the official compose file may need${NC}"
echo -e "${GRAY}  manual adjustment on first run. Verify the stack with --status.${NC}"
