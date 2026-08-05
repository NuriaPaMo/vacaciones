#!/bin/bash
# Bolt Framework — Update agents, skills and support files in a consumer repo
# Syncs .github/agents/, .claude/agents/, and .claude/skills/ from the framework
# source repo into a consumer repo, classifying each file and prompting for
# MODIFIED files when stdin is a terminal.
#
# Usage:
#   update-bolt-framework.sh [--source-dir <path>] [--dest-dir <path>]
#                            [--ai-client claude|copilot|auto]
#                            [--dry-run] [--force] [--help]

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
SOURCE_DIR=""
DEST_DIR="$(pwd)"
AI_CLIENT="auto"
DRY_RUN=false
FORCE=false
HAS_JQ=false

# ── Counters ──────────────────────────────────────────────────────────────────
COUNT_NEW=0
COUNT_PRISTINE=0
COUNT_MODIFIED=0
COUNT_SKIPPED=0
COUNT_REPLACED=0
COUNT_ORPHAN=0

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --source-dir <path>   Path to bolt-framework source repo"
    echo "                        (auto-detected from bolt-upstream remote if omitted)"
    echo "  --dest-dir <path>     Consumer repo root (default: current directory)"
    echo "  --ai-client <value>   claude | copilot | auto (default: auto)"
    echo "  --dry-run             Preview only, no changes written"
    echo "  --force               Skip interactive menus, accept framework versions"
    echo "  --help                Show this help"
    echo ""
    echo "Files synced:"
    echo "  Primary   .github/agents/*.agent.md"
    echo "            .claude/agents/*.md"
    echo "            .claude/skills/*/SKILL.md"
    echo "  Support   all other files under .claude/skills/*/ (copy-if-missing only)"
}

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --source-dir)  SOURCE_DIR="$2"; shift 2 ;;
        --dest-dir)    DEST_DIR="$2";   shift 2 ;;
        --ai-client)   AI_CLIENT="$2";  shift 2 ;;
        --dry-run)     DRY_RUN=true;    shift   ;;
        --force)       FORCE=true;      shift   ;;
        --help)        usage; exit 0             ;;
        *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ── Validate ai-client value ──────────────────────────────────────────────────
case "$AI_CLIENT" in
    claude|copilot|auto) ;;
    *) err "--ai-client must be claude, copilot, or auto (got: $AI_CLIENT)"; exit 1 ;;
esac

# ── Resolve effective AI client ───────────────────────────────────────────────
resolve_ai_client() {
    if [[ "$AI_CLIENT" != "auto" ]]; then
        echo "$AI_CLIENT"
        return
    fi
    if command -v claude >/dev/null 2>&1; then
        echo "claude"
    elif command -v gh >/dev/null 2>&1; then
        echo "copilot"
    else
        echo "none"
    fi
}
EFFECTIVE_AI_CLIENT="$(resolve_ai_client)"

# ── jq detection ─────────────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
else
    warn "jq not found — sync-state tracking disabled (new files still copied)"
fi

# ── Hash helper ───────────────────────────────────────────────────────────────
compute_hash() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    else
        shasum -a 256 "$file" | awk '{print $1}'
    fi
}

# ── Source-dir auto-detection ─────────────────────────────────────────────────
detect_source_dir() {
    local remote_url
    remote_url=$(git -C "$DEST_DIR" remote get-url bolt-upstream 2>/dev/null || true)
    if [[ -n "$remote_url" ]]; then
        # Only use as source if it's a local path (no :// and not github.com)
        if [[ "$remote_url" != *"://"* && "$remote_url" != *"github.com"* ]]; then
            echo "$remote_url"
            return
        fi
    fi
    echo ""
}

if [[ -z "$SOURCE_DIR" ]]; then
    SOURCE_DIR="$(detect_source_dir)"
    if [[ -z "$SOURCE_DIR" ]]; then
        err "Could not auto-detect source directory. Use --source-dir <path>."
        exit 1
    fi
    info "Auto-detected source dir from bolt-upstream remote: $SOURCE_DIR"
fi

# Normalise paths to absolute
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
DEST_DIR="$(cd "$DEST_DIR" && pwd)"

