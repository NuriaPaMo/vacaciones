#!/bin/bash
# Bolt Framework — MCP config sync (dual-client)
# Generates BOTH MCP targets from the active scopes' mcp-tools definitions:
#   - .vscode/mcp.json   → GitHub Copilot (VS Code) format: { servers, inputs }
#   - .mcp.json          → Claude Code format: { mcpServers }
#
# Closes a pre-existing framework gap: scope mcp-tools only fed Copilot (.vscode/)
# and nothing generated Claude's .mcp.json. Not Penpot-specific, but is what makes
# the Penpot MCP (and every scope MCP) reach BOTH clients.
#
# Idempotent: merges server entries into existing files. Requires jq.
#
# See: docs/integrations/penpot-integration-plan.md

set -euo pipefail

PROJECT_ROOT=""
PENPOT_MCP_URL_ARG=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }

usage() {
    echo "Usage: sync-mcp-config.sh [--project-root <path>] [--penpot-mcp-url <url>]"
    echo "  Generates .vscode/mcp.json (Copilot) and .mcp.json (Claude) from active scopes."
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --penpot-mcp-url) PENPOT_MCP_URL_ARG="$2"; shift 2 ;;
        --help) usage; exit 0 ;;
        *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if ! command -v jq >/dev/null 2>&1; then
    err "jq is required but not installed. Install: https://jqlang.github.io/jq/download/"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "$PROJECT_ROOT" ]] && PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ── Resolve active scopes ────────────────────────────────────────────────────
SCOPES_YAML="$PROJECT_ROOT/.boltf/scopes.yaml"
ACTIVE_SCOPES=()
if [[ -f "$SCOPES_YAML" ]]; then
    in_active=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^active-scopes:[[:space:]]*$ ]]; then in_active=true; continue; fi
        if [[ "$in_active" == "true" ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
                ACTIVE_SCOPES+=("${BASH_REMATCH[1]}")
            elif [[ "$line" =~ ^[^[:space:]] ]]; then
                in_active=false
            fi
        fi
    done < "$SCOPES_YAML"
    # work-management is transversal (always active)
    if [[ ! " ${ACTIVE_SCOPES[*]} " =~ " work-management " ]]; then ACTIVE_SCOPES+=("work-management"); fi
else
    warn "scopes.yaml not found — scanning all scope folders with mcp-tools."
    for d in "$PROJECT_ROOT"/.boltf/scopes/*/; do
        [[ -f "${d}mcp-tools/default.mcp.servers.json" ]] && ACTIVE_SCOPES+=("$(basename "$d")")
    done
fi

info "Active scopes: ${ACTIVE_SCOPES[*]:-<none>}"

# ── Aggregate servers + inputs across scopes ──────────────────────────────────
AGG_SERVERS='{}'
AGG_INPUTS='[]'
for scope in "${ACTIVE_SCOPES[@]:-}"; do
    [[ -z "$scope" ]] && continue
    f="$PROJECT_ROOT/.boltf/scopes/$scope/mcp-tools/default.mcp.servers.json"
    [[ -f "$f" ]] || continue
    s=$(jq -c '.servers // {}' "$f")
    i=$(jq -c '.inputs // []' "$f")
    AGG_SERVERS=$(jq -c -n --argjson a "$AGG_SERVERS" --argjson b "$s" '$a * $b')
    AGG_INPUTS=$(jq -c -n --argjson a "$AGG_INPUTS" --argjson b "$i" '$a + $b | unique_by(.id)')
done

if [[ "$(jq 'length' <<<"$AGG_SERVERS")" -eq 0 ]]; then
    warn "No MCP servers found across active scopes. Nothing to sync."; exit 0
fi

# ── 1) Copilot target: .vscode/mcp.json (verbatim servers + inputs) ────────────
mkdir -p "$PROJECT_ROOT/.vscode"
VSCODE_PATH="$PROJECT_ROOT/.vscode/mcp.json"
EXISTING_VSCODE='{}'
[[ -f "$VSCODE_PATH" ]] && EXISTING_VSCODE=$(cat "$VSCODE_PATH")
jq -n \
    --argjson existing "$EXISTING_VSCODE" \
    --argjson servers "$AGG_SERVERS" \
    --argjson inputs "$AGG_INPUTS" \
    '{
        servers: ((($existing.servers) // {}) * $servers),
        inputs:  ((($existing.inputs) // []) + $inputs | unique_by(.id))
    } | if (.inputs | length) == 0 then del(.inputs) else . end' \
    > "$VSCODE_PATH"
ok "Wrote $VSCODE_PATH (Copilot) — $(jq '.servers | length' "$VSCODE_PATH") servers"

# ── 2) Claude target: .mcp.json (mcpServers, ${input:foo-bar} → ${FOO_BAR}) ────
MCP_PATH="$PROJECT_ROOT/.mcp.json"
EXISTING_MCP='{}'
[[ -f "$MCP_PATH" ]] && EXISTING_MCP=$(cat "$MCP_PATH")

# Translate VS Code ${input:...} tokens to ${ENV_VAR} that Claude expands, then
# optionally bake the concrete Penpot URL.
TRANSLATED_SERVERS=$(jq -c '
    walk(
        if type == "string" then
            gsub("\\$\\{input:(?<id>[a-zA-Z0-9_-]+)\\}";
                 "${" + (.id | ascii_upcase | gsub("-"; "_")) + "}")
        else . end
    )
' <<<"$AGG_SERVERS")

if [[ -n "$PENPOT_MCP_URL_ARG" ]]; then
    # WARNING: bakes the literal token into .mcp.json (tracked file) — untracked local use only.
    TRANSLATED_SERVERS=$(jq -c --arg url "$PENPOT_MCP_URL_ARG" \
        'if has("penpot") then .penpot.url = $url else . end' <<<"$TRANSLATED_SERVERS")
    warn 'Baking a literal Penpot URL into .mcp.json (tracked file). Do NOT commit the token. Prefer the ${PENPOT_MCP_URL} env var.'
fi

jq -n \
    --argjson existing "$EXISTING_MCP" \
    --argjson servers "$TRANSLATED_SERVERS" \
    '{ mcpServers: ((($existing.mcpServers) // {}) * $servers) }' \
    > "$MCP_PATH"
ok "Wrote $MCP_PATH (Claude) — $(jq '.mcpServers | length' "$MCP_PATH") servers"

if jq -e '.mcpServers | has("penpot")' "$MCP_PATH" >/dev/null && [[ -z "$PENPOT_MCP_URL_ARG" ]]; then
    warn "Claude .mcp.json penpot URL uses \${PENPOT_MCP_URL}. Set that env var, or re-run with --penpot-mcp-url."
fi
info "MCP sync complete. Restart Claude Code / VS Code to pick up changes."