info "Source : $SOURCE_DIR"
info "Dest   : $DEST_DIR"
$DRY_RUN && warn "DRY-RUN mode — no files will be written"
$FORCE   && info "FORCE mode — MODIFIED files will be auto-replaced"

# ── Backup ────────────────────────────────────────────────────────────────────
BACKUP_TIMESTAMP="$(date '+%Y-%m-%d-%H%M')"
BACKUP_DIR="$DEST_DIR/.boltf/.update-backup/$BACKUP_TIMESTAMP"

backup_file() {
    local dest_file="$1"
    if $DRY_RUN; then return; fi
    local rel_path="${dest_file#$DEST_DIR/}"
    local backup_path="$BACKUP_DIR/$rel_path"
    mkdir -p "$(dirname "$backup_path")"
    cp "$dest_file" "$backup_path"
}

# ── Sync-state helpers ────────────────────────────────────────────────────────
SYNC_STATE_FILE="$DEST_DIR/.boltf/bolt-sync-state.json"

load_stored_hash() {
    # $1 = relative path key; hash stored as plain string value (compatible with PS version)
    if ! $HAS_JQ || [[ ! -f "$SYNC_STATE_FILE" ]]; then
        echo ""
        return
    fi
    jq -r --arg key "$1" '.files[$key] // empty' "$SYNC_STATE_FILE" 2>/dev/null || echo ""
}

save_hash_to_state() {
    # $1 = relative path key, $2 = hash value (stored as plain string — matches PS format)
    if ! $HAS_JQ || $DRY_RUN; then return; fi
    local key="$1"
    local hash="$2"
    local tmp
    tmp="$(mktemp)"
    if [[ -f "$SYNC_STATE_FILE" ]]; then
        jq --arg key "$key" --arg hash "$hash" \
            '.files[$key] = $hash' \
            "$SYNC_STATE_FILE" > "$tmp"
    else
        local fw_version
        fw_version=$(grep -m1 '^\s*version:' "$SOURCE_DIR/.boltf/bolt-manifest.yaml" 2>/dev/null | awk '{print $2}' || echo "unknown")
        jq -n --arg key "$key" --arg hash "$hash" \
            --arg fw_version "$fw_version" \
            --arg source "$SOURCE_DIR" \
            '{framework_version: $fw_version, synced_at: (now | todate), source: $source, files: {($key): $hash}}' > "$tmp"
    fi
    mkdir -p "$(dirname "$SYNC_STATE_FILE")"
    mv "$tmp" "$SYNC_STATE_FILE"
}

# ── Classification ─────────────────────────────────────────────────────────────
# Returns one of: NEW PRISTINE MODIFIED
classify_primary() {
    local src_file="$1"
    local dest_file="$2"
    local rel_path="$3"

    if [[ ! -f "$dest_file" ]]; then
        echo "NEW"
        return
    fi

    local src_hash dest_hash stored_hash
    src_hash="$(compute_hash "$src_file")"
    dest_hash="$(compute_hash "$dest_file")"
    stored_hash="$(load_stored_hash "$rel_path")"

    if [[ -z "$stored_hash" ]]; then
        # First run / no sync-state: UNKNOWN
        if [[ "$dest_hash" == "$src_hash" ]]; then
            echo "PRISTINE"
        else
            echo "MODIFIED"
        fi
        return
    fi

    if [[ "$dest_hash" == "$stored_hash" ]]; then
        echo "PRISTINE"
    else
        echo "MODIFIED"
    fi
}

# ── Interactive menu for MODIFIED ─────────────────────────────────────────────
show_diff() {
    local dest_file="$1" src_file="$2"
    echo ""
    git diff --no-index --unified=3 -- "$dest_file" "$src_file" || true
    echo ""
}

run_ai_session() {
    local dest_file="$1" src_file="$2"

    if [[ "$EFFECTIVE_AI_CLIENT" == "none" ]]; then
        warn "No AI client available (tried claude and gh copilot)"
        return
    fi

    local prompt
    prompt="$(cat <<AIPROMPT
You are a Bolt Framework maintainer helping a developer merge a framework update.

--- LOCAL VERSION (${dest_file}) ---
$(cat "$dest_file")

--- FRAMEWORK VERSION (${src_file}) ---
$(cat "$src_file")

Analyze the differences and recommend whether the developer should:
1. Keep the local version (it contains meaningful customizations)
2. Accept the framework version (local changes are trivial or outdated)
3. Manually merge specific sections

Provide a concise analysis with your recommendation.
AIPROMPT
)"

    info "Running AI analysis (client: $EFFECTIVE_AI_CLIENT)..."
    local ai_output=""

    if [[ "$EFFECTIVE_AI_CLIENT" == "claude" ]]; then
        # Use temp file → stdin redirection — avoids arg-length limits and echo escape-sequence mangling
        local tmp_prompt
        tmp_prompt="$(mktemp)"
        printf '%s' "$prompt" > "$tmp_prompt"
        ai_output="$(claude -p < "$tmp_prompt" 2>&1)" || ai_output="(AI command failed — check claude CLI)"
        rm -f "$tmp_prompt"
    elif [[ "$EFFECTIVE_AI_CLIENT" == "copilot" ]]; then
        # gh copilot explain is designed for shell commands, not large content analysis.
        # It may hang or show an interactive TUI. If it does, press Ctrl+C and use
        # VS Code Copilot Chat manually with the diff shown above (option [D]).
        warn "GitHub Copilot CLI has limited support for file analysis."
        info "If it hangs, press Ctrl+C and use VS Code Copilot Chat with the diff [D] option."
        local tmp_prompt
        tmp_prompt="$(mktemp)"
        printf '%s' "$prompt" > "$tmp_prompt"
        ai_output="$(gh copilot explain < "$tmp_prompt" 2>&1)" || ai_output="(gh copilot explain failed)"
        rm -f "$tmp_prompt"
    fi

    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "$ai_output"
    echo "────────────────────────────────────────────────────────"
    echo ""
}

# IS_INTERACTIVE: set once at startup (not inside a subshell) so prompt_modified can use it
if [[ -t 0 ]]; then IS_INTERACTIVE=true; else IS_INTERACTIVE=false; fi

# prompt_modified writes its decision to a temp file to avoid the subshell tty problem.
# Caller reads PROMPT_RESULT after the call.
PROMPT_RESULT=""
prompt_modified() {
    local dest_file="$1" src_file="$2" rel_path="$3"

    # Non-interactive: auto-replace when --force, else skip
    if ! $IS_INTERACTIVE || $FORCE; then
        if $FORCE; then
            PROMPT_RESULT="replace"
        else
            PROMPT_RESULT="skip"
        fi
        return
    fi

    show_diff "$dest_file" "$src_file"

    local choice ai_choice
    while true; do
        echo -e "${YELLOW}MODIFIED: $rel_path${NC}"
        echo "  [S] Skip    — keep local"
        echo "  [R] Replace — accept framework version"
        echo "  [A] AI      — analyze with AI"
        echo "  [D] Diff    — open in VS Code"
        echo "  [Q] Quit"
        printf "Choice [S/R/A/D/Q]: "
        read -r choice </dev/tty || { PROMPT_RESULT="skip"; return; }
        case "${choice^^}" in
            S) PROMPT_RESULT="skip";    return ;;
            R) PROMPT_RESULT="replace"; return ;;
            A)
                run_ai_session "$dest_file" "$src_file"
                while true; do
                    printf "After AI review — [S]kip / [R]eplace: "
                    read -r ai_choice </dev/tty || { PROMPT_RESULT="skip"; return; }
                    case "${ai_choice^^}" in
                        S) PROMPT_RESULT="skip";    return ;;
                        R) PROMPT_RESULT="replace"; return ;;
                        *) warn "Enter S or R" ;;
                    esac
                done
                ;;
            D)
                if command -v code >/dev/null 2>&1; then
                    code --diff "$dest_file" "$src_file" &
                else
                    warn "VS Code (code) not found on PATH"
                fi
                ;;
            Q)
                info "Quit — stopping sync"
                exit 0
                ;;
            *) warn "Enter S, R, A, D, or Q" ;;
        esac
    done
}

# ── Apply a primary file ──────────────────────────────────────────────────────
apply_file() {
    local src_file="$1" dest_file="$2" rel_path="$3"
    if $DRY_RUN; then
        info "  [DRY-RUN] would copy: $rel_path"
        return
    fi
    mkdir -p "$(dirname "$dest_file")"
    # Back up an existing destination before overwriting (PRISTINE updates are still
    # overwrites) — keeps parity with the PowerShell updater and the MODIFIED path.
    [[ -f "$dest_file" ]] && backup_file "$dest_file"
    cp "$src_file" "$dest_file"
    local new_hash
    new_hash="$(compute_hash "$dest_file")"
    save_hash_to_state "$rel_path" "$new_hash"
}

# ── Process one primary file ──────────────────────────────────────────────────
process_primary() {
    local src_file="$1"
    # Compute rel_path relative to SOURCE_DIR
    local rel_path="${src_file#$SOURCE_DIR/}"
    local dest_file="$DEST_DIR/$rel_path"

    local class
    class="$(classify_primary "$src_file" "$dest_file" "$rel_path")"

    case "$class" in
        NEW)
            ok "  NEW      $rel_path"
            apply_file "$src_file" "$dest_file" "$rel_path"
            COUNT_NEW=$((COUNT_NEW + 1))
            ;;
        PRISTINE)
            info "  PRISTINE $rel_path"
            apply_file "$src_file" "$dest_file" "$rel_path"
            COUNT_PRISTINE=$((COUNT_PRISTINE + 1))
            ;;
        MODIFIED)
            warn "  MODIFIED $rel_path"
            prompt_modified "$dest_file" "$src_file" "$rel_path"
            if [[ "$PROMPT_RESULT" == "replace" ]]; then
                # apply_file backs up the existing destination before overwriting.
                apply_file "$src_file" "$dest_file" "$rel_path"
                ok "    → Replaced"
                COUNT_REPLACED=$((COUNT_REPLACED + 1))
            else
                info "    → Skipped (kept local)"
                COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
            fi
            COUNT_MODIFIED=$((COUNT_MODIFIED + 1))
            ;;
    esac
}

# ── Process one support file (copy-if-missing only) ───────────────────────────
process_support() {
    local src_file="$1"
    local rel_path="${src_file#$SOURCE_DIR/}"
    local dest_file="$DEST_DIR/$rel_path"

    if [[ -f "$dest_file" ]]; then
        return  # never overwrite support files
    fi

    info "  NEW (support) $rel_path"
    if ! $DRY_RUN; then
        mkdir -p "$(dirname "$dest_file")"
        cp "$src_file" "$dest_file"
    else
        info "  [DRY-RUN] would copy support: $rel_path"
    fi
    COUNT_NEW=$((COUNT_NEW + 1))
}

# ── Orphan detection ──────────────────────────────────────────────────────────
check_orphans() {
    local pattern="$1"   # glob relative to DEST_DIR, e.g. '.github/agents/*.agent.md'
    local dest_glob="$DEST_DIR/$pattern"

    # Use nullglob-style expansion
    local dest_file
    for dest_file in $dest_glob; do
        [[ -f "$dest_file" ]] || continue
        local rel_path="${dest_file#$DEST_DIR/}"
        local src_file="$SOURCE_DIR/$rel_path"
        if [[ ! -f "$src_file" ]]; then
            warn "  ORPHAN   $rel_path  (exists in dest, not in source)"
            COUNT_ORPHAN=$((COUNT_ORPHAN + 1))
        fi
    done
}

# ── Main sync ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Bolt Framework — Update Agents & Skills${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

# Validate source dirs exist
for check_dir in ".github/agents" ".claude/agents" ".claude/skills"; do
    if [[ ! -d "$SOURCE_DIR/$check_dir" ]]; then
        warn "Source directory not found, skipping: $SOURCE_DIR/$check_dir"
    fi
done

# ── 1. Primary files: .github/agents/*.agent.md ───────────────────────────────
info "Syncing .github/agents/ ..."
if [[ -d "$SOURCE_DIR/.github/agents" ]]; then
    for src in "$SOURCE_DIR/.github/agents/"*.agent.md; do
        [[ -f "$src" ]] || continue
        process_primary "$src"
    done
fi

# ── 2. Primary files: .claude/agents/*.md ─────────────────────────────────────
info "Syncing .claude/agents/ ..."
if [[ -d "$SOURCE_DIR/.claude/agents" ]]; then
    for src in "$SOURCE_DIR/.claude/agents/"*.md; do
        [[ -f "$src" ]] || continue
        process_primary "$src"
    done
fi

# ── 3. Primary files: .claude/skills/*/SKILL.md ───────────────────────────────
info "Syncing .claude/skills/*/SKILL.md ..."
if [[ -d "$SOURCE_DIR/.claude/skills" ]]; then
    for src in "$SOURCE_DIR/.claude/skills/"*/SKILL.md; do
        [[ -f "$src" ]] || continue
        process_primary "$src"
    done
fi

# ── 4. Support files: all other files under .claude/skills/*/ ────────────────
info "Syncing support files under .claude/skills/ (copy-if-missing) ..."
if [[ -d "$SOURCE_DIR/.claude/skills" ]]; then
    while IFS= read -r src; do
        [[ -f "$src" ]] || continue
        # Skip SKILL.md — already handled as primary
        [[ "$(basename "$src")" == "SKILL.md" ]] && continue
        process_support "$src"
    done < <(find "$SOURCE_DIR/.claude/skills" -type f 2>/dev/null || true)
fi

# ── 5. Orphan detection ───────────────────────────────────────────────────────
info "Checking for orphaned files in dest ..."
check_orphans ".github/agents/*.agent.md"
check_orphans ".claude/agents/*.md"

if [[ -d "$DEST_DIR/.claude/skills" ]]; then
    while IFS= read -r dest_file; do
        [[ -f "$dest_file" ]] || continue
        orphan_rel="${dest_file#$DEST_DIR/}"
        src_check="$SOURCE_DIR/$orphan_rel"
        if [[ ! -f "$src_check" ]]; then
            warn "  ORPHAN   $orphan_rel  (exists in dest, not in source)"
            COUNT_ORPHAN=$((COUNT_ORPHAN + 1))
        fi
    done < <(find "$DEST_DIR/.claude/skills" -type f 2>/dev/null || true)
fi

# ── Refresh top-level fields in sync-state (framework_version, synced_at, source) ─
# save_hash_to_state only writes these fields when the state file is first created,
# so re-runs against a newer framework version would leave them stale.
if $HAS_JQ && ! $DRY_RUN && [[ -f "$SYNC_STATE_FILE" ]]; then
    _fw_version=$(grep -m1 '^\s*version:' "$SOURCE_DIR/.boltf/bolt-manifest.yaml" 2>/dev/null | awk '{print $2}' || echo "unknown")
    _tmp="$(mktemp)"
    jq --arg fw_version "$_fw_version" --arg source "$SOURCE_DIR" \
        '. + {framework_version: $fw_version, synced_at: (now | todate), source: $source}' \
        "$SYNC_STATE_FILE" > "$_tmp" && mv "$_tmp" "$SYNC_STATE_FILE"
    unset _fw_version _tmp
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Sync Summary${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}NEW files copied   : $COUNT_NEW${NC}"
echo -e "  ${GREEN}PRISTINE (updated) : $COUNT_PRISTINE${NC}"
echo -e "  ${YELLOW}MODIFIED detected  : $COUNT_MODIFIED${NC}"
echo -e "  ${GREEN}  → Replaced       : $COUNT_REPLACED${NC}"
echo -e "  ${CYAN}  → Skipped (kept)  : $COUNT_SKIPPED${NC}"
if [[ $COUNT_ORPHAN -gt 0 ]]; then
    echo -e "  ${YELLOW}ORPHAN warnings    : $COUNT_ORPHAN${NC}"
fi
if $DRY_RUN; then
    echo ""
    warn "DRY-RUN — no files were written"
fi
if [[ -n "$BACKUP_DIR" ]] && [[ -d "$BACKUP_DIR" ]]; then
    echo ""
    info "Backups written to: $BACKUP_DIR"
fi
echo ""

if [[ $COUNT_MODIFIED -gt 0 && $COUNT_SKIPPED -gt 0 ]]; then
    warn "$COUNT_SKIPPED MODIFIED file(s) were skipped — review manually if needed"
fi

ok "Done"
